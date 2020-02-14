# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2020 zsh-syntax-highlighting contributors
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
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------

# Highlighter for zsh-syntax-highlighting that highlights filenames

typeset -gA ZSH_HIGHLIGHT_FILE_TYPES
typeset -ga ZSH_HIGHLIGHT_FILE_PATTERNS

# Convert an ANSI escape sequence color into zle_highlight format (man 1 zshzle)
_zsh_highlight_highlighter_files_ansi_to_zle()
{
  local match mbegin mend seq
  local var=$1; shift
  for seq in "${(@s.:.)1}"; do
    seq=${seq#(#b)(*)=}
    (( $#match )) || continue
    _zsh_highlight_highlighter_files_ansi_to_zle1 $seq $var\[$match[1]\]
    unset match
  done
}

_zsh_highlight_highlighter_files_ansi_to_zle1()
{
  emulate -L zsh
  setopt local_options extended_glob

  local -a sgrs match
  local back mbegin mend fgbg hex
  integer sgr arg arg2 col r g b
  local str=$1

  while [ -n "$str" ]; do
    back=${str##(#b)([[:digit:]]##)}
    back=${back#;}
    (( $#match )) || return 1

    sgr=$match; unset match
    case $sgr in
      0) ;;
      1) sgrs+=(bold) ;;
      4) sgrs+=(underline) ;;
      7) sgrs+=(standout) ;;
      <30-37>) sgrs+=(fg=$(( $sgr - 30 ))) ;;
      <40-47>) sgrs+=(bg=$(( $sgr - 40 ))) ;;
      38|48)
        (( sgr == 38 )) && fgbg=fg || fgbg=bg
        # 38;5;n means paletted color
        # 38;2;r;g;b means truecolor
        back=${back##(#b)([[:digit:]]##)}
        back=${back#;}
        (( $#match )) || return 1
        arg=$match; unset match
        case $arg in
          5) back=${back##(#b)([[:digit:]]##)}
             back=${back#;}
             (( $#match )) || return 1
             arg2=$match; unset match
             sgrs+=($fgbg=$arg2) ;;
          2) back=${back##(#b)([[:digit:]]##);([[:digit:]]##);([[:digit:]]##)}
             back=${back#;}
             (( $#match == 3 )) || return 1
             printf -v hex \#%02X%02X%02X $match
             unset match
             sgrs+=($fgbg=$hex) ;;
          *) return 1 ;;
        esac ;;
      *) return 1 ;;
    esac

    str=$back
  done

  if [[ -n "$2" ]]; then
    eval $2='${(j.,.)sgrs}'
  else
    print -- ${(j.,.)sgrs}
  fi
}

# Extract ZSH_HIGHLIGHT_FILE_TYPES and ZSH_HIGHLIGHT_FILE_PATTERNS from LS_COLORS
zsh_highlight_files_extract_ls_colors()
{
  local -A ls_colors
  _zsh_highlight_highlighter_files_ansi_to_zle ls_colors $LS_COLORS
  for key val in ${(kv)ls_colors}; do
    case $key in
      di|fi|ln|pi|so|bd|cd|or|ex|su|sg|ow|tw)
        ZSH_HIGHLIGHT_FILE_TYPES[$key]=$val ;;
      *)  ZSH_HIGHLIGHT_FILE_PATTERNS+=($key $val) ;;
    esac
  done
}

# Perform simple filename expansion without globbing and without generating
# errors
_zsh_highlight_highlighter_files_fn_expand()
{
  local fn=$1
  local match expandable tail
  local -a mbegin mend
  if [[ $fn = (#b)(\~[^/]#)(*) ]]; then
    expandable=$match[1]
    tail=$match[2]
    # Try expanding expandable
    (: $~expandable) >&/dev/null && expandable=$~expandable
    print -- $expandable$tail
  else
    print -- $fn
  fi
}

# Whether the highlighter should be called or not.
_zsh_highlight_highlighter_files_predicate()
{
  _zsh_highlight_buffer_modified
}

# Syntax highlighting function.
_zsh_highlight_highlighter_files_paint()
{
  emulate -L zsh
  setopt localoptions extended_glob

  zmodload -F zsh/stat b:zstat

  local buf=$BUFFER word basename word_subst col type mode
  local -a words=(${(z)buf})
  local -A statdata
  integer start=0 curword=0 numwords=$#words len end

  while (( curword++ < numwords )); do
    col=""
    word=$words[1]
    words=("${(@)words:1}")
    len=$#buf
    buf="${buf/#[^$word[1]]#}" # strip whitespace
    start+=$(( len - $#buf ))
    end=$(( start + $#word ))

    word_subst=$(_zsh_highlight_highlighter_files_fn_expand $word)

    if ! zstat -H statdata -Ls -- "$word_subst" 2>/dev/null; then
      start=$end
      buf=${buf[$#word+1,-1]}
      continue
    fi
    mode=$statdata[mode]
    type=$mode[1]
    basename=$word:t
    [[ $word[-1] = '/' ]] && basename=$basename/

    # Color by file type
    case $type in
      d) [[ ${mode[9,10]} = wt ]] \
           && col=$ZSH_HIGHLIGHT_FILE_TYPES[tw] \
           || col=$ZSH_HIGHLIGHT_FILE_TYPES[di];;
      l) [[ -e "$word_subst" ]] \
           && col=$ZSH_HIGHLIGHT_FILE_TYPES[ln] \
           || col=$ZSH_HIGHLIGHT_FILE_TYPES[or];;
      p) col=$ZSH_HIGHLIGHT_FILE_TYPES[pi];;
      b) col=$ZSH_HIGHLIGHT_FILE_TYPES[bd];;
      c) col=$ZSH_HIGHLIGHT_FILE_TYPES[cd];;
      s) col=$ZSH_HIGHLIGHT_FILE_TYPES[so];;
    esac

    # Regular file: more special cases
    if [[ -z "$col" ]]; then
      if [[ $mode[4] = s ]]; then
        col=$ZSH_HIGHLIGHT_FILE_TYPES[su]  # setuid root
      elif [[ $mode[7] = s ]]; then
        col=$ZSH_HIGHLIGHT_FILE_TYPES[sg]  # setgid root
      elif [[ $mode[4] = x ]]; then
        col=$ZSH_HIGHLIGHT_FILE_TYPES[ex]  # Executable
      fi
    fi

    # Regular file: check file patterns
    if [[ -z "$col" ]]; then
      for key val in ${(kv)ZSH_HIGHLIGHT_FILE_PATTERNS}; do
        if [[ $basename = $~key ]]; then
          col=$val
          break
        fi
      done
    fi

    # Just a regular file
    if [[ -z "$col" ]]; then
      col=$ZSH_HIGHLIGHT_FILE_TYPES[fi]
    fi

    if [[ -n "$col" ]]; then
      if (( end > start + $#basename && ${+ZSH_HIGHLIGHT_FILE_TYPES[lp]} )); then
        region_highlight+=("$start $(( end - $#basename )) $ZSH_HIGHLIGHT_FILE_TYPES[lp]")
      fi
      region_highlight+=("$(( end - $#basename )) $end $col")
    fi

    start=$end
    buf=${buf[$#word+1,-1]}
  done
}

