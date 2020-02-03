zsh-syntax-highlighting / highlighters / files
----------------------------------------------

This is the `files` highlighter, that highlights existing files appearing on the
command line.


### Quickstart

If you are happy with your `LS_COLORS`, simply add the following line to your
`.zshrc` after sourcing `zsh-syntax-highlighting.zsh`:

```zsh
zsh_highlight_files_extract_ls_colors
```


### Configuration

Files are colored according to the associative arrays `ZSH_HIGHLIGHT_FILE_TYPES`
and `ZSH_HIGHLIGHT_FILE_PATTERNS`.  The values of `ZSH_HIGHLIGHT_FILE_TYPES` are
color specifications as in `ZSH_HIGHLIGHT_STYLES`, and the keys define which
file types are highlighted according to that style (following `LS_COLORS`):

* `fi` - ordinary files
* `di` - directories
* `ln` - symbolic links
* `pi` - pipes
* `so` - sockets
* `bd` - block devices
* `cd` - character devices
* `or` - broken symlinks
* `ex` - executable files
* `su` - files that have the suid bit set
* `sg` - files that have the sgid bit set
* `ow` - files that are world-writable
* `tw` - files that are world-writable and sticky
* `lp` - if set, the path-component of a filename is highlighted using this style

If a file would be highlighted `fi`, then it can be highlighted according to the
filename using `ZSH_HIGHLIGHT_FILE_PATTERNS` instead.  The keys of this
associative array are arbitrary glob patterns; the values are color
specifications.  For instance, if have `setopt extended_glob` and you write

```zsh
ZSH_HIGHLIGHT_FILE_PATTERNS[(#i)*.jpe#g]=red,bold
```

then the files `foo.jpg` and `bar.jPeG` will be colored red and bold.
