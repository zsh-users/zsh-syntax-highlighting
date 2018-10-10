# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2017 zsh-syntax-highlighting contributors
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
: ${ZSH_HIGHLIGHT_STYLES[suffix-alias]:=fg=green,underline}
: ${ZSH_HIGHLIGHT_STYLES[precommand]:=fg=green,underline}
: ${ZSH_HIGHLIGHT_STYLES[commandseparator]:=none}
: ${ZSH_HIGHLIGHT_STYLES[path]:=underline}
: ${ZSH_HIGHLIGHT_STYLES[path_pathseparator]:=}
: ${ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]:=}
: ${ZSH_HIGHLIGHT_STYLES[globbing]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[history-expansion]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[command-substitution]:=none}
: ${ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]:=fg=magenta}
: ${ZSH_HIGHLIGHT_STYLES[process-substitution]:=none}
: ${ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]:=fg=magenta}
: ${ZSH_HIGHLIGHT_STYLES[single-hyphen-option]:=none}
: ${ZSH_HIGHLIGHT_STYLES[double-hyphen-option]:=none}
: ${ZSH_HIGHLIGHT_STYLES[back-quoted-argument]:=none}
: ${ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]:=fg=magenta}
: ${ZSH_HIGHLIGHT_STYLES[single-quoted-argument]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[double-quoted-argument]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]:=fg=yellow}
: ${ZSH_HIGHLIGHT_STYLES[rc-quote]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[assign]:=none}
: ${ZSH_HIGHLIGHT_STYLES[redirection]:=none}
: ${ZSH_HIGHLIGHT_STYLES[comment]:=fg=black,bold}
: ${ZSH_HIGHLIGHT_STYLES[arg0]:=fg=green}

# Whether the highlighter should be called or not.
_zsh_highlight_highlighter_main_predicate()
{
  # may need to remove path_prefix highlighting when the line ends
  [[ $WIDGET == zle-line-finish ]] || _zsh_highlight_buffer_modified
}

# Helper to deal with tokens crossing line boundaries.
_zsh_highlight_main_add_region_highlight() {
  integer start=$1 end=$2
  shift 2

  # The calculation was relative to $buf but region_highlight is relative to $BUFFER.
  (( start += buf_offset ))
  (( end += buf_offset ))

  list_highlights+=($start $end $1)
}

_zsh_highlight_main_add_many_region_highlights() {
  for 1 2 3; do
    _zsh_highlight_main_add_region_highlight $1 $2 $3
  done
}

_zsh_highlight_main_calculate_fallback() {
  local -A fallback_of; fallback_of=(
      alias arg0
      suffix-alias arg0
      builtin arg0
      function arg0
      command arg0
      precommand arg0
      hashed-command arg0
      arg0_\* arg0

      path_prefix path
      # The path separator fallback won't ever be used, due to the optimisation
      # in _zsh_highlight_main_highlighter_highlight_path_separators().
      path_pathseparator path
      path_prefix_pathseparator path_prefix

      single-quoted-argument{-unclosed,}
      double-quoted-argument{-unclosed,}
      dollar-quoted-argument{-unclosed,}
      back-quoted-argument{-unclosed,}

      command-substitution{-delimiter,}
      process-substitution{-delimiter,}
      back-quoted-argument{-delimiter,}
  )
  local needle=$1 value
  reply=($1)
  while [[ -n ${value::=$fallback_of[(k)$needle]} ]]; do
    unset "fallback_of[$needle]" # paranoia against infinite loops
    reply+=($value)
    needle=$value
  done
}

# Get the type of a command.
#
# Uses the zsh/parameter module if available to avoid forks, and a
# wrapper around 'type -w' as fallback.
#
# Takes a single argument.
#
# Uses the following caller variables: [[ $this_word == *':alias:'* ]]
#
# The result will be stored in REPLY.
_zsh_highlight_main__type() {
  # Our caller knows whether aliases are allowed at this point.  Compare:
  #    % ls
  #    % sudo ls
  if [[ $this_word == *':alias:'* ]]; then
    integer -r aliases_allowed=1
  else
    integer -r aliases_allowed=0
  fi
  # For the same reason, we won't cache replies of anything that exists as an
  # alias at all, regardless of $aliases_allowed.
  #
  # ### We probably _should_ cache them in a cache that's keyed on the value of
  # ### $aliases_allowed, on the assumption that aliases are the common case.
  integer may_cache=1

  # Cache lookup
  if (( $+_zsh_highlight_main__command_type_cache )); then
    REPLY=$_zsh_highlight_main__command_type_cache[(e)$1]
    if [[ -n "$REPLY" ]]; then
      return
    fi
  fi

  # Main logic
  if (( $#options_to_set )); then
    setopt localoptions $options_to_set;
  fi
  unset REPLY
  if zmodload -e zsh/parameter; then
    if (( $+aliases[(e)$1] )); then
      may_cache=0
    fi
    if (( $+aliases[(e)$1] )) && (( aliases_allowed )); then
      REPLY=alias
    elif (( $+saliases[(e)${1##*.}] )); then
      REPLY='suffix alias'
    elif (( $reswords[(Ie)$1] )); then
      REPLY=reserved
    elif (( $+functions[(e)$1] )); then
      REPLY=function
    elif (( $+builtins[(e)$1] )); then
      REPLY=builtin
    elif (( $+commands[(e)$1] )); then
      REPLY=command
    # zsh 5.2 and older have a bug whereby running 'type -w ./sudo' implicitly
    # runs 'hash ./sudo=/usr/local/bin/./sudo' (assuming /usr/local/bin/sudo
    # exists and is in $PATH).  Avoid triggering the bug, at the expense of
    # falling through to the $() below, incurring a fork.  (Issue #354.)
    #
    # The first disjunct mimics the isrelative() C call from the zsh bug.
    elif {  [[ $1 != */* ]] || is-at-least 5.3 } &&
         ! builtin type -w -- $1 >/dev/null 2>&1; then
      REPLY=none
    fi
  fi
  if ! (( $+REPLY )); then
    # Note that 'type -w' will run 'rehash' implicitly.
    #
    # We 'unalias' in a subshell, so the parent shell is not affected.
    #
    # The colon command is there just to avoid a command substitution that
    # starts with an arithmetic expression [«((…))» as the first thing inside
    # «$(…)»], which is area that has had some parsing bugs before 5.6
    # (approximately).
    REPLY="${$(:; (( aliases_allowed )) || unalias -- $1 2>/dev/null; LC_ALL=C builtin type -w -- $1 2>/dev/null)##*: }"
    if [[ $REPLY == 'alias' ]]; then
      may_cache=0
    fi
  fi

  # Cache population
  if (( may_cache )) && (( $+_zsh_highlight_main__command_type_cache )); then
    _zsh_highlight_main__command_type_cache[(e)$1]=$REPLY
  fi
}

# Check whether the first argument is a redirection operator token.
# Report result via the exit code.
_zsh_highlight_main__is_redirection() {
  # A redirection operator token:
  # - starts with an optional single-digit number;
  # - then, has a '<' or '>' character;
  # - is not a process substitution [<(...) or >(...)].
  # - is not a numeric glob <->
  [[ $1 == (<0-9>|)(\<|\>)* ]] && [[ $1 != (\<|\>)$'\x28'* ]] && [[ $1 != *'<'*'-'*'>'* ]]
}

# Resolve alias.
#
# Takes a single argument.
#
# The result will be stored in REPLY.
_zsh_highlight_main__resolve_alias() {
  if zmodload -e zsh/parameter; then
    REPLY=${aliases[$arg]}
  else
    REPLY="${"$(alias -- $arg)"#*=}"
  fi
}

# Check that the top of $braces_stack has the expected value.  If it does, set
# the style according to $2; otherwise, set style=unknown-token.
#
# $1: character expected to be at the top of $braces_stack
# $2: optional assignment to style it if matches
# return value is 0 if there is a match else 1
_zsh_highlight_main__stack_pop() {
  if [[ $braces_stack[1] == $1 ]]; then
    braces_stack=${braces_stack:1}
    if (( $+2 )); then
      style=$2
    fi
    return 0
  else
    style=unknown-token
    return 1
  fi
}

# Main syntax highlighting function.
_zsh_highlight_highlighter_main_paint()
{
  setopt localoptions extendedglob

  # At the PS3 prompt and in vared, highlight nothing.
  #
  # (We can't check this in _zsh_highlight_highlighter_main_predicate because
  # if the predicate returns false, the previous value of region_highlight
  # would be reused.)
  if [[ $CONTEXT == (select|vared) ]]; then
    return
  fi

  typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
  typeset -a ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
  typeset -a ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW
  local -a options_to_set reply # used in callees
  local REPLY

  if [[ $zsyh_user_options[ignorebraces] == on || ${zsyh_user_options[ignoreclosebraces]:-off} == on ]]; then
    local right_brace_is_recognised_everywhere=false
  else
    local right_brace_is_recognised_everywhere=true
  fi

  if [[ $zsyh_user_options[pathdirs] == on ]]; then
    options_to_set+=( PATH_DIRS )
  fi

  ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=(
    '|' '||' ';' '&' '&&'
    '|&'
    '&!' '&|'
    # ### 'case' syntax, but followed by a pattern, not by a command
    # ';;' ';&' ';|'
  )
  ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(
    'builtin' 'command' 'exec' 'nocorrect' 'noglob'
    'pkexec' # immune to #121 because it's usually not passed --option flags
  )

  # Tokens that, at (naively-determined) "command position", are followed by
  # a de jure command position.  All of these are reserved words.
  ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW=(
    $'\x7b' # block
    $'\x28' # subshell
    '()' # anonymous function
    'while'
    'until'
    'if'
    'then'
    'elif'
    'else'
    'do'
    'time'
    'coproc'
    '!' # reserved word; unrelated to $histchars[1]
  )

  _zsh_highlight_main_highlighter_highlight_list -$#PREBUFFER '' 1 "$PREBUFFER$BUFFER"

  # end is a reserved word
  local start end_ style
  for start end_ style in $reply; do
    (( start >= end_ )) && { print -r -- >&2 "zsh-syntax-highlighting: BUG: _zsh_highlight_highlighter_main_paint: start($start) >= end($end_)"; return }
    (( end_ <= 0 )) && continue
    (( start < 0 )) && start=0 # having start<0 is normal with e.g. multiline strings
    _zsh_highlight_main_calculate_fallback $style
    _zsh_highlight_add_highlight $start $end_ $reply
  done
}

# $1 is the offset of $4 from the parent buffer. Added to the returned highlights.
# $2 is the initial braces_stack (for a closing paren).
# $3 is 1 if $4 contains the end of $BUFFER, else 0.
# $4 is the buffer to highlight.
# Returns:
# $REPLY: $buf[REPLY] is the last character parsed.
# $reply is an array of region_highlight additions.
# exit code is 0 if the braces_stack is empty, 1 otherwise.
_zsh_highlight_main_highlighter_highlight_list()
{
  integer start_pos=0 end_pos buf_offset=$1 has_end=$3
  local buf=$4 highlight_glob=true arg style
  local in_array_assignment=false # true between 'a=(' and the matching ')'
  integer len=$#buf
  local -a match mbegin mend list_highlights
  list_highlights=()

  # "R" for round
  # "Q" for square
  # "Y" for curly
  # "S" for $( )
  # "D" for do/done
  # "$" for 'end' (matches 'foreach' always; also used with cshjunkiequotes in repeat/while)
  # "?" for 'if'/'fi'; also checked by 'elif'/'else'
  # ":" for 'then'
  local braces_stack=$2

  # State machine
  #
  # The states are:
  # - :start:      Command word
  # - :alias:      :start: and alias expansion is allowed
  # - :sudo_opt:   A leading-dash option to sudo (such as "-u" or "-i")
  # - :sudo_arg:   The argument to a sudo leading-dash option that takes one,
  #                when given as a separate word; i.e., "foo" in "-u foo" (two
  #                words) but not in "-ufoo" (one word).
  # - :regular:    "Not a command word", and command delimiters are permitted.
  #                Mainly used to detect premature termination of commands.
  # - :always:     The word 'always' in the «{ foo } always { bar }» syntax.
  #
  # When the kind of a word is not yet known, $this_word / $next_word may contain
  # multiple states.  For example, after "sudo -i", the next word may be either
  # another --flag or a command name, hence the state would include both :start:
  # and :sudo_opt:.
  #
  # The tokens are always added with both leading and trailing colons to serve as
  # word delimiters (an improvised array); [[ $x == *:foo:* ]] and x=${x//:foo:/}
  # will DTRT regardless of how many elements or repetitions $x has..
  #
  # Handling of redirections: upon seeing a redirection token, we must stall
  # the current state --- that is, the value of $this_word --- for two iterations
  # (one for the redirection operator, one for the word following it representing
  # the redirection target).  Therefore, we set $in_redirection to 2 upon seeing a
  # redirection operator, decrement it each iteration, and stall the current state
  # when it is non-zero.  Thus, upon reaching the next word (the one that follows
  # the redirection operator and target), $this_word will still contain values
  # appropriate for the word immediately following the word that preceded the
  # redirection operator.
  #
  # The "the previous word was a redirection operator" state is not communicated
  # to the next iteration via $next_word/$this_word as usual, but via
  # $in_redirection.  The value of $next_word from the iteration that processed
  # the operator is discarded.
  #
  local this_word=':start::alias:' next_word
  integer in_redirection
  # Processing buffer
  local proc_buf="$buf"
  local -a args
  if [[ $zsyh_user_options[interactivecomments] == on ]]; then
    args=(${(zZ+c+)buf})
  else
    args=(${(z)buf})
  fi
  for arg in $args; do
    # Initialize $next_word.
    if (( in_redirection )); then
      (( --in_redirection ))
    fi
    if (( in_redirection == 0 )); then
      # Initialize $next_word to its default value.
      next_word=':regular:'
    else
      # Stall $next_word.
    fi

    # Initialize per-"simple command" [zshmisc(1)] variables:
    #
    #   $already_added       (see next paragraph)
    #   $style               how to highlight $arg
    #   $in_array_assignment boolean flag for "between '(' and ')' of array assignment"
    #   $highlight_glob      boolean flag for "'noglob' is in effect"
    #
    # $already_added is set to 1 to disable adding an entry to region_highlight
    # for this iteration.  Currently, that is done for "" and $'' strings,
    # which add the entry early so escape sequences within the string override
    # the string's color.
    integer already_added=0
    style=unknown-token
    if [[ $this_word == *':alias:'* ]]; then
      in_array_assignment=false
      if [[ $arg == 'noglob' ]]; then
        highlight_glob=false
      fi
    fi

    # Compute the new $start_pos and $end_pos, skipping over whitespace in $buf.
    if [[ $arg == ';' ]] ; then
      # We're looking for either a semicolon or a newline, whichever comes
      # first.  Both of these are rendered as a ";" (SEPER) by the ${(z)..}
      # flag.
      #
      # We can't use the (Z+n+) flag because that elides the end-of-command
      # token altogether, so 'echo foo\necho bar' (two commands) becomes
      # indistinguishable from 'echo foo echo bar' (one command with three
      # words for arguments).
      local needle=$'[;\n]'
      integer offset=$(( ${proc_buf[(i)$needle]} - 1 ))
      (( start_pos += offset ))
      (( end_pos = start_pos + $#arg ))
    else
      # The line was:
      #
      # integer offset=$(((len-start_pos)-${#${proc_buf##([[:space:]]|\\[[:space:]])#}}))
      #
      # - len-start_pos is length of current proc_buf; basically: initial length minus where
      #   we are, and proc_buf is chopped to the "where we are" (compare the "previous value
      #   of start_pos" below, and the len-(start_pos-offset) = len-start_pos+offset)
      # - what's after main minus sign is: length of proc_buf without spaces at the beginning
      # - so what the line actually did, was computing length of the spaces!
      # - this can be done via (#b) flag, like below
      if [[ "$proc_buf" = (#b)(#s)(([[:space:]]|\\$'\n')##)* ]]; then
          # The first, outer parenthesis
          integer offset="${#match[1]}"
      else
          integer offset=0
      fi
      ((start_pos+=offset))
      ((end_pos=$start_pos+${#arg}))
    fi

    # Compute the new $proc_buf. We advance it
    # (chop off characters from the beginning)
    # beyond what end_pos points to, by skipping
    # as many characters as end_pos was advanced.
    #
    # end_pos was advanced by $offset (via start_pos)
    # and by $#arg. Note the `start_pos=$end_pos`
    # below.
    #
    # As for the [,len]. We could use [,len-start_pos+offset]
    # here, but to make it easier on eyes, we use len and
    # rely on the fact that Zsh simply handles that. The
    # length of proc_buf is len-start_pos+offset because
    # we're chopping it to match current start_pos, so its
    # length matches the previous value of start_pos.
    #
    # Why [,-1] is slower than [,length] isn't clear.
    proc_buf="${proc_buf[offset + $#arg + 1,len]}"

    # Handle the INTERACTIVE_COMMENTS option.
    #
    # We use the (Z+c+) flag so the entire comment is presented as one token in $arg.
    if [[ $zsyh_user_options[interactivecomments] == on && $arg[1] == $histchars[3] ]]; then
      if [[ $this_word == *(':regular:'|':start:')* ]]; then
        style=comment
      else
        style=unknown-token # prematurely terminated
      fi
      _zsh_highlight_main_add_region_highlight $start_pos $end_pos $style
      already_added=1
      start_pos=$end_pos
      continue
    fi

    # Analyse the current word.
    if _zsh_highlight_main__is_redirection $arg ; then
      if (( in_redirection )); then
        _zsh_highlight_main_add_region_highlight $start_pos $end_pos unknown-token
        already_added=1
      else
        in_redirection=2
      fi
    fi

    # Special-case the first word after 'sudo'.
    if (( ! in_redirection )); then
      if [[ $this_word == *':sudo_opt:'* ]] && [[ $arg != -* ]]; then
        this_word=${this_word//:sudo_opt:/}
      fi
    fi

    # Parse the sudo command line
    if (( ! in_redirection )); then
      if [[ $this_word == *':sudo_opt:'* ]]; then
        case "$arg" in
          # Flag that requires an argument
          '-'[Cgprtu]) this_word=${this_word//:start:/};
                       this_word=${this_word//:alias:/};
                       next_word=':sudo_arg:';;
          # This prevents misbehavior with sudo -u -otherargument
          '-'*)        this_word=${this_word//:start:/};
                       this_word=${this_word//:alias:/};
                       next_word+=':start:';
                       next_word+=':sudo_opt:';;
          *)           ;;
        esac
      elif [[ $this_word == *':sudo_arg:'* ]]; then
        next_word+=':sudo_opt:'
        next_word+=':start:'
      fi
   fi

   # The Great Fork: is this a command word?  Is this a non-command word?
   if [[ $this_word == *':always:'* && $arg == 'always' ]]; then
     # try-always construct
     style=reserved-word # de facto a reserved word, although not de jure
     next_word=':start:' # :alias: will be added to $next_word when $this_word is \x7b.
   elif [[ $this_word == *':start:'* ]] && (( in_redirection == 0 )); then # $arg is the command word
     if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS:#"$arg"} ]]; then
      style=precommand
     elif [[ "$arg" = "sudo" ]] && { _zsh_highlight_main__type sudo; [[ -n $REPLY && $REPLY != "none" ]] }; then
      style=precommand
      next_word=${next_word//:regular:/}
      next_word=${next_word//:alias:/}
      next_word+=':sudo_opt:'
      next_word+=':start:'
     else
      _zsh_highlight_main_highlighter_expand_path $arg
      local expanded_arg="$REPLY"
      if [[ $arg != $expanded_arg ]]; then
        this_word=${this_word//:alias:/}
      fi
      _zsh_highlight_main__type ${expanded_arg}
      local res="$REPLY"
      () {
        # Special-case: command word is '$foo', like that, without braces or anything.
        #
        # That's not entirely correct --- if the parameter's value happens to be a reserved
        # word, the parameter expansion will be highlighted as a reserved word --- but that
        # incorrectness is outweighed by the usability improvement of permitting the use of
        # parameters that refer to commands, functions, and builtins.
        local -a match mbegin mend
        local MATCH; integer MBEGIN MEND
        if [[ $res == none ]] && (( ${+parameters} )) &&
           [[ ${arg[1]} == \$ ]] && [[ ${arg:1} =~ ^([A-Za-z_][A-Za-z0-9_]*|[0-9]+)$ ]] &&
           (( ${+parameters[(e)${MATCH}]} )) && [[ ${parameters[(e)$MATCH]} != *special* ]]
           then
          _zsh_highlight_main__type ${(P)MATCH}
          res=$REPLY
        fi
      }
      case $res in
        reserved)       # reserved word
                        style=reserved-word
                        #
                        # Match braces.
                        case $arg in
                          ($'\x7b')
                            braces_stack='Y'"$braces_stack"
                            next_word+=':alias:'
                            ;;
                          ($'\x7d')
                            # We're at command word, so no need to check $right_brace_is_recognised_everywhere
                            _zsh_highlight_main__stack_pop 'Y' reserved-word
                            if [[ $style == reserved-word ]]; then
                              next_word+=':always:'
                            fi
                            ;;
                          ('do')
                            braces_stack='D'"$braces_stack"
                            ;;
                          ('done')
                            _zsh_highlight_main__stack_pop 'D' reserved-word
                            ;;
                          ('if')
                            braces_stack=':?'"$braces_stack"
                            ;;
                          ('then')
                            _zsh_highlight_main__stack_pop ':' reserved-word
                            ;;
                          ('elif')
                            if [[ ${braces_stack[1]} == '?' ]]; then
                              braces_stack=':'"$braces_stack"
                            else
                              style=unknown-token
                            fi
                            ;;
                          ('else')
                            if [[ ${braces_stack[1]} == '?' ]]; then
                              :
                            else
                              style=unknown-token
                            fi
                            ;;
                          ('fi')
                            _zsh_highlight_main__stack_pop '?'
                            ;;
                          ('foreach')
                            braces_stack='$'"$braces_stack"
                            ;;
                          ('end')
                            _zsh_highlight_main__stack_pop '$' reserved-word
                            ;;
                        esac
                        ;;
        'suffix alias') style=suffix-alias;;
        alias)          () {
                          integer insane_alias
                          case $arg in
                            # Issue #263: aliases with '=' on their LHS.
                            #
                            # There are three cases:
                            #
                            # - Unsupported, breaks 'alias -L' output, but invokable:
                            ('='*) :;;
                            # - Unsupported, not invokable:
                            (*'='*) insane_alias=1;;
                            # - The common case:
                            (*) :;;
                          esac
                          if (( insane_alias )); then
                            style=unknown-token
                          else
                            # The common case.
                            style=alias
                            _zsh_highlight_main__resolve_alias $arg
                            local alias_target="$REPLY"
                            [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS:#"$alias_target"} && -z ${(M)ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS:#"$arg"} ]] && ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS+=($arg)
                          fi
                        }
                        ;;
        builtin)        style=builtin;;
        function)       style=function;;
        command)        style=command;;
        hashed)         style=hashed-command;;
        none)           if _zsh_highlight_main_highlighter_check_assign; then
                          style=assign
                          _zsh_highlight_main_add_region_highlight $start_pos $end_pos $style
                          already_added=1
                          local i=$(( arg[(i)=] + 1 ))
                          if [[ $arg[i] == '(' ]]; then
                            in_array_assignment=true
                          else
                            # assignment to a scalar parameter.
                            # (For array assignments, the command doesn't start until the ")" token.)
                            next_word+=':start:'
                            next_word+=':alias:'
                            if (( start_pos + i <= end_pos )); then
                              () {
                                local highlight_glob=false
                                [[ $zsyh_user_options[globassign] == on ]] && highlight_glob=true
                                _zsh_highlight_main_highlighter_highlight_argument $i
                              }
                            fi
                          fi
                        elif [[ $arg[0,1] = $histchars[0,1] ]] && (( $#arg[0,2] == 2 )); then
                          style=history-expansion
                        elif [[ $arg[0,1] == $histchars[2,2] ]]; then
                          style=history-expansion
                        elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]]; then
                          if [[ $this_word == *':regular:'* ]]; then
                            # This highlights empty commands (semicolon follows nothing) as an error.
                            # Zsh accepts them, though.
                            style=commandseparator
                          else
                            style=unknown-token
                          fi
                        elif (( in_redirection == 2 )); then
                          style=redirection
                        elif [[ $arg[1,2] == '((' ]]; then
                          # Arithmetic evaluation.
                          #
                          # Note: prior to zsh-5.1.1-52-g4bed2cf (workers/36669), the ${(z)...}
                          # splitter would only output the '((' token if the matching '))' had
                          # been typed.  Therefore, under those versions of zsh, BUFFER="(( 42"
                          # would be highlighted as an error until the matching "))" are typed.
                          #
                          # We highlight just the opening parentheses, as a reserved word; this
                          # is how [[ ... ]] is highlighted, too.
                          style=reserved-word
                          _zsh_highlight_main_add_region_highlight $start_pos $((start_pos + 2)) $style
                          already_added=1
                          if [[ $arg[-2,-1] == '))' ]]; then
                            _zsh_highlight_main_add_region_highlight $((end_pos - 2)) $end_pos $style
                            already_added=1
                          fi
                        elif [[ $arg == '()' ]]; then
                          # anonymous function
                          style=reserved-word
                        elif [[ $arg == $'\x28' ]]; then
                          # subshell
                          style=reserved-word
                          braces_stack='R'"$braces_stack"
                        elif [[ $arg == $'\x29' ]]; then
                          # end of subshell or command substitution
                          if _zsh_highlight_main__stack_pop 'S'; then
                            REPLY=$start_pos
                            reply=($list_highlights)
                            return 0
                          fi
                          _zsh_highlight_main__stack_pop 'R' reserved-word
                        else
                          if _zsh_highlight_main_highlighter_check_path $arg; then
                            style=$REPLY
                          else
                            style=unknown-token
                          fi
                        fi
                        ;;
        *)              _zsh_highlight_main_add_region_highlight $start_pos $end_pos arg0_$res
                        already_added=1
                        ;;
      esac
     fi
   fi
   if (( ! already_added )) && [[ $style == unknown-token ]] && # not handled by the 'command word' codepath
      { (( in_redirection )) || [[ $this_word == *':regular:'* ]] || [[ $this_word == *':sudo_opt:'* ]] || [[ $this_word == *':sudo_arg:'* ]] }
   then # $arg is a non-command word
      case $arg in
        $'\x29') # subshell or end of array assignment
                 if $in_array_assignment; then
                   style=assign
                   in_array_assignment=false
                   next_word+=':start:'
                   next_word+=':alias:'
                 else
                   if _zsh_highlight_main__stack_pop 'S'; then
                     REPLY=$start_pos
                     reply=($list_highlights)
                     return 0
                   fi
                   # TODO: next_word can only be a command separator now
                   _zsh_highlight_main__stack_pop 'R' reserved-word
                 fi;;
        $'\x28\x29') # possibly a function definition
                 if [[ $zsyh_user_options[multifuncdef] == on ]] || false # TODO: or if the previous word was a command word
                 then
                   next_word+=':start:'
                   next_word+=':alias:'
                 fi
                 style=reserved-word
                 ;;
        *)       if false; then
                 elif [[ $arg = $'\x7d' ]] && $right_brace_is_recognised_everywhere; then
                   # Parsing rule: }
                   #
                   #     Additionally, `tt(})' is recognized in any position if neither the
                   #     tt(IGNORE_BRACES) option nor the tt(IGNORE_CLOSE_BRACES) option is set.
                   _zsh_highlight_main__stack_pop 'Y' reserved-word
                   if [[ $style == reserved-word ]]; then
                     next_word+=':always:'
                   fi
                 elif [[ $arg[0,1] = $histchars[0,1] ]] && (( $#arg[0,2] == 2 )); then
                   style=history-expansion
                 elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]]; then
                   if [[ $this_word == *':regular:'* ]]; then
                     style=commandseparator
                   else
                     style=unknown-token
                   fi
                 elif (( in_redirection == 2 )); then
                   style=redirection
                 else
                   _zsh_highlight_main_highlighter_highlight_argument 1
                   already_added=1
                 fi
                 ;;
      esac
    fi
    if ! (( already_added )); then
      _zsh_highlight_main_add_region_highlight $start_pos $end_pos $style
    fi
    if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR:#"$arg"} ]]; then
      if [[ $arg == ';' ]] && $in_array_assignment; then
        # literal newline inside an array assignment
        next_word=':regular:'
      else
        next_word=':start:'
        next_word+=':alias:'
        highlight_glob=true
      fi
    elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_CONTROL_FLOW:#"$arg"} && $this_word == *':start:'* ]]; then
      next_word=':start:'
      next_word+=':alias:'
    elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS:#"$arg"} && $this_word == *':start:'* ]]; then
      next_word=':start:'
      # Special-case two reserved words that _can_ be followed by aliases
      if [[ $arg == ('noglob'|'nocorrect') ]]; then
        next_word+=':alias:'
      fi
    elif [[ $arg == "repeat" && $this_word == *':start:'* ]]; then
      # skip the repeat-count word
      in_redirection=2
      # The redirection mechanism assumes $this_word describes the word
      # following the redirection.  Make it so.
      #
      # That word can be a command word with shortloops (`repeat 2 ls`)
      # or a command separator (`repeat 2; ls` or `repeat 2; do ls; done`).
      #
      # The repeat-count word will be handled like a redirection target.
      this_word=':start::alias::regular:'
    fi
    start_pos=$end_pos
    if (( in_redirection == 0 )); then
      # This is the default/common codepath.
      this_word=$next_word
    else
      # Stall $this_word.
    fi
  done
  REPLY=$(( end_pos - 1 ))
  reply=($list_highlights)
  return $(( $#braces_stack > 0 ))
}

# Check if $arg is variable assignment
_zsh_highlight_main_highlighter_check_assign()
{
    setopt localoptions extended_glob
    [[ $arg == [[:alpha:]_][[:alnum:]_]#(|\[*\])(|[+])=* ]] ||
      [[ $arg == [0-9]##(|[+])=* ]]
}

_zsh_highlight_main_highlighter_highlight_path_separators()
{
  local pos style_pathsep
  style_pathsep=$1_pathseparator
  reply=()
  [[ -z "$ZSH_HIGHLIGHT_STYLES[$style_pathsep]" || "$ZSH_HIGHLIGHT_STYLES[$1]" == "$ZSH_HIGHLIGHT_STYLES[$style_pathsep]" ]] && return 0
  for (( pos = start_pos; $pos <= end_pos; pos++ )) ; do
    if [[ $BUFFER[pos] == / ]]; then
      reply+=($((pos - 1)) $pos $style_pathsep)
    fi
  done
}

# Check if $1 is a path.
# If yes, return 0 and in $REPLY the style to use.
# Else, return non-zero (and the contents of $REPLY is undefined).
_zsh_highlight_main_highlighter_check_path()
{
  _zsh_highlight_main_highlighter_expand_path $1
  local expanded_path="$REPLY" tmp_path

  REPLY=path

  [[ -z $expanded_path ]] && return 1

  # Check if this is a blacklisted path
  if [[ $expanded_path[1] == / ]]; then
    tmp_path=$expanded_path
  else
    tmp_path=$PWD/$expanded_path
  fi
  tmp_path=$tmp_path:a

  while [[ $tmp_path != / ]]; do
    [[ -n ${(M)X_ZSH_HIGHLIGHT_DIRS_BLACKLIST:#$tmp_path} ]] && return 1
    tmp_path=$tmp_path:h
  done

  [[ -L $expanded_path ]] && return 0
  [[ -e $expanded_path ]] && return 0

  # Search the path in CDPATH
  local cdpath_dir
  for cdpath_dir in $cdpath ; do
    [[ -e "$cdpath_dir/$expanded_path" ]] && return 0
  done

  # If dirname($1) doesn't exist, neither does $1.
  [[ ! -d ${expanded_path:h} ]] && return 1

  # If this word ends the buffer, check if it's the prefix of a valid path.
  if (( has_end && (len == end_pos) )) &&
     [[ $WIDGET != zle-line-finish ]]; then
    local -a tmp
    tmp=( ${expanded_path}*(N) )
    (( $#tmp > 0 )) && REPLY=path_prefix && return 0
  fi

  # It's not a path.
  return 1
}

# Highlight an argument and possibly special chars in quotes starting at $1 in $arg
# This command will at least highlight $1 to end_pos with the default style
_zsh_highlight_main_highlighter_highlight_argument()
{
  local base_style=default i=$1 path_eligible=1 ret start style
  local -a highlights

  local -a match mbegin mend
  local MATCH; integer MBEGIN MEND

  case "$arg[i]" in
    '-')
      if [[ $arg[i+1] == - ]]; then
        base_style=double-hyphen-option
      else
        base_style=single-hyphen-option
      fi
      path_eligible=0
      ;;
    '=')
      if [[ $arg[i+1] == $'\x28' ]]; then
        (( i += 2 ))
        _zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,end_pos]
        ret=$?
        (( i += REPLY ))
        highlights+=(
          $(( start_pos + $1 - 1 )) $(( start_pos + i )) process-substitution
          $(( start_pos + $1 - 1 )) $(( start_pos + $1 + 1 )) process-substitution-delimiter
          $reply
        )
        if (( ret == 0 )); then
          highlights+=($(( start_pos + i - 1 )) $(( start_pos + i )) process-substitution-delimiter)
        fi
      fi
  esac

  for (( ; i <= end_pos - start_pos ; i += 1 )); do
    case "$arg[$i]" in
      "\\") (( i += 1 )); continue;;
      "'")
        _zsh_highlight_main_highlighter_highlight_single_quote $i
        (( i = REPLY ))
        highlights+=($reply)
        ;;
      '"')
        _zsh_highlight_main_highlighter_highlight_double_quote $i
        (( i = REPLY ))
        highlights+=($reply)
        ;;
      '`')
        _zsh_highlight_main_highlighter_highlight_backtick $i
        (( i = REPLY ))
        highlights+=($reply)
        ;;
      '$')
        path_eligible=0
        if [[ $arg[i+1] == "'" ]]; then
          path_eligible=1
          _zsh_highlight_main_highlighter_highlight_dollar_quote $i
          (( i = REPLY ))
          highlights+=($reply)
          continue
       elif [[ $arg[i+1] == $'\x28' ]]; then
          start=$i
          (( i += 2 ))
          _zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,end_pos]
          ret=$?
          (( i += REPLY ))
          highlights+=(
            $(( start_pos + start - 1)) $(( start_pos + i )) command-substitution
            $(( start_pos + start - 1)) $(( start_pos + start + 1)) command-substitution-delimiter
            $reply
          )
          if (( ret == 0 )); then
            highlights+=($(( start_pos + i - 1)) $(( start_pos + i )) command-substitution-delimiter)
          fi
          continue
        fi
        while [[ $arg[i+1] == [\^=~#+] ]]; do
          (( i += 1 ))
        done
        if [[ $arg[i+1] == [*@#?$!-] ]]; then
          (( i += 1 ))
        fi;;
      [\<\>])
        if [[ $arg[i+1] == $'\x28' ]]; then # \x28 = open paren
          start=$i
          (( i += 2 ))
          _zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,end_pos]
          ret=$?
          (( i += REPLY ))
          highlights+=(
            $(( start_pos + start - 1)) $(( start_pos + i )) process-substitution
            $(( start_pos + start - 1)) $(( start_pos + start + 1 )) process-substitution-delimiter
            $reply
          )
          if (( ret == 0 )); then
            highlights+=($(( start_pos + i - 1)) $(( start_pos + i )) process-substitution-delimiter)
          fi
          continue
        fi
        ;|
      *)
        if $highlight_glob && [[ ${arg[$i]} =~ ^[*?] || ${arg:$i-1} =~ ^\<[0-9]*-[0-9]*\> ]]; then
          highlights+=($(( start_pos + i - 1 )) $(( start_pos + i + $#MATCH - 1)) globbing)
          (( i += $#MATCH - 1 ))
          path_eligible=0
        else
          continue
        fi
        ;;
    esac
  done

  if (( path_eligible )) && _zsh_highlight_main_highlighter_check_path $arg[$1,end_pos]; then
    base_style=$REPLY
    _zsh_highlight_main_highlighter_highlight_path_separators $base_style
    highlights+=($reply)
  fi

  highlights=($(( start_pos + $1 - 1 )) $end_pos $base_style $highlights)
  _zsh_highlight_main_add_many_region_highlights $highlights
}

# Quote Helper Functions
#
# $arg is expected to be set to the current argument
# $start_pos is expected to be set to the start of $arg in $BUFFER
# $1 is the index in $arg which starts the quote
# $REPLY is returned as the end of quote index in $arg
# $reply is returned as an array of region_highlight additions

# Highlight single-quoted strings
_zsh_highlight_main_highlighter_highlight_single_quote()
{
  local arg1=$1 i q=\' style
  i=$arg[(ib:arg1+1:)$q]
  reply=()

  if [[ $zsyh_user_options[rcquotes] == on ]]; then
    while [[ $arg[i+1] == "'" ]]; do
      reply+=($(( start_pos + i - 1 )) $(( start_pos + i + 1 )) rc-quote)
      (( i++ ))
      i=$arg[(ib:i+1:)$q]
    done
  fi

  if [[ $arg[i] == "'" ]]; then
    style=single-quoted-argument
  else
    # If unclosed, i points past the end
    (( i-- ))
    style=single-quoted-argument-unclosed
  fi
  reply=($(( start_pos + arg1 - 1 )) $(( start_pos + i )) $style $reply)
  REPLY=$i
}

# Highlight special chars inside double-quoted strings
_zsh_highlight_main_highlighter_highlight_double_quote()
{
  local -a match mbegin mend saved_reply
  local MATCH; integer MBEGIN MEND
  local i j k ret style
  reply=()

  for (( i = $1 + 1 ; i <= end_pos - start_pos ; i += 1 )) ; do
    (( j = i + start_pos - 1 ))
    (( k = j + 1 ))
    case "$arg[$i]" in
      '"') break;;
      '`') saved_reply=($reply)
           _zsh_highlight_main_highlighter_highlight_backtick $i
           (( i = REPLY ))
           reply=($saved_reply $reply)
           continue
           ;;
      '$' ) style=dollar-double-quoted-argument
            # Look for an alphanumeric parameter name.
            if [[ ${arg:$i} =~ ^([A-Za-z_][A-Za-z0-9_]*|[0-9]+) ]] ; then
              (( k += $#MATCH )) # highlight the parameter name
              (( i += $#MATCH )) # skip past it
            elif [[ ${arg:$i} =~ ^[{]([A-Za-z_][A-Za-z0-9_]*|[0-9]+)[}] ]] ; then
              (( k += $#MATCH )) # highlight the parameter name and braces
              (( i += $#MATCH )) # skip past it
            elif [[ $arg[i+1] == '$' ]]; then
              # $$ - pid
              (( k += 1 )) # highlight both dollar signs
              (( i += 1 )) # don't consider the second one as introducing another parameter expansion
            elif [[ $arg[i+1] == [-#*@?] ]]; then
              # $#, $*, $@, $?, $- - like $$ above
              (( k += 1 )) # highlight both dollar signs
              (( i += 1 )) # don't consider the second one as introducing another parameter expansion
            elif [[ $arg[i+1] == $'\x28' ]]; then
              (( i += 2 ))
              saved_reply=($reply)
              _zsh_highlight_main_highlighter_highlight_list $(( start_pos + i - 1 )) S $has_end $arg[i,end_pos]
              ret=$?
              (( i += REPLY ))
              reply=(
                $saved_reply
                $j $(( start_pos + i )) command-substitution
                $j $(( j + 2 )) command-substitution-delimiter
                $reply
              )
              if (( ret == 0 )); then
                reply+=($(( start_pos + i - 1 )) $(( start_pos + i )) command-substitution-delimiter)
              fi
              continue
            else
              continue
            fi
            ;;
      "\\") style=back-double-quoted-argument
            if [[ \\\`\"\$${histchars[1]} == *$arg[$i+1]* ]]; then
              (( k += 1 )) # Color following char too.
              (( i += 1 )) # Skip parsing the escaped char.
            else
              continue
            fi
            ;;
      ($histchars[1]) # ! - may be a history expansion
            if [[ $arg[i+1] != ('='|$'\x28'|$'\x7b'|[[:blank:]]) ]]; then
              style=history-expansion
            else
              continue
            fi
            ;;
      *) continue ;;

    esac
    reply+=($j $k $style)
  done

  if [[ $arg[i] == '"' ]]; then
    style=double-quoted-argument
  else
    # If unclosed, i points past the end
    (( i-- ))
    style=double-quoted-argument-unclosed
  fi
  reply=($(( start_pos + $1 - 1)) $(( start_pos + i )) $style $reply)
  REPLY=$i
}

# Highlight special chars inside dollar-quoted strings
_zsh_highlight_main_highlighter_highlight_dollar_quote()
{
  local -a match mbegin mend
  local MATCH; integer MBEGIN MEND
  local i j k style
  local AA
  integer c
  reply=()

  for (( i = $1 + 2 ; i <= end_pos - start_pos ; i += 1 )) ; do
    (( j = i + start_pos - 1 ))
    (( k = j + 1 ))
    case "$arg[$i]" in
      "'") break;;
      "\\") style=back-dollar-quoted-argument
            for (( c = i + 1 ; c <= end_pos - start_pos ; c += 1 )); do
              [[ "$arg[$c]" != ([0-9xXuUa-fA-F]) ]] && break
            done
            AA=$arg[$i+1,$c-1]
            # Matching for HEX and OCT values like \0xA6, \xA6 or \012
            if [[    "$AA" =~ "^(x|X)[0-9a-fA-F]{1,2}"
                  || "$AA" =~ "^[0-7]{1,3}"
                  || "$AA" =~ "^u[0-9a-fA-F]{1,4}"
                  || "$AA" =~ "^U[0-9a-fA-F]{1,8}"
               ]]; then
              (( k += $#MATCH ))
              (( i += $#MATCH ))
            else
              if (( $#arg > $i+1 )) && [[ $arg[$i+1] == [xXuU] ]]; then
                # \x not followed by hex digits is probably an error
                style=unknown-token
              fi
              (( k += 1 )) # Color following char too.
              (( i += 1 )) # Skip parsing the escaped char.
            fi
            ;;
      *) continue ;;

    esac
    reply+=($j $k $style)
  done

  if [[ $arg[i] == "'" ]]; then
    style=dollar-quoted-argument
  else
    # If unclosed, i points past the end
    (( i-- ))
    style=dollar-quoted-argument-unclosed
  fi
  reply=($(( start_pos + $1 - 1 )) $(( start_pos + i )) $style $reply)
  REPLY=$i
}

# Highlight backtick substitutions
_zsh_highlight_main_highlighter_highlight_backtick()
{
  # buf is the contents of the backticks with a layer of backslashes removed.
  # last is the index of arg for the start of the string to be copied into buf.
  #     It is either one past the beginning backtick or one past the last backslash.
  # offset is a count of consumed \ (the delta between buf and arg).
  # offsets is an array indexed by buf offset of when the delta between buf and arg changes.
  #     It is sparse, so search backwards to the last value
  local buf highlight style=back-quoted-argument-unclosed style_end
  local -i arg1=$1 end_ i=$1 last offset=0 start subshell_has_end=0
  local -a highlight_zone highlights offsets
  reply=()

  last=$(( arg1 + 1 ))
  # Remove one layer of backslashes and find the end
  while i=$arg[(ib:i+1:)[\\\\\`]]; do # find the next \ or `
    if (( i > end_pos - start_pos )); then
      buf=$buf$arg[last,i]
      offsets[i-arg1-offset]='' # So we never index past the end
      (( i-- ))
      subshell_has_end=$(( has_end && (start_pos + i == len) ))
      break
    fi

    if [[ $arg[i] == '\' ]]; then
      (( i++ ))
      # POSIX XCU 2.6.3
      if [[ $arg[i] == ('$'|'`'|'\') ]]; then
        buf=$buf$arg[last,i-2]
        (( offset++ ))
        # offsets is relative to buf, so adjust by -arg1
        offsets[i-arg1-offset]=$offset
      else
        buf=$buf$arg[last,i-1]
      fi
    else # it's an unquoted ` and this is the end
      style=back-quoted-argument
      style_end=back-quoted-argument-delimiter
      buf=$buf$arg[last,i-1]
      offsets[i-arg1-offset]='' # So we never index past the end
      break
    fi
    last=$i
  done

  _zsh_highlight_main_highlighter_highlight_list 0 '' $subshell_has_end $buf

  # Munge the reply to account for removed backslashes
  for start end_ highlight in $reply; do
    start=$(( start_pos + arg1 + start + offsets[(Rb:start:)?*] ))
    end_=$(( start_pos + arg1 + end_ + offsets[(Rb:end_:)?*] ))
    highlights+=($start $end_ $highlight)
    if [[ $highlight == back-quoted-argument-unclosed && $style == back-quoted-argument ]]; then
      # An inner backtick command substitution is unclosed, but this level is closed
      style_end=unknown-token
    fi
  done

  reply=(
    $(( start_pos + arg1 - 1 )) $(( start_pos + i )) $style
    $(( start_pos + arg1 - 1 )) $(( start_pos + arg1 )) back-quoted-argument-delimiter
    $highlights
  )
  if (( $#style_end )); then
    reply+=($(( start_pos + i - 1)) $(( start_pos + i )) $style_end)
  fi
  REPLY=$i
}

# Called with a single positional argument.
# Perform filename expansion (tilde expansion) on the argument and set $REPLY to the expanded value.
#
# Does not perform filename generation (globbing).
_zsh_highlight_main_highlighter_expand_path()
{
  (( $# == 1 )) || print -r -- >&2 "zsh-syntax-highlighting: BUG: _zsh_highlight_main_highlighter_expand_path: called without argument"

  # The $~1 syntax normally performs filename generation, but not when it's on the right-hand side of ${x:=y}.
  setopt localoptions nonomatch
  unset REPLY
  : ${REPLY:=${(Q)${~1}}}
}

# -------------------------------------------------------------------------------------------------
# Main highlighter initialization
# -------------------------------------------------------------------------------------------------

_zsh_highlight_main__precmd_hook() {
  _zsh_highlight_main__command_type_cache=()
}

autoload -Uz add-zsh-hook
if add-zsh-hook precmd _zsh_highlight_main__precmd_hook 2>/dev/null; then
  # Initialize command type cache
  typeset -gA _zsh_highlight_main__command_type_cache
else
  print -r -- >&2 'zsh-syntax-highlighting: Failed to load add-zsh-hook. Some speed optimizations will not be used.'
  # Make sure the cache is unset
  unset _zsh_highlight_main__command_type_cache
fi
typeset -ga X_ZSH_HIGHLIGHT_DIRS_BLACKLIST
