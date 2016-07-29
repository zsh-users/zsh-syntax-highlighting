zsh-syntax-highlighting
=======================

**[Fish shell][fish]-like like syntax highlighting for [Zsh][zsh].**

*Requirements: zsh 4.3.17+.*

[fish]: http://www.fishshell.com/
[zsh]: http://www.zsh.org/

This package provides syntax highlighing for the shell zsh.  It enables
highlighing of commands whilst they are typed at a zsh prompt into an
interactive terminal.  This helps in reviewing commands before running
them, particularly in catching syntax errors.

[![Screenshot](images/preview-smaller.png)](images/preview.png)


How to install
--------------

See [INSTALL.md](INSTALL.md).


FAQ
---

### Why must `zsh-syntax-highlighting.zsh` be sourced at the end of the `.zshrc` file?

`zsh-syntax-highlighting.zsh` wraps ZLE widgets.  It must be sourced after all
custom widgets have been created (i.e., after all `zle -N` calls and after
running `compinit`).  Widgets created later will work, but will not update the
syntax highlighting.

### Why does syntax highlighting not work while searching history?

In `zsh` versions before 5.3 is not possible for `zsh-syntax-highlighting.zsh`
to know if an incremental search is currently active and that matched parts of the
buffer should be underlined (or otherwise highlighted). Therefore, it is not possible
for `zsh-syntax-highlighting.zsh` to apply syntax highlighting and to underline the
matched part of the search. While searching the history, the latter is more important,
so syntax highlighting is disabled in this case.

### How are new releases announced?

There is currently no "push" announcements channel.  However, the following
alternatives exist:

- GitHub's RSS feed of releases: https://github.com/zsh-users/zsh-syntax-highlighting/releases.atom
- An anitya entry: https://release-monitoring.org/project/7552/


How to tweak
------------

Syntax highlighting is done by pluggable highlighter scripts.  See the
[documentation on highlighters](docs/highlighters.md) for details and
configuration settings.
