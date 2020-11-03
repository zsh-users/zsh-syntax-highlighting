# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2020 zsh-syntax-highlighting contributors
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

# First of all, ensure predictable parsing.
typeset zsh_highlight__aliases="$(builtin alias -Lm '[^+]*')"
# In zsh <= 5.2, aliases that begin with a plus sign ('alias -- +foo=42')
# are emitted by `alias -L` without a '--' guard, so they don't round trip.
#
# Hence, we exclude them from unaliasing:
builtin unalias -m '[^+]*'

# Set $0 to the expected value, regardless of functionargzero.
0=${(%):-%N}
if true; then
  # $0 is reliable
  typeset -g ZSH_HIGHLIGHT_VERSION=$(<"${0:A:h}"/.version)
  typeset -g ZSH_HIGHLIGHT_REVISION=$(<"${0:A:h}"/.revision-hash)
  if [[ $ZSH_HIGHLIGHT_REVISION == \$Format:* ]]; then
    # When running from a source tree without 'make install', $ZSH_HIGHLIGHT_REVISION
    # would be set to '$Format:%H$' literally.  That's an invalid value, and obtaining
    # the valid value (via `git rev-parse HEAD`, as Makefile does) might be costly, so:
    ZSH_HIGHLIGHT_REVISION=HEAD
  fi
fi

# This function takes a single argument F and returns True iff F is an autoload stub.
_zsh_highlight__function_is_autoload_stub_p() {
  if zmodload -e zsh/parameter; then
    #(( ${+functions[$1]} )) &&
    [[ "$functions[$1]" == *"builtin autoload -X"* ]]
  else
    #[[ $(type -wa -- "$1") == *'function'* ]] &&
    [[ "${${(@f)"$(which -- "$1")"}[2]}" == $'\t'$histchars[3]' undefined' ]]
  fi
  # Do nothing here: return the exit code of the if.
}

# Return True iff the argument denotes a function name.
_zsh_highlight__is_function_p() {
  if zmodload -e zsh/parameter; then
    (( ${+functions[$1]} ))
  else
    [[ $(type -wa -- "$1") == *'function'* ]]
  fi
}

# This function takes a single argument F and returns True iff F denotes the
# name of a callable function.  A function is callable if it is fully defined
# or if it is marked for autoloading and autoloading it at the first call to it
# will succeed.  In particular, if a function has been marked for autoloading
# but is not available in $fpath, then this function will return False therefor.
#
# See users/21671 http://www.zsh.org/cgi-bin/mla/redirect?USERNUMBER=21671
_zsh_highlight__function_callable_p() {
  if _zsh_highlight__is_function_p "$1" &&
     ! _zsh_highlight__function_is_autoload_stub_p "$1"
  then
    # Already fully loaded.
    return 0 # true
  else
    # "$1" is either an autoload stub, or not a function at all.
    #
    # Use a subshell to avoid affecting the calling shell.
    #
    # We expect 'autoload +X' to return non-zero if it fails to fully load
    # the function.
    ( autoload -U +X -- "$1" 2>/dev/null )
    return $?
  fi
}

# -------------------------------------------------------------------------------------------------
# Core highlighting update system
# -------------------------------------------------------------------------------------------------

# Use workaround for bug in ZSH?
# zsh-users/zsh@48cadf4 http://www.zsh.org/mla/workers//2017/msg00034.html
autoload -Uz is-at-least
if is-at-least 5.4; then
  typeset -g zsh_highlight__pat_static_bug=false
else
  typeset -g zsh_highlight__pat_static_bug=true
fi

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
  # Make it read-only.  Can't combine this with the previous line when POSIX_BUILTINS may be set.
  typeset -r ret

  # $region_highlight should be predefined, either by zle or by the test suite's mock (non-special) array.
  (( ${+region_highlight} )) || {
    echo >&2 'zsh-syntax-highlighting: error: $region_highlight is not defined'
    echo >&2 'zsh-syntax-highlighting: (Check whether zsh-syntax-highlighting was installed according to the instructions.)'
    return $ret
  }

  # Probe the memo= feature, once.
  (( ${+zsh_highlight__memo_feature} )) || {
    region_highlight+=( " 0 0 fg=red, memo=zsh-syntax-highlighting" )
    case ${region_highlight[-1]} in
      ("0 0 fg=red")
        # zsh 5.8 or earlier
        integer -gr zsh_highlight__memo_feature=0
        ;;
      ("0 0 fg=red memo=zsh-syntax-highlighting")
        # zsh 5.9 or later
        integer -gr zsh_highlight__memo_feature=1
        ;;
      (" 0 0 fg=red, memo=zsh-syntax-highlighting") ;&
      (*)
        # We can get here in two ways:
        #
        # 1. When not running as a widget.  In that case, $region_highlight is
        # not a special variable (= one with custom getter/setter functions
        # written in C) but an ordinary one, so the third case pattern matches
        # and we fall through to this block.  (The test suite uses this codepath.)
        #
        # 2. When running under a future version of zsh that will have changed
        # the serialization of $region_highlight elements from their underlying
        # C structs, so that none of the previous case patterns will match.
        #
        # In either case, fall back to a version check.
        #
        # The memo= feature was added to zsh in commit zsh-5.8-172-gdd6e702ee.
        # The version number at the time was 5.8.0.2-dev (see Config/version.mk).
        # Therefore, on 5.8.0.3 and newer the memo= feature is available.
        #
        # On zsh version 5.8.0.2 between the aforementioned commit and the
        # first Config/version.mk bump after it (which, at the time of writing,
        # is yet to come), this condition will false negative.
        if is-at-least 5.8.0.3 $ZSH_VERSION.0.0; then
          integer -gr zsh_highlight__memo_feature=1
        else
          integer -gr zsh_highlight__memo_feature=0
        fi
        ;;
    esac
    region_highlight[-1]=()
  }

  # Remove all highlighting in isearch, so that only the underlining done by zsh itself remains.
  # For details see FAQ entry 'Why does syntax highlighting not work while searching history?'.
  # This disables highlighting during isearch (for reasons explained in README.md) unless zsh is new enough
  # and doesn't have the pattern matching bug
  if [[ $WIDGET == zle-isearch-update ]] && { $zsh_highlight__pat_static_bug || ! (( $+ISEARCHMATCH_ACTIVE )) } ||
      # Do not highlight if there are more than 300 chars in the buffer. It's most
      # likely a pasted command or a huge list of files in that case..
      [[ -n ${ZSH_HIGHLIGHT_MAXLENGTH:-} ]] && (( ${#BUFFER} > ZSH_HIGHLIGHT_MAXLENGTH )) ||
      # Do not highlight if there are pending inputs (copy/paste).
      (( PENDING )); then
    # Reset region_highlight to build it from scratch
    if (( zsh_highlight__memo_feature )); then
      region_highlight=( "${(@)region_highlight:#*memo=zsh-syntax-highlighting*}" )
    else
      # Legacy codepath.  Not very interoperable with other plugins (issue #418).
      region_highlight=()
    fi
    return $ret
  fi

  # Before we 'emulate -L', save the user's options
  local -A zsyh_user_options
  if zmodload -e zsh/parameter; then
    if [[ -n ${ZSH_HIGHLIGHT_HIGHLIGHTERS:#(brackets|cursor|line|main|pattern|regexp|root)} ]]; then
      # Copy all options if there are user-defined highlighters
      zsyh_user_options=("${(kv)options[@]}")
    else
      # Copy a subset of options used by the bundled highlighters.  This is faster than
      # copying all options.
      zsyh_user_options=(
        ignorebraces        "${options[ignorebraces]}"
        ignoreclosebraces   "${options[ignoreclosebraces]-off}"
        pathdirs            "${options[pathdirs]}"
        interactivecomments "${options[interactivecomments]}"
        globassign          "${options[globassign]}"
        multifuncdef        "${options[multifuncdef]}"
        autocd              "${options[autocd]}"
        equals              "${options[equals]}"
        multios             "${options[multios]}"
        rcquotes            "${options[rcquotes]}"
      )
    fi
  else
    local canonical_options onoff option raw_options
    raw_options=(${(f)"$(emulate -R zsh; set -o)"})
    canonical_options=(${${${(M)raw_options:#*off}%% *}#no} ${${(M)raw_options:#*on}%% *})
    for option in "${canonical_options[@]}"; do
      [[ -o $option ]]
      case $? in
        (0) zsyh_user_options+=($option on);;
        (1) zsyh_user_options+=($option off);;
        (*) # Can't happen, surely?
            echo "zsh-syntax-highlighting: warning: '[[ -o $option ]]' returned $?"
            ;;
      esac
    done
  fi
  typeset -r zsyh_user_options

  local -a new_highlight
  if (( zsh_highlight__memo_feature )); then
    new_highlight=( "${(@)region_highlight:#*memo=zsh-syntax-highlighting*}" )
  fi

  emulate -L zsh
  setopt warncreateglobal nobashrematch
  local REPLY # don't leak $REPLY into global scope

  {
    local cache_place pred

    # Select which highlighters in ZSH_HIGHLIGHT_HIGHLIGHTERS need to be invoked.
    local highlighter; for highlighter in $ZSH_HIGHLIGHT_HIGHLIGHTERS; do

      # eval cache place for current highlighter and prepare it
      cache_place="_zsh_highlight__highlighter_${highlighter}_cache"
      typeset -ga ${cache_place}

      # If highlighter needs to be invoked
      pred="_zsh_highlight_highlighter_${highlighter}_predicate"
      if (( ! $pred )); then
        if type $pred >&/dev/null; then
          typeset -gri $pred=1
        else
          echo "zsh-syntax-highlighting: warning: disabling the ${(qq)highlighter} highlighter as it has not been loaded" >&2
          # TODO: use ${(b)} rather than ${(q)} if supported
          ZSH_HIGHLIGHT_HIGHLIGHTERS=( ${ZSH_HIGHLIGHT_HIGHLIGHTERS:#${highlighter}} )
          continue
        fi
      fi

      if $pred; then
        # Execute highlighter and save result
        region_highlight=()
        "_zsh_highlight_highlighter_${highlighter}_paint"
        : ${(AP)cache_place::="${region_highlight[@]}"}
        new_highlight+=($region_highlight)
      else
        # Use value form cache if any cached
        new_highlight+=("${(@P)cache_place}")
      fi

    done

    region_highlight=($new_highlight)

    # Re-apply zle_highlight settings

    # region
    (( REGION_ACTIVE )) && () {
      integer min max
      if (( MARK > CURSOR )) ; then
        min=$CURSOR max=$MARK
      else
        min=$MARK max=$CURSOR
      fi
      if (( REGION_ACTIVE == 1 )); then
        [[ $KEYMAP = vicmd ]] && (( max++ ))
      elif (( REGION_ACTIVE == 2 )); then
        local needle=$'\n'
        # CURSOR and MARK are 0 indexed between letters like region_highlight
        # Do not include the newline in the highlight
        (( min = ${BUFFER[(Ib:min:)$needle]} ))
        (( max = ${BUFFER[(ib:max:)$needle]} - 1 ))
      fi
      _zsh_highlight_apply_zle_highlight region standout "$min" "$max"
    }

    # yank / paste (zsh-5.1.1 and newer)
    (( YANK_ACTIVE )) && _zsh_highlight_apply_zle_highlight paste standout "$YANK_START" "$YANK_END"

    # isearch
    (( ISEARCHMATCH_ACTIVE )) && _zsh_highlight_apply_zle_highlight isearch underline "$ISEARCHMATCH_START" "$ISEARCHMATCH_END"

    # suffix
    (( SUFFIX_ACTIVE )) && _zsh_highlight_apply_zle_highlight suffix bold "$SUFFIX_START" "$SUFFIX_END"


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
  #
  # ### In zsh≥5.0.8 we'd use ${(b)entry}, but we support older zsh's, so we don't
  # ### add (b).  The only effect is on the failure mode for callers that violate
  # ### the precondition.
  local region="${zle_highlight[(r)${entry}:*]-}"

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
  region_highlight+=("$start $end $region, memo=zsh-syntax-highlighting")
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
      region_highlight+=("$start $end $ZSH_HIGHLIGHT_STYLES[$highlight], memo=zsh-syntax-highlighting")
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

# Decide whether to use the zle-line-pre-redraw codepath (colloquially known as
# "feature/redrawhook", after the topic branch's name) or the legacy "bind all
# widgets" codepath.
#
# We use the new codepath under two conditions:
#
# 1. If it's available, which we check by testing for add-zle-hook-widget's availability.
# 
# 2. If zsh has the memo= feature, which is required for interoperability reasons.
#    See issues #579 and #735, and the issues referenced from them.
#
#    We check this with a plain version number check, since a functional check,
#    as done by _zsh_highlight, can only be done from inside a widget
#    function — a catch-22.
#
#    See _zsh_highlight for the magic version number.  (The use of 5.8.0.2
#    rather than 5.8.0.3 as in the _zsh_highlight is deliberate.)
if is-at-least 5.8.0.2 $ZSH_VERSION.0.0 && _zsh_highlight__function_callable_p add-zle-hook-widget
then
  autoload -U add-zle-hook-widget
  _zsh_highlight__zle-line-finish() {
    # Reset $WIDGET since the 'main' highlighter depends on it.
    #
    # Since $WIDGET is declared by zle as read-only in this function's scope,
    # a nested function is required in order to shadow its built-in value;
    # see "User-defined widgets" in zshall.
    () {
      local -h -r WIDGET=zle-line-finish
      _zsh_highlight
    }
  }
  _zsh_highlight__zle-line-pre-redraw() {
    # Set $? to 0 for _zsh_highlight.  Without this, subsequent
    # zle-line-pre-redraw hooks won't run, since add-zle-hook-widget happens to
    # call us with $? == 1 in the common case.
    true && _zsh_highlight "$@"
  }
  _zsh_highlight_bind_widgets(){}
  if [[ -o zle ]]; then
    add-zle-hook-widget zle-line-pre-redraw _zsh_highlight__zle-line-pre-redraw
    add-zle-hook-widget zle-line-finish _zsh_highlight__zle-line-finish
  fi
else
  # Rebind all ZLE widgets to make them invoke _zsh_highlights.
  _zsh_highlight_bind_widgets()
  {
    setopt localoptions noksharrays
    typeset -F SECONDS
    local prefix=orig-s$SECONDS-r$RANDOM # unique each time, in case we're sourced more than once

    # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
    zmodload zsh/zleparameter 2>/dev/null || {
      print -r -- >&2 'zsh-syntax-highlighting: failed loading zsh/zleparameter.'
      return 1
    }

    # Override ZLE widgets to make them invoke _zsh_highlight.
    local -U widgets_to_bind
    widgets_to_bind=(${${(k)widgets}:#(.*|run-help|which-command|beep|set-local-history|yank|yank-pop)})

    # Always wrap special zle-line-finish widget. This is needed to decide if the
    # current line ends and special highlighting logic needs to be applied.
    # E.g. remove cursor imprint, don't highlight partial paths, ...
    widgets_to_bind+=(zle-line-finish)

    # Always wrap special zle-isearch-update widget to be notified of updates in isearch.
    # This is needed because we need to disable highlighting in that case.
    widgets_to_bind+=(zle-isearch-update)

    local cur_widget
    for cur_widget in $widgets_to_bind; do
      case ${widgets[$cur_widget]:-""} in

        # Already rebound event: do nothing.
        user:_zsh_highlight_widget_*);;

        # The "eval"'s are required to make $cur_widget a closure: the value of the parameter at function
        # definition time is used.
        #
        # We can't use ${0/_zsh_highlight_widget_} because these widgets are always invoked with
        # NO_function_argzero, regardless of the option's setting here.

        # User defined widget: override and rebind old one with prefix "orig-".
        user:*) zle -N $prefix-$cur_widget ${widgets[$cur_widget]#*:}
                eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget ${(q)prefix}-${(q)cur_widget} -- \"\$@\" }"
                zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

        # Completion widget: override and rebind old one with prefix "orig-".
        completion:*) zle -C $prefix-$cur_widget ${${(s.:.)widgets[$cur_widget]}[2,3]}
                      eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget ${(q)prefix}-${(q)cur_widget} -- \"\$@\" }"
                      zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

        # Builtin widget: override and make it call the builtin ".widget".
        builtin) eval "_zsh_highlight_widget_${(q)prefix}-${(q)cur_widget}() { _zsh_highlight_call_widget .${(q)cur_widget} -- \"\$@\" }"
                 zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

        # Incomplete or nonexistent widget: Bind to z-sy-h directly.
        *)
           if [[ $cur_widget == zle-* ]] && (( ! ${+widgets[$cur_widget]} )); then
             _zsh_highlight_widget_${cur_widget}() { :; _zsh_highlight }
             zle -N $cur_widget _zsh_highlight_widget_$cur_widget
           else
        # Default: unhandled case.
             print -r -- >&2 "zsh-syntax-highlighting: unhandled ZLE widget ${(qq)cur_widget}"
             print -r -- >&2 "zsh-syntax-highlighting: (This is sometimes caused by doing \`bindkey <keys> ${(q-)cur_widget}\` without creating the ${(qq)cur_widget} widget with \`zle -N\` or \`zle -C\`.)"
           fi
      esac
    done
  }
fi

# Load highlighters from directory.
#
# Arguments:
#   1) Path to the highlighters directory.
_zsh_highlight_load_highlighters()
{
  setopt localoptions noksharrays bareglobqual

  # Check the directory exists.
  [[ -d "$1" ]] || {
    print -r -- >&2 "zsh-syntax-highlighting: highlighters directory ${(qq)1} not found."
    return 1
  }

  # Load highlighters from highlighters directory and check they define required functions.
  local highlighter highlighter_dir
  for highlighter_dir ($1/*/(/)); do
    highlighter="${highlighter_dir:t}"
    [[ -f "$highlighter_dir${highlighter}-highlighter.zsh" ]] &&
      . "$highlighter_dir${highlighter}-highlighter.zsh"
    if type "_zsh_highlight_highlighter_${highlighter}_paint" &> /dev/null &&
       type "_zsh_highlight_highlighter_${highlighter}_predicate" &> /dev/null;
    then
        # New (0.5.0) function names
    elif type "_zsh_highlight_${highlighter}_highlighter" &> /dev/null &&
         type "_zsh_highlight_${highlighter}_highlighter_predicate" &> /dev/null;
    then
        # Old (0.4.x) function names
        if false; then
            # TODO: only show this warning for plugin authors/maintainers, not for end users
            print -r -- >&2 "zsh-syntax-highlighting: warning: ${(qq)highlighter} highlighter uses deprecated entry point names; please ask its maintainer to update it: https://github.com/zsh-users/zsh-syntax-highlighting/issues/329"
        fi
        # Make it work.
        eval "_zsh_highlight_highlighter_${(q)highlighter}_paint() { _zsh_highlight_${(q)highlighter}_highlighter \"\$@\" }"
        eval "_zsh_highlight_highlighter_${(q)highlighter}_predicate() { _zsh_highlight_${(q)highlighter}_highlighter_predicate \"\$@\" }"
    else
        print -r -- >&2 "zsh-syntax-highlighting: ${(qq)highlighter} highlighter should define both required functions '_zsh_highlight_highlighter_${highlighter}_paint' and '_zsh_highlight_highlighter_${highlighter}_predicate' in ${(qq):-"$highlighter_dir${highlighter}-highlighter.zsh"}."
    fi
  done
}


# -------------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------------

# Try binding widgets.
_zsh_highlight_bind_widgets || {
  print -r -- >&2 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.'
  return 1
}

# Resolve highlighters directory location.
_zsh_highlight_load_highlighters "${ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR:-${${0:A}:h}/highlighters}" || {
  print -r -- >&2 'zsh-syntax-highlighting: failed loading highlighters, exiting.'
  return 1
}

# Reset scratch variables when commandline is done.
_zsh_highlight_preexec_hook()
{
  typeset -g _ZSH_HIGHLIGHT_PRIOR_BUFFER=
  typeset -gi _ZSH_HIGHLIGHT_PRIOR_CURSOR=
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _zsh_highlight_preexec_hook 2>/dev/null || {
    print -r -- >&2 'zsh-syntax-highlighting: failed loading add-zsh-hook.'
  }

# Load zsh/parameter module if available
zmodload zsh/parameter 2>/dev/null || true

# Initialize the array of active highlighters if needed.
[[ $#ZSH_HIGHLIGHT_HIGHLIGHTERS -eq 0 ]] && ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)

if (( $+X_ZSH_HIGHLIGHT_DIRS_BLACKLIST )); then
  print >&2 'zsh-syntax-highlighting: X_ZSH_HIGHLIGHT_DIRS_BLACKLIST is deprecated. Please use ZSH_HIGHLIGHT_DIRS_BLACKLIST.'
  ZSH_HIGHLIGHT_DIRS_BLACKLIST=($X_ZSH_HIGHLIGHT_DIRS_BLACKLIST)
  unset X_ZSH_HIGHLIGHT_DIRS_BLACKLIST
fi

# Restore the aliases we unned
eval "$zsh_highlight__aliases"
builtin unset zsh_highlight__aliases

# Set $?.
true
