zsh-syntax-highlighting
=======================

**[Fish shell](http://www.fishshell.com) like syntax highlighting for [Zsh](http://www.zsh.org).**

![](misc/screenshot.png)

*Requirements: zsh 4.3.17+.*


How to install
--------------

### Using packages

* Arch Linux: [community/zsh-syntax-highlighting](https://www.archlinux.org/packages/zsh-syntax-highlighting) / [AUR/zsh-syntax-highlighting-git](https://aur.archlinux.org/packages/zsh-syntax-highlighting-git)
* Gentoo: [mv overlay](http://gpo.zugaina.org/app-shells/zsh-syntax-highlighting)

### In your ~/.zshrc

* Clone this repository:

        git clone git://github.com/zsh-users/zsh-syntax-highlighting.git

  (or [download a snapshot](https://github.com/zsh-users/zsh-syntax-highlighting/archive/master.tar.gz))

* Source the script **at the end** of `~/.zshrc`:

        source /path/to/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

* Source `~/.zshrc`  to take changes into account:

        source ~/.zshrc


### With oh-my-zsh

* Download the script or clone this repository in [oh-my-zsh](http://github.com/robbyrussell/oh-my-zsh) plugins directory:

        cd ~/.oh-my-zsh/custom/plugins
        git clone git://github.com/zsh-users/zsh-syntax-highlighting.git

* Activate the plugin in `~/.zshrc` (in **last** position):

        plugins=( [plugins...] zsh-syntax-highlighting)

* Source `~/.zshrc`  to take changes into account:

        source ~/.zshrc


FAQ
---

### Why must `zsh-syntax-highlighting.zsh` be sourced at the end of the `.zshrc` file?

`zsh-syntax-highlighting.zsh` wraps ZLE widgets.  It must be sourced after all
custom widgets have been created (i.e., after all `zle -N` calls).

How to tweak
------------

Syntax highlighting is done by pluggable highlighter scripts, see the [highlighters directory](highlighters)
for documentation and configuration settings.
