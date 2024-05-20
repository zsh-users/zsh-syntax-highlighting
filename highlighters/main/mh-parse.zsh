#!/bin/sh

#
# This file runs main highlighter on a specified file
# i.e. parses the file with the highlighter. Outputs
# running time (stderr) and resulting region_highlight
# (stdout).
#

# Strive for -f
# .. occuring problems (no q flag), but at least try to quote $0 and $@
[[ -z "$ZSH_VERSION" ]] && exec /usr/bin/env zsh -f -c "source \"$0\" \"$1\" \"$2\" \"$3\""

ZERO="${(%):-%N}"
ZERO_RESOLVED="${ZERO:A:h}"

#
# Load Z-SY-H
#

if [[ -e "${ZERO_RESOLVED}/main-highlighter.zsh" ]]; then
    source "${ZERO_RESOLVED}/../../zsh-syntax-highlighting.zsh"
elif [[ -e "${0:A:h}/main-highlighter.zsh" ]]; then
    source "${0:A:h}/../../zsh-syntax-highlighting.zsh"
elif [[ -e "../../main-highlighter.zsh" ]]; then
    source "../../zsh-syntax-highlighting.zsh"
else
    print "Could not find zsh-syntax-highlighting.zsh, aborting"
    exit 1
fi

#
# Call _zsh_highlight_highlighter_main_paint
#

if [[ -r "$1" ]]; then
    # Load from given file
    PREBUFFER=""
    BUFFER="$(<$1)"

    typeset -F SECONDS
    SECONDS=0

    _zsh_highlight_highlighter_main_paint

    print -u2 "Main highlighter's running time: $SECONDS"

    # This output can be diffed to detect changes in operation
    print -rl -- "${region_highlight[@]}"
else
    if [[ -z "$1" ]]; then
        print -u2 "Usage: ./mh-parse.zsh {to-parse file}"
        exit 1
    else
        print -u2 "Unreadable to-parse file \`$1', aborting"
        exit 2
    fi
fi

exit 0

# vim:ft=zsh
