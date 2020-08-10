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
fpath+=(${0:P:h})
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

# Load highlighters from directory.
#
# Arguments:
#   1) Path to the highlighters directory.
_zsh_highlight_load_highlighters()
{
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
    if [[ -f "${highlighter_dir}_zsh_highlight_highlighter_${highlighter}_paint" ]] &&
       [[ -f "${highlighter_dir}_zsh_highlight_highlighter_${highlighter}_predicate" ]]; then
      # New (0.8.0) autoload style highlighter
      fpath+=(${highlighter_dir%/})
      autoload -Uz "_zsh_highlight_highlighter_${highlighter}_paint" "_zsh_highlight_highlighter_${highlighter}_predicate"
    else
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
    fi
  done
}


# -------------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------------

autoload -Uz _zsh_highlight_internal

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
