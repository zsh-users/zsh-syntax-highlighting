#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2011 zsh-syntax-highlighting contributors
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


# Define default styles.
: ${ZSH_HIGHLIGHT_STYLES[default]:=none}
: ${ZSH_HIGHLIGHT_STYLES[unknown-token]:=fg=red,bold}
: ${ZSH_HIGHLIGHT_STYLES[reserved-word]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[alias]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[builtin]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[function]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[command]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[command_prefix]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[precommand]:=fg=green,underline}
: ${ZSH_HIGHLIGHT_STYLES[commandseparator]:=none}
: ${ZSH_HIGHLIGHT_STYLES[redirection]:=fg=magenta}
: ${ZSH_HIGHLIGHT_STYLES[hashed-command]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[path]:=underline}
: ${ZSH_HIGHLIGHT_STYLES[path_prefix]:=underline}
: ${ZSH_HIGHLIGHT_STYLES[path_approx]:=fg=yellow,underline}
: ${ZSH_HIGHLIGHT_STYLES[file]:=}
: ${ZSH_HIGHLIGHT_STYLES[globbing]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[history-expansion]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[single-hyphen-option]:=none}
: ${ZSH_HIGHLIGHT_STYLES[double-hyphen-option]:=none}
: ${ZSH_HIGHLIGHT_STYLES[back-quoted-argument]:=none}
: ${ZSH_HIGHLIGHT_STYLES[single-quoted-argument]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[double-quoted-argument]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[assign]:=none}
: ${ZSH_HIGHLIGHT_STYLES[isearch]:=fg=yellow,bg=red,bold}
: ${ZSH_HIGHLIGHT_STYLES[region]:=bg=blue}
: ${ZSH_HIGHLIGHT_STYLES[special]:=none}
: ${ZSH_HIGHLIGHT_STYLES[suffix]:=none}

# Whether the highlighter should be called or not.
_zsh_highlight_main_highlighter_predicate()
{
  _zsh_highlight_buffer_modified
}

## In case we need to highlight in other circumstances then default from highlighter_predicate lets define a switcher
_zsh_highlight_main_highlighter_predicate_switcher()
{
    case $1 in
	'b') # buffer
           _zsh_highlight_main_highlighter_predicate()
	   {
	       _zsh_highlight_buffer_modified
	   };;
	'c') # cursor
	   _zsh_highlight_main_highlighter_predicate()
	   {
	       _zsh_highlight_cursor_moved
	   };;
	'bc') bccounter=0 # buffer and cursor
	   _zsh_highlight_main_highlighter_predicate()
	   {
	       bccounter=$((bccounter+1))
	       (( $bccounter > 1 )) && _zsh_highlight_main_highlighter_predicate_switcher b
	       _zsh_highlight_cursor_moved || _zsh_highlight_buffer_modified
	   };;
	*);;
    esac
}

# Main syntax highlighting function.
_zsh_highlight_main_highlighter()
{
  emulate -L zsh
  setopt localoptions extendedglob bareglobqual
  local start_pos=0 end_pos highlight_glob=true new_expression=true arg style lsstyle start_file_pos end_file_pos sudo=false sudo_arg=false
  typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
  typeset -a ZSH_HIGHLIGHT_TOKENS_REDIRECTION
  typeset -a ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
  typeset -a ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS
  region_highlight=()

  ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=(
    '|' '||' ';' '&' '&&' '&|' '|&' '&!'
  )
  ZSH_HIGHLIGHT_TOKENS_REDIRECTION=(
    '<' '<>' '>' '>|' '>!' '>>' '>>|' '>>!' '<<' '<<-' '<<<' '<&' '>&' '<& -' '>& -' '<& p' '>& p' '&>' '>&|' '>&!' '&>|' '&>!' '>>&' '&>>' '>>&|' '>>&!' '&>>|' '&>>!'
  )
  ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(
    'builtin' 'command' 'exec' 'nocorrect' 'noglob'
  )
  # Tokens that are always immediately followed by a command.
  ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS=(
    $ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR $ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
  )

  splitbuf1=(${(z)BUFFER})
  splitbuf2=(${(z)BUFFER//$'\n'/ \$\'\\\\n\' }) # ugly hack, but I have no other idea
  local argnum=0
  for arg in ${(z)BUFFER}; do
    argnum=$((argnum+1))
    if [[ $splitbuf1[$argnum] != $splitbuf2[$argnum] ]] && new_expression=true && continue

    local substr_color=0 isfile=false
    local style_override=""
    [[ $start_pos -eq 0 && $arg = 'noglob' ]] && highlight_glob=false
    ((start_pos+=${#BUFFER[$start_pos+1,-1]}-${#${BUFFER[$start_pos+1,-1]##[[:space:]]#}}))
    ((end_pos=$start_pos+${#arg}))

    # Parse the sudo command line
    if $sudo; then
      case "$arg" in
        # Flag that requires an argument
        '-'[Cgprtu]) sudo_arg=true;;
        # This prevents misbehavior with sudo -u -otherargument
        '-'*)        sudo_arg=false;;
        *)           if $sudo_arg; then
                       sudo_arg=false
                     else
                       sudo=false
                       new_expression=true
                     fi
                     ;;
      esac
    fi
    if $new_expression; then
      new_expression=false
     if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS:#"$arg"} ]]; then
      style=$ZSH_HIGHLIGHT_STYLES[precommand]
     elif [[ "$arg" = "sudo" ]]; then
      style=$ZSH_HIGHLIGHT_STYLES[precommand]
      sudo=true
     else
      res=$(LC_ALL=C builtin type -w $arg 2>/dev/null)
      case $res in
        *': reserved')  style=$ZSH_HIGHLIGHT_STYLES[reserved-word];;
        *': alias')     style=$ZSH_HIGHLIGHT_STYLES[alias]
                        local aliased_command="${"$(alias -- $arg)"#*=}"
                        [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$aliased_command"} && -z ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS+=($arg)
                        ;;
        *': builtin')   style=$ZSH_HIGHLIGHT_STYLES[builtin];;
        *': function')  style=$ZSH_HIGHLIGHT_STYLES[function];;
        *': command')   style=$ZSH_HIGHLIGHT_STYLES[command];;
        *': hashed')    style=$ZSH_HIGHLIGHT_STYLES[hashed-command];;
        *)              if _zsh_highlight_main_highlighter_check_assign; then
                          style=$ZSH_HIGHLIGHT_STYLES[assign]
                          new_expression=true
                        elif _zsh_highlight_main_highlighter_check_command; then
                          style=$ZSH_HIGHLIGHT_STYLES[command_prefix]
                        elif _zsh_highlight_main_highlighter_check_path; then
                          style=$ZSH_HIGHLIGHT_STYLES[path]
                        elif [[ $arg[0,1] == $histchars[0,1] || $arg[0,1] == $histchars[2,2] ]]; then
                          style=$ZSH_HIGHLIGHT_STYLES[history-expansion]
                        elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]]; then
			  style=$ZSH_HIGHLIGHT_STYLES[commandseparator]
                        elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$arg"} ]]; then
			    style=$ZSH_HIGHLIGHT_STYLES[redirection]
                        else
                          style=$ZSH_HIGHLIGHT_STYLES[unknown-token]
                        fi
                        _zsh_highlight_main_highlighter_check_file && isfile=true
                        ;;
      esac
     fi
    else
      case $arg in
        '--'*)   style=$ZSH_HIGHLIGHT_STYLES[double-hyphen-option];;
        '-'*)    style=$ZSH_HIGHLIGHT_STYLES[single-hyphen-option];;
        "'"*"'") style=$ZSH_HIGHLIGHT_STYLES[single-quoted-argument];;
        '"'*'"') style=$ZSH_HIGHLIGHT_STYLES[double-quoted-argument]
                 region_highlight+=("$start_pos $end_pos $style")
                 _zsh_highlight_main_highlighter_highlight_string
                 substr_color=1
                 ;;
        '`'*'`') style=$ZSH_HIGHLIGHT_STYLES[back-quoted-argument];;
        *"*"*)   $highlight_glob && style=$ZSH_HIGHLIGHT_STYLES[globbing] || style=$ZSH_HIGHLIGHT_STYLES[default];;
        *)       if _zsh_highlight_main_highlighter_check_path; then
                   style=$ZSH_HIGHLIGHT_STYLES[path]
                 elif [[ $arg[0,1] = $histchars[0,1] ]]; then
                   style=$ZSH_HIGHLIGHT_STYLES[history-expansion]
                 elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]]; then
                   style=$ZSH_HIGHLIGHT_STYLES[commandseparator]
                 elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$arg"} ]]; then
                   style=$ZSH_HIGHLIGHT_STYLES[redirection]
                 else
                   style=$ZSH_HIGHLIGHT_STYLES[default]
                 fi
		 _zsh_highlight_main_highlighter_check_file && isfile=true
                 ;;
      esac
    fi
    # if a style_override was set (eg in _zsh_highlight_main_highlighter_check_path), use it
    [[ -n $style_override ]] && style=$ZSH_HIGHLIGHT_STYLES[$style_override]
    if [[ $isfile == true ]]; then
	start_file_pos=$((start_pos+${#arg}-${#arg:t}))
	end_file_pos=$end_pos
	end_pos=$((end_pos-${#arg:t}))
	region_highlight+=("$start_file_pos $end_file_pos $lsstyle")
    fi
    [[ $substr_color = 0 ]] && region_highlight+=("$start_pos $end_pos $style")
    [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && new_expression=true
    [[ $isfile == true ]] && start_pos=$end_file_pos || start_pos=$end_pos
  done
}

# Check if the argument is variable assignment
_zsh_highlight_main_highlighter_check_assign()
{
    setopt localoptions extended_glob
    [[ $arg == [[:alpha:]_][[:alnum:]_]#(|\[*\])=* ]]
}

# Check if the argument is a path.
_zsh_highlight_main_highlighter_check_path()
{
  setopt localoptions nonomatch
  local expanded_path; : ${expanded_path:=${(Q)~arg}}
  [[ -z $expanded_path ]] && return 1
  [[ -e $expanded_path ]] && return 0
  # Search the path in CDPATH
  local cdpath_dir
  for cdpath_dir in $cdpath ; do
    [[ -e "$cdpath_dir/$expanded_path" ]] && return 0
  done
  [[ ! -e ${expanded_path:h} ]] && return 1
  if [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos ]]; then
    local -a tmp
    # got a path prefix?
    tmp=( ${expanded_path}*(N) )
    (( $#tmp > 0 )) && style_override=path_prefix && _zsh_highlight_main_highlighter_predicate_switcher bc && return 0
    # or maybe an approximate path?
    tmp=( (#a1)${expanded_path}*(N) )
    (( $#arg > 3 && $#tmp > 0 )) && style_override=path_approx && return 0
  fi
  return 1
}

# Highlight special chars inside double-quoted strings
_zsh_highlight_main_highlighter_highlight_string()
{
  setopt localoptions noksharrays
  local i j k style varflag
  # Starting quote is at 1, so start parsing at offset 2 in the string.
  for (( i = 2 ; i < end_pos - start_pos ; i += 1 )) ; do
    (( j = i + start_pos - 1 ))
    (( k = j + 1 ))
    case "$arg[$i]" in
      '$' ) style=$ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]
            (( varflag = 1))
            ;;
      "\\") style=$ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]
            for (( c = i + 1 ; c < end_pos - start_pos ; c += 1 )); do
              [[ "$arg[$c]" != ([0-9,xX,a-f,A-F]) ]] && break
            done
            AA=$arg[$i+1,$c-1]
            # Matching for HEX and OCT values like \0xA6, \xA6 or \012
            if [[ "$AA" =~ "^(0*(x|X)[0-9,a-f,A-F]{1,2})" || "$AA" =~ "^(0[0-7]{1,3})" ]];then
              (( k += $#MATCH ))
              (( i += $#MATCH ))
            else
              (( k += 1 )) # Color following char too.
              (( i += 1 )) # Skip parsing the escaped char.
            fi
              (( varflag = 0 )) # End of variable
            ;;
      ([^a-zA-Z0-9_]))
            (( varflag = 0 )) # End of variable
            continue
            ;;
      *) [[ $varflag -eq 0 ]] && continue ;;

    esac
    region_highlight+=("$j $k $style")
  done
}

## Check if command with given prefix exists
_zsh_highlight_main_highlighter_check_command()
{
  setopt localoptions nonomatch
  local -a prefixed_command
  [[ $arg != $arg:t ]] && return 1  # don't match anything if explicit path is present
  for p in $path; do prefixed_command+=( $p/${arg}*(N) ); done
  [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos && $#prefixed_command > 0 ]] && return 0 || return 1
}

## Fill table with colors and file types from $LS_COLORS
_zsh_highlight_files_highlighter_fill_table_of_types()
{
  local group type code ncolors=$(echotc Co)
  local -a attrib

  for group in ${(s.:.)LS_COLORS}; do
    type=${group%=*}
    code=${group#*=}
    attrib=()
    takeattrib ${(s.;.)code}
    ZSH_HIGHLIGHT_FILES+=($type ${(j.,.)attrib})
  done
}

## Take attributes from unfolded $LS_COLORS code
takeattrib()
{
    while [ "$#" -gt 0 ]; do
	[[ $1 == 38 && $2 == 5 ]] && {attrib+=("fg=$3"); shift 3; continue}
	[[ $1 == 48 && $2 == 5 ]] && {attrib+=("bg=$3"); shift 3; continue}
	case $1 in
	    00|0) attrib+=("none"); shift;;
            01|1) attrib+=("bold" ); shift;;
            02|2) attrib+=("faint"); shift;;
            03|3) attrib+=("italic"); shift;;
            04|4) attrib+=("underscore"); shift;;
            05|5) attrib+=("blink"); shift;;
            07|7) attrib+=("standout"); shift;;
            08|8) attrib+=("concealed"); shift;;
            3[0-7]) attrib+=("fg=$(($1-30))"); shift;;
            4[0-7]) attrib+=("bg=$(($1-40))"); shift;;
            9[0-7]) [[ $ncolors == 256 ]] && attrib+=("fg=$(($1-82))") || attrib+=("fg=$(($1-90))" "bold"); shift;;
            10[0-7]) [[ $ncolors == 256 ]] && attrib+=("bg=$(($1-92))") || attrib+=("bg=$(($1-100))" "bold"); shift;;
            *) shift;;
        esac
    done
}

## Check if the argument is a file, if yes change the style accordingly
_zsh_highlight_main_highlighter_check_file()
{
    setopt localoptions nonomatch
    local expanded_arg matched_file

    expanded_arg=${(Q)~arg}
    [[ -z $expanded_arg ]] && return 1
    [[ -d $expanded_arg ]] && return 1
    [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos ]] && matched_file=(${expanded_arg}*(Noa^/[1]))
    [[ -e $expanded_arg || -e $matched_file ]] && lsstyle=none || return 1
    [[ -e $matched_file ]] && _zsh_highlight_main_highlighter_predicate_switcher bc

    [[ ! -z $ZSH_HIGHLIGHT_STYLES[file] ]] && lsstyle=$ZSH_HIGHLIGHT_STYLES[file] && return 0

    # [[ rs ]]
    # [[ -d $expanded_arg || -d $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[di] && return 0
    [[ -h $expanded_arg || -h $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[ln] && return 0
    # [[ mh ]]
    [[ -p $expanded_arg || -p $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[pi] && return 0
    [[ -S $expanded_arg || -S $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[so] && return 0
    # [[ do ]]
    [[ -b $expanded_arg || -b $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[bd] && return 0
    [[ -c $expanded_arg || -c $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[cd] && return 0
    # [[ or ]]
    # [[ mi ]]
    [[ -u $expanded_arg || -u $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[su] && return 0
    [[ -g $expanded_arg || -g $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[sg] && return 0
    # [[ ca ]]
    # [[ tw ]]
    # [[ ow ]]
    [[ -k $expanded_arg || -k $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[st] && return 0
    [[ -x $expanded_arg || -x $matched_file ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[ex] && return 0

    [[ -e $expanded_arg ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[*.$expanded_arg:e] && return 0
    [[ -n $matched_file:e ]] && lsstyle=$ZSH_HIGHLIGHT_FILES[*.$matched_file:e] && return 0

    return 0
}

## Fill table only once, at the initialization process
_zsh_highlight_files_highlighter_fill_table_of_types
