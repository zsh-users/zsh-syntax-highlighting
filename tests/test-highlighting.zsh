#!/usr/bin/env zsh
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


# Check an highlighter was given as argument.
[[ -n "$1" ]] || {
  echo >&2 "Bail out! You must provide the name of a valid highlighter as argument."
  exit 2
}

# Check the highlighter is valid.
[[ -f ${0:h:h}/highlighters/$1/$1-highlighter.zsh ]] || {
  echo >&2 "Bail out! Could not find highlighter ${(qq)1}."
  exit 2
}

# Check the highlighter has test data.
[[ -d ${0:h:h}/highlighters/$1/test-data ]] || {
  echo >&2 "Bail out! Highlighter ${(qq)1} has no test data."
  exit 2
}

# Set up results_filter
local results_filter
if [[ $QUIET == y ]]; then
  if type -w perl >/dev/null; then
    results_filter=${0:A:h}/tap-filter
  else
    echo >&2 "Bail out! quiet mode not supported: perl not found"; exit 2
  fi
else
  results_filter=cat
fi
[[ -n $results_filter ]] || { echo >&2 "Bail out! BUG setting \$results_filter"; exit 2 }

# Load the main script.
# While here, test that it doesn't eat aliases.
print > >($results_filter | ${0:A:h}/tap-colorizer.zsh) -r -- "# global (driver) tests"
print > >($results_filter | ${0:A:h}/tap-colorizer.zsh) -r -- "1..1"
alias -- +plus=plus
alias -- _other=other
original_alias_dash_L_output="$(alias -L)"
. ${0:h:h}/zsh-syntax-highlighting.zsh
if [[ $original_alias_dash_L_output == $(alias -L) ]]; then
  print -r -- "ok 1 # 'alias -- +foo=bar' is preserved"
else
  print -r -- "not ok 1 # 'alias -- +foo=bar' is preserved"
  exit 1
fi > >($results_filter | ${0:A:h}/tap-colorizer.zsh) 

# Overwrite _zsh_highlight_add_highlight so we get the key itself instead of the style
_zsh_highlight_add_highlight()
{
  region_highlight+=("$1 $2 $3")
}

# Activate the highlighter.
ZSH_HIGHLIGHT_HIGHLIGHTERS=($1)

# Runs a highlighting test
# $1: data file
run_test_internal() {

  local tests_tempdir="$1"; shift
  local srcdir="$PWD"
  builtin cd -q -- "$tests_tempdir" || { echo >&2 "Bail out! cd failed: $?"; return 1 }

  echo "# ${1:t:r}"

  # Load the data and prepare checking it.
  PREBUFFER= BUFFER= ;
  . "$srcdir"/"$1"

  # Check the data declares $PREBUFFER or $BUFFER.
  [[ -z $PREBUFFER && -z $BUFFER ]] && { echo >&2 "Bail out! Either 'PREBUFFER' or 'BUFFER' must be declared and non-blank"; return 1; }
  # Check the data declares $expected_region_highlight.
  (( ${#expected_region_highlight} == 0 )) && { echo >&2 "Bail out! 'expected_region_highlight' is not declared or empty."; return 1; }

  # Process the data.
  region_highlight=()
  _zsh_highlight

  # Overlapping regions can be declared in region_highlight, so we first build an array of the
  # observed highlighting.
  local -A observed_result
  for ((i=1; i<=${#region_highlight}; i++)); do
    local -a highlight_zone; highlight_zone=( ${(z)region_highlight[$i]} )
    integer start=$highlight_zone[1] end=$highlight_zone[2]
    if (( start < end )) # region_highlight ranges are half-open
    then
      (( --end )) # convert to closed range, like expected_region_highlight
      (( ++start, ++end )) # region_highlight is 0-indexed; expected_region_highlight is 1-indexed
      for j in {$start..$end}; do
        observed_result[$j]=$highlight_zone[3]
      done
    else
      # noop range; ignore.
    fi
    unset start end
    unset highlight_zone
  done

  # Then we compare the observed result with the expected one.
  echo "1..${#expected_region_highlight}"
  for ((i=1; i<=${#expected_region_highlight}; i++)); do
    local -a highlight_zone; highlight_zone=( ${(z)expected_region_highlight[$i]} )
    local todo=
    integer start=$highlight_zone[1] end=$highlight_zone[2]
    # Escape # as ♯ since the former is illegal in the 'description' part of TAP output
    local desc="[$start,$end] «${BUFFER[$start,$end]//'#'/♯}»"
    # Match the emptiness of observed_result if no highlighting is expected
    [[ $highlight_zone[3] == NONE ]] && highlight_zone[3]=
    [[ -n "$highlight_zone[4]" ]] && todo="# TODO $highlight_zone[4]"
    for j in {$start..$end}; do
      if [[ "$observed_result[$j]" != "$highlight_zone[3]" ]]; then
        print -r -- "not ok $i - $desc - expected ${(qqq)highlight_zone[3]}, observed ${(qqq)observed_result[$j]}. $todo"
        continue 2
      fi
    done
    print -r -- "ok $i - $desc${todo:+ - }$todo"
    unset desc
    unset start end
    unset todo
    unset highlight_zone
  done
}

# Run a single test file.  The exit status is 1 if the test harness had
# an error and 0 otherwise.  The exit status does not depend on whether
# test points succeeded or failed.
run_test() {
  # Do not combine the declaration and initialization: «local x="$(false)"» does not set $?.
  local __tests_tempdir
  __tests_tempdir="$(mktemp -d)" && [[ -d $__tests_tempdir ]] || {
    echo >&2 "Bail out! mktemp failed"; return 1
  }
  typeset -r __tests_tempdir # don't allow tests to override the variable that we will 'rm -rf' later on

  {
    # Use a subshell to isolate tests from each other.
    # (So tests can alter global shell state using 'cd', 'hash', etc)
    {
      # These braces are so multios don't come into play.
      { (run_test_internal "$__tests_tempdir" "$@") 3>&1 >&2 2>&3 } | grep \^
      local ret=$pipestatus[1] stderr=$pipestatus[2]
      if (( ! stderr )); then
        # stdout will become stderr
        echo "Bail out! output on stderr"; return 1
      else
        return $ret
      fi
    } 3>&1 >&2 2>&3
  } always {
    rm -rf -- "$__tests_tempdir"
  }
}

# Process each test data file in test data directory.
integer something_failed=0
ZSH_HIGHLIGHT_STYLES=()
for data_file in ${0:h:h}/highlighters/$1/test-data/*.zsh; do
  run_test "$data_file" | tee >($results_filter | ${0:A:h}/tap-colorizer.zsh) | grep -v '^not ok.*# TODO' | grep -Eq '^not ok|^ok.*# TODO' && (( something_failed=1 ))
  (( $pipestatus[1] )) && exit 2
done

exit $something_failed
