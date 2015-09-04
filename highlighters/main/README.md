zsh-syntax-highlighting / highlighters / main
=============================================

This is the ***main*** highlighter, that highlights:

* Commands
* Options
* Arguments
* Paths
* Files
* Strings

How to activate it
------------------
To activate it, add it to `ZSH_HIGHLIGHT_HIGHLIGHTERS`:

    ZSH_HIGHLIGHT_HIGHLIGHTERS=( [...] main)

This highlighter is active by default.


How to tweak it
---------------
This highlighter defines the following styles:

* `unknown-token` - unknown tokens / errors
* `reserved-word` - shell reserved words
* `alias` - aliases
* `builtin` - shell builtin commands
* `function` - functions
* `command` - commands
* `command_prefix` - command prefixes
* `precommand` - precommands (i.e. exec, builtin, ...)
* `commandseparator` - command separation tokens
* `redirection` - redirection operators
* `hashed-command` - hashed commands
* `path` - paths
* `path_prefix` - path prefixes
* `path_approx` - approximated paths
* `globbing` - globbing expressions
* `history-expansion` - history expansion expressions
* `single-hyphen-option` - single hyphen options
* `double-hyphen-option` - double hyphen options
* `back-quoted-argument` - backquoted expressions
* `single-quoted-argument` - single quoted arguments
* `double-quoted-argument` - double quoted arguments
* `dollar-double-quoted-argument` -  dollar double quoted arguments
* `back-double-quoted-argument` -  back double quoted arguments
* `assign` - variable assignments
* `default` - parts of the buffer that do not match anything

To override one of those styles, change its entry in `ZSH_HIGHLIGHT_STYLES`, for example in `~/.zshrc`:

    # To differentiate aliases from other command types
    ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'
    
    # To have paths colored instead of underlined
    ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
    
    # To disable highlighting of globbing expressions
    ZSH_HIGHLIGHT_STYLES[globbing]='none'

The syntax for declaring styles is [documented here](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#SEC135).


By default files are colored in the same fashion as `ls` command, namely by comparing file attributes and extension with the content of LS_COLORS environment variable. To override this behaviour change the value of ZSH_HIGHLIGHT_STYLES[file] in ~/.zshrc:

    # To have all files in one color irrespectively of attributes and extensions
    ZSH_HIGHLIGHT_STYLES[file]='fg=green'

    # To disable higlighting for all files
    ZSH_HIGHLIGHT_STYLES[file]='none'

    # To use LS_COLORS do not set this style at all
    # ZSH_HIGHLIGHT_STYLES[file]

It is also possible to change the color for one single file attribute/extenstion. To achieve this modify ZSH_HIGHLIGHT_FILES in ~/.zshrc:

    # To set color for executables
    ZSH_HIGHLIGHT_FILES[ex]='fg=119'

    # To set color for files with sticky bit
    ZSH_HIGHLIGHT_FILES[st]='fg=7,bg=4'

    # To set color for files with pdf extenstion
    ZSH_HIGHLIGHT_FILES[*.pdf]='fg=34'

Note that LS_COLORS uses ANSI color codes (not names as 'green') and so does ZSH_HIGHLIGHT_FILES by default, but ZSH_HIGHLIGHT_FILES[*.pdf]='fg=green' is possible too. However if you set color code by hand you must guarantee that your terminal is capable to display that color properly. In above examples 256 color palette is used. In case of doubt it is better not to set ZSH_HIGHLIGHT_STYLES[file] and change LS_COLORS via ~/.dircolors file. If ~/.dircolors files doesn't exist one can generate it by `dircolor` command.
