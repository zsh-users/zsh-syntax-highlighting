#!/bin/zsh

source "../../zsh-syntax-highlighting.zsh"

if [ -n "$1" ]; then
    # Load from given file
    PREBUFFER=""
    BUFFER="$(<$1)"

    _zsh_highlight_main_highlighter

    # This output can be diffed to detect changes in operation 
    print -rl -- "${region_highlight[@]}"
else
    echo "Usage: ./parse.zsh {file}"
fi
