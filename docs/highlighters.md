zsh-syntax-highlighting / highlighters
======================================

Syntax highlighting is done by pluggable highlighters:

* `main` - the base highlighter, and the only one [active by default](highlighters/main.md).
* `brackets` - [matches brackets](highlighters/brackets.md) and parenthesis.
* `pattern` - matches [user-defined patterns](highlighters/pattern.md).
* `cursor` - matches [the cursor](highlighters/cursor.md) position.
* `root` - highlights the whole command line [if the current user is root](highlighters/root.md).
* `line` - applied to [the whole command line](highlighters/line.md).


How to activate highlighters
----------------------------

To activate an highlighter, add it to the `ZSH_HIGHLIGHT_HIGHLIGHTERS` array in
`~/.zshrc`, for example:

    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

By default, `$ZSH_HIGHLIGHT_HIGHLIGHTERS` is unset and only the `main`
highlighter is active.


How to tweak highlighters
-------------------------

Highlighters look up styles from the `ZSH_HIGHLIGHT_STYLES` associative array.
Navigate into the [individual highlighters' documentation](highlighters/) to
see what styles (keys) each highlighter defines; the syntax for values is the
same as the syntax of "types of highlighting" of the zsh builtin
`$zle_highlight` array, which is documented in [the `zshzle(1)` manual
page][zshzle-Character-Highlighting].

[zshzle-Character-Highlighting]: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting

Some highlighters support additional configuration parameters; see each
highlighter's documentation for details and examples.


How to implement a new highlighter
----------------------------------

To create your own `myhighlighter` highlighter:

* Create your script at
    `highlighters/${myhighlighter}/${myhighlighter}-highlighter.zsh`.

* Implement the `_zsh_highlight_myhighlighter_highlighter_predicate` function.
  This function must return 0 when the highlighter needs to be called and
  non-zero otherwise, for example:

        _zsh_highlight_myhighlighter_highlighter_predicate() {
          # Call this highlighter in SVN working copies
          [[ -d .svn ]]
        }

* Implement the `_zsh_highlight_myhighlighter_highlighter` function.
  This function does the actual syntax highlighting, by modifying
  `region_highlight`, for example:

        _zsh_highlight_myhighlighter_highlighter() {
          # Colorize the whole buffer with blue background
          region_highlight+=(0 $#BUFFER bg=blue)
        }

* Activate your highlighter in `~/.zshrc`:

        ZSH_HIGHLIGHT_HIGHLIGHTERS+=(myhighlighter)
