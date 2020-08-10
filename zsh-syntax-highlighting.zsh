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

# Set $0 to the expected value, regardless of functionargzero.
0=${(%):-%N}

# Update ZLE buffer syntax highlighting.
#
# Invokes each highlighter that needs updating.
# This function is supposed to be called whenever the ZLE state changes.
#
# This function must not be defined or run under emulate zsh so zsyh_user_options is correct.
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

  # Reset region_highlight to build it from scratch
  if (( zsh_highlight__memo_feature )); then
    region_highlight=( "${(@)region_highlight:#*memo=zsh-syntax-highlighting*}" )
  else
    # Legacy codepath.  Not very interoperable with other plugins (issue #418).
    region_highlight=()
  fi

  # Remove all highlighting in isearch, so that only the underlining done by zsh itself remains.
  # For details see FAQ entry 'Why does syntax highlighting not work while searching history?'.
  # This disables highlighting during isearch (for reasons explained in README.md) unless zsh is new enough
  # and doesn't have the pattern matching bug
  if [[ $WIDGET == zle-isearch-update ]] && { $zsh_highlight__pat_static_bug || ! (( $+ISEARCHMATCH_ACTIVE )) }; then
    return $ret
  fi

  # Before we 'emulate -L', save the user's options
  local -A zsyh_user_options
  if zmodload -e zsh/parameter; then
    zsyh_user_options=("${(kv)options[@]}")
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

  _zsh_highlight_internal

  return ret
}

emulate zsh -c 'source ${0:h}/driver.zsh'

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

# Try binding widgets.
_zsh_highlight_bind_widgets || {
  print -r -- >&2 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.'
  return 1
}

# Set $?.
true
