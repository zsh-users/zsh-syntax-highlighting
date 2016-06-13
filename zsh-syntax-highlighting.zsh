# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2016 zsh-syntax-highlighting contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------


# Set $0 to the expected value, regardless of functionargzero.
0=${(%):-%N}
if true; then
  # $0 is reliable
  ZSH_HIGHLIGHT_VERSION=$(<"${0:A:h}"/.version)
  ZSH_HIGHLIGHT_REVISION=$(<"${0:A:h}"/.revision-hash)
  if [[ $ZSH_HIGHLIGHT_REVISION == \$Format:* ]]; then
    # When running from a source tree without 'make install', $ZSH_HIGHLIGHT_REVISION
    # would be set to '$Format:%H$' literally.  That's an invalid value, and obtaining
    # the valid value (via `git rev-parse HEAD`, as Makefile does) might be costly, so:
    ZSH_HIGHLIGHT_REVISION=HEAD
  fi
fi

# -------------------------------------------------------------------------------------------------
# Core highlighting update system
# -------------------------------------------------------------------------------------------------

# Array declaring active highlighters names.
typeset -ga ZSH_HIGHLIGHT_HIGHLIGHTERS

# Update ZLE buffer syntax highlighting.
#
# Invokes each highlighter that needs updating.
# This function is supposed to be called whenever the ZLE state changes.
_zsh_highlight()
{
  # Store the previous command return code to restore it whatever happens.
  local ret=$?

  setopt localoptions warncreateglobal
  setopt localoptions noksharrays
  local REPLY # don't leak $REPLY into global scope

  # Do not highlight if there are more than 300 chars in the buffer. It's most
  # likely a pasted command or a huge list of files in that case..
  [[ -n ${ZSH_HIGHLIGHT_MAXLENGTH:-} ]] && [[ $#BUFFER -gt $ZSH_HIGHLIGHT_MAXLENGTH ]] && return $ret

  # Do not highlight if there are pending inputs (copy/paste).
  [[ $PENDING -gt 0 ]] && return $ret

  # Reset region highlight to build it from scratch
  typeset -ga region_highlight
  region_highlight=();

  {
    local cache_place
    local -a region_highlight_copy

    # Select which highlighters in ZSH_HIGHLIGHT_HIGHLIGHTERS need to be invoked.
    local highlighter; for highlighter in $ZSH_HIGHLIGHT_HIGHLIGHTERS; do

      # eval cache place for current highlighter and prepare it
      cache_place="_zsh_highlight_${highlighter}_highlighter_cache"
      typeset -ga ${cache_place}

      # If highlighter needs to be invoked
      if "_zsh_highlight_${highlighter}_highlighter_predicate"; then

        # save a copy, and cleanup region_highlight
        region_highlight_copy=("${region_highlight[@]}")
        region_highlight=()

        # Execute highlighter and save result
        {
          "_zsh_highlight_${highlighter}_highlighter"
        } always {
          eval "${cache_place}=(\"\${region_highlight[@]}\")"
        }

        # Restore saved region_highlight
        region_highlight=("${region_highlight_copy[@]}")

      fi

      # Use value form cache if any cached
      eval "region_highlight+=(\"\${${cache_place}[@]}\")"

    done

    # Re-apply zle_highlight settings

    # region
    (( REGION_ACTIVE )) && _zsh_highlight_apply_zle_highlight region standout "$MARK" "$CURSOR"

    # yank / paste (zsh-5.1.1 and newer)
    (( $+YANK_ACTIVE )) && (( YANK_ACTIVE )) && _zsh_highlight_apply_zle_highlight paste standout "$YANK_START" "$YANK_END"

    # isearch
    (( $+ISEARCHMATCH_ACTIVE )) && (( ISEARCHMATCH_ACTIVE )) && _zsh_highlight_apply_zle_highlight isearch underline "$ISEARCHMATCH_START" "$ISEARCHMATCH_END"

    # suffix
    (( $+SUFFIX_ACTIVE )) && (( SUFFIX_ACTIVE )) && _zsh_highlight_apply_zle_highlight suffix bold "$SUFFIX_START" "$SUFFIX_END"


    return $ret


  } always {
    typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER="$BUFFER"
    typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=$CURSOR
  }
}

# Apply highlighting based on entries in the zle_highlight array.
# This function takes four arguments:
# 1. The exact entry (no patterns) in the zle_highlight array:
#    region, paste, isearch, or suffix
# 2. The default highlighting that should be applied if the entry is unset
# 3. and 4. Two integer values describing the beginning and end of the
#    range. The order does not matter.
_zsh_highlight_apply_zle_highlight() {
  local entry="$1" default="$2"
  integer first="$3" second="$4"

  # read the relevant entry from zle_highlight
  local region="${zle_highlight[(r)${entry}:*]}"

  if [[ -z "$region" ]]; then
    # entry not specified at all, use default value
    region=$default
  else
    # strip prefix
    region="${region#${entry}:}"

    # no highlighting when set to the empty string or to 'none'
    if [[ -z "$region" ]] || [[ "$region" == none ]]; then
      return
    fi
  fi

  integer start end
  if (( first < second )); then
    start=$first end=$second
  else
    start=$second end=$first
  fi
  region_highlight+=("$start $end $region")
}


# -------------------------------------------------------------------------------------------------
# API/utility functions for highlighters
# -------------------------------------------------------------------------------------------------

# Array used by highlighters to declare user overridable styles.
typeset -gA ZSH_HIGHLIGHT_STYLES

# Whether the command line buffer has been modified or not.
#
# Returns 0 if the buffer has changed since _zsh_highlight was last called.
_zsh_highlight_buffer_modified()
{
  [[ "${_ZSH_HIGHLIGHT_PRIOR_BUFFER:-}" != "$BUFFER" ]]
}

# Whether the cursor has moved or not.
#
# Returns 0 if the cursor has moved since _zsh_highlight was last called.
_zsh_highlight_cursor_moved()
{
  [[ -n $CURSOR ]] && [[ -n ${_ZSH_HIGHLIGHT_PRIOR_CURSOR-} ]] && (($_ZSH_HIGHLIGHT_PRIOR_CURSOR != $CURSOR))
}

# Add a highlight defined by ZSH_HIGHLIGHT_STYLES.
#
# Should be used by all highlighters aside from 'pattern' (cf. ZSH_HIGHLIGHT_PATTERN).
# Overwritten in tests/test-highlighting.zsh when testing.
_zsh_highlight_add_highlight()
{
  local -i start end
  local highlight
  start=$1
  end=$2
  shift 2
  for highlight; do
    if (( $+ZSH_HIGHLIGHT_STYLES[$highlight] )); then
      region_highlight+=("$start $end $ZSH_HIGHLIGHT_STYLES[$highlight]")
      break
    fi
  done
}

# -------------------------------------------------------------------------------------------------
# Setup functions
# -------------------------------------------------------------------------------------------------

# Helper for _zsh_highlight_bind_widgets
# $1 is name of widget to call
_zsh_highlight_call_widget()
{
  builtin zle "$@" && 
  _zsh_highlight
}

# Rebind all ZLE widgets to make them invoke _zsh_highlights.
_zsh_highlight_bind_widgets()
{
  setopt localoptions noksharrays

  # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
  zmodload zsh/zleparameter 2>/dev/null || {
    echo 'zsh-syntax-highlighting: failed loading zsh/zleparameter.' >&2
    return 1
  }

  # Override ZLE widgets to make them invoke _zsh_highlight.
  local cur_widget
  for cur_widget in ${${(f)"$(builtin zle -la)"}:#(.*|orig-*|run-help|which-command|beep|set-local-history|yank)}; do

    # Most probably that widgets are already bound, but got rebount by another plugin like autosuggest.
    if type _zsh_highlight_widget_$cur_widget 2>&1 >/dev/null; then
      continue;
    fi

    case $widgets[$cur_widget] in

      # Already rebound event: do nothing.
      user:_zsh_highlight_widget_*);;

      # The "eval"'s are required to make $cur_widget a closure: the value of the parameter at function
      # definition time is used.
      #
      # We can't use ${0/_zsh_highlight_widget_} because these widgets are always invoked with
      # NO_function_argzero, regardless of the option's setting here.

      # User defined widget: override and rebind old one with prefix "orig-".
      user:*) zle -N orig-$cur_widget ${widgets[$cur_widget]#*:}
              eval "_zsh_highlight_widget_${(q)cur_widget}() { _zsh_highlight_call_widget orig-${(q)cur_widget} -- \"\$@\" }"
              zle -N $cur_widget _zsh_highlight_widget_$cur_widget;;

      # Completion widget: override and rebind old one with prefix "orig-".
      completion:*) zle -C orig-$cur_widget ${${(s.:.)widgets[$cur_widget]}[2,3]} 
                    eval "_zsh_highlight_widget_${(q)cur_widget}() { _zsh_highlight_call_widget orig-${(q)cur_widget} -- \"\$@\" }"
                    zle -N $cur_widget _zsh_highlight_widget_$cur_widget;;

      # Builtin widget: override and make it call the builtin ".widget".
      builtin) eval "_zsh_highlight_widget_${(q)cur_widget}() { _zsh_highlight_call_widget .${(q)cur_widget} -- \"\$@\" }"
               zle -N $cur_widget _zsh_highlight_widget_$cur_widget;;

      # Default: unhandled case.
      *) echo "zsh-syntax-highlighting: unhandled ZLE widget '$cur_widget'" >&2 ;;
    esac
  done
}

# Load highlighters from directory.
#
# Arguments:
#   1) Path to the highlighters directory.
_zsh_highlight_load_highlighters()
{
  setopt localoptions noksharrays

  # Check the directory exists.
  [[ -d "$1" ]] || {
    echo "zsh-syntax-highlighting: highlighters directory '$1' not found." >&2
    return 1
  }

  # Load highlighters from highlighters directory and check they define required functions.
  local highlighter highlighter_dir
  for highlighter_dir ($1/*/); do
    highlighter="${highlighter_dir:t}"
    [[ -f "$highlighter_dir/${highlighter}-highlighter.zsh" ]] && {
      . "$highlighter_dir/${highlighter}-highlighter.zsh"
      type "_zsh_highlight_${highlighter}_highlighter" &> /dev/null &&
      type "_zsh_highlight_${highlighter}_highlighter_predicate" &> /dev/null || {
        echo "zsh-syntax-highlighting: '${highlighter}' highlighter should define both required functions '_zsh_highlight_${highlighter}_highlighter' and '_zsh_highlight_${highlighter}_highlighter_predicate' in '${highlighter_dir}/${highlighter}-highlighter.zsh'." >&2
      }
    }
  done
}


# -------------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------------

# Try binding widgets.
_zsh_highlight_bind_widgets || {
  echo 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.' >&2
  return 1
}

# Resolve highlighters directory location.
_zsh_highlight_load_highlighters "${ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR:-${${0:A}:h}/highlighters}" || {
  echo 'zsh-syntax-highlighting: failed loading highlighters, exiting.' >&2
  return 1
}

# Reset scratch variables when commandline is done.
_zsh_highlight_preexec_hook()
{
  typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER=
  typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=
}
autoload -U add-zsh-hook
add-zsh-hook preexec _zsh_highlight_preexec_hook 2>/dev/null || {
    echo 'zsh-syntax-highlighting: failed loading add-zsh-hook.' >&2
  }

# Load zsh/parameter module if available
zmodload zsh/parameter 2>/dev/null || true

# Initialize the array of active highlighters if needed.
[[ $#ZSH_HIGHLIGHT_HIGHLIGHTERS -eq 0 ]] && ZSH_HIGHLIGHT_HIGHLIGHTERS=(main) || true
