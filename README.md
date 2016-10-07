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

zsh-syntax-highlighting works by hooking into the Zsh Line Editor (ZLE) and
computing syntax highlighting for the command-line buffer as it stands at the
time z-sy-h's hook is invoked.

In zsh 5.2 and older,
`zsh-syntax-highlighting.zsh` hooks into ZLE by wrapping ZLE widgets.  It must be sourced after all
custom widgets have been created (i.e., after all `zle -N` calls and after
running `compinit`) in order to be able to wrap all of them.
Widgets created after z-sy-h is sourced will work, but will not update the
syntax highlighting.

In zsh 5.3 and newer,
zsh-syntax-highlighting uses the `add-zle-hook-widget` facility to install
a `zle-line-pre-redraw` hook.  Hooks are run in order of registration,
therefore, z-sy-h must be sourced (and register its hook) after anything else
that adds hooks that modify the command-line buffer.

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
