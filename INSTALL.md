# Installation

* [Manual (preferred)](#manual-git-clone)
* [Packages](#packages)
* [Plugin Managers](#plugin-managers)
* [System-Wide Installation](#system-wide-installation)

## Manual (Git Clone)

1. Clone this repository and source the script:

    ```sh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
    echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
    ```
    
    If `git` is not installed, download and extract a snapshot of the latest development tree from:
    ```
    https://github.com/zsh-users/zsh-syntax-highlighting/archive/master.tar.gz
    ```

2. Enable syntax highlighting in the current interactive shell (add the following to **the end** of your `.zshrc`):

    ```sh
    source ./zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ```

3. Start a new terminal session.

## Packages

| System  | Package |
| ------------- | ------------- |
| Arch Linux / Antergos / Manjaro / Hyperbola | [zsh-syntax-highlighting][arch-package], [zsh-syntax-highlighting-git][AUR-package] |
| Debian | [zsh-syntax-highlighting OBS repository][obs-repository], [zsh-syntax-highlighting in Stretch][debian-package] |
| CentOS / Fedora / RHEL / Scientific Linux | [zsh-syntax-highlighting OBS repository][obs-repository], [zsh-syntax-highlighting in Fedora 24+][fedora-package-alt] |
| FreeBSD / NetBSD | [shells/zsh-syntax-highlighting][freebsd-port] |
| Gentoo | [app-shells/zsh-syntax-highlighting][gentoo-repository] |
| macOS | [brew install zsh-syntax-highlighting][brew-package] |
| OpenBSD | [shells/zsh-syntax-highlighting][openbsd-port] |
| OpenSUSE / SLE | [zsh-syntax-highlighting OBS repository][obs-repository] |
| Ubuntu | [zsh-syntax-highlighting OBS repository][obs-repository], [zsh-syntax-highlighting in Xenial][ubuntu-package] |
| Void Linux | [zsh-syntax-highlighting in XBPS][void-package] |

[arch-package]: https://www.archlinux.org/packages/zsh-syntax-highlighting
[AUR-package]: https://aur.archlinux.org/packages/zsh-syntax-highlighting-git
[brew-package]: https://github.com/Homebrew/homebrew-core/blob/master/Formula/zsh-syntax-highlighting.rb
[debian-package]: https://packages.debian.org/zsh-syntax-highlighting
[fedora-package]: https://apps.fedoraproject.org/packages/zsh-syntax-highlighting
[fedora-package-alt]: https://bodhi.fedoraproject.org/updates/?packages=zsh-syntax-highlighting
[freebsd-port]: http://www.freshports.org/textproc/zsh-syntax-highlighting/
[gentoo-repository]: https://packages.gentoo.org/packages/app-shells/zsh-syntax-highlighting
[netbsd-port]: http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/shells/zsh-syntax-highlighting/
[obs-repository]: https://software.opensuse.org/download.html?project=shells%3Azsh-users%3Azsh-syntax-highlighting&package=zsh-syntax-highlighting
[openbsd-port]: https://cvsweb.openbsd.org/ports/shells/zsh-syntax-highlighting/
[ubuntu-package]: https://launchpad.net/ubuntu/+source/zsh-syntax-highlighting
[void-package]: https://github.com/void-linux/void-packages/tree/master/srcpkgs/zsh-syntax-highlighting

See also [repology's cross-distro index](https://repology.org/metapackage/zsh-syntax-highlighting/versions)

## Plugin Managers

Note that `zsh-syntax-highlighting` must be the last plugin sourced.

The zsh-syntax-highlighting authors recommend manual installation over the use
of a framework or plugin manager.

This list is incomplete as there are too many
[frameworks / plugin managers][framework-list] to list them all here.

[framework-list]: https://github.com/unixorn/awesome-zsh-plugins#frameworks


#### [Antigen](https://github.com/zsh-users/antigen)

Add `antigen bundle zsh-users/zsh-syntax-highlighting` to your `.zshrc`.

#### [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)

1. Clone this repository in oh-my-zsh's plugins directory:

    ```zsh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    ```

2. Activate the plugin in `~/.zshrc` by adding `zsh-syntax-highlighting` to the plugin list:

    ```zsh
    plugins=( [plugins...] zsh-syntax-highlighting)
    ```

3. Start a new terminal session.

#### [Prezto](https://github.com/sorin-ionescu/prezto)

Zsh-syntax-highlighting is included with Prezto. See the
[Prezto documentation][prezto-docs] to enable and configure highlighters.

[prezto-docs]: https://github.com/sorin-ionescu/prezto/tree/master/modules/syntax-highlighting

#### [zgen](https://github.com/tarjoilija/zgen)

Add `zgen load zsh-users/zsh-syntax-highlighting` to the end of your `.zshrc`.

#### [zplug](https://github.com/zplug/zplug)

Add `zplug "zsh-users/zsh-syntax-highlighting", defer:2` to your `.zshrc`.

#### [zplugin](https://github.com/psprint/zplugin)

Add `zplugin load zsh-users/zsh-syntax-highlighting` to the end of your
`.zshrc`.

## System-Wide Installation

Any of the above methods is suitable for a single-user installation,
which requires no special privileges. If, however, you desire to install
`zsh-syntax-highlighting` system-wide, you may do so by running

```zsh
make install
```

and directing your users to add

```zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

to their `.zshrc`s.
