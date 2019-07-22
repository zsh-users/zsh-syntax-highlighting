zsh-syntax-highlighting / highlighters
======================================

Syntax highlighting is done by pluggable highlighters:

* `main` - the base highlighter, and the only one [active by default][1].
* `brackets` - [matches brackets][2] and parenthesis.
* `pattern` - matches [user-defined patterns][3].
* `cursor` - matches [the cursor position][4].
* `root` - highlights the whole command line [if the current user is root][5].
* `line` - applied to [the whole command line][6].

[1]: highlighters/main.md
[2]: highlighters/brackets.md
[3]: highlighters/pattern.md
[4]: highlighters/cursor.md
[5]: highlighters/root.md
[6]: highlighters/line.md


How to activate highlighters
----------------------------

To activate an highlighter, add it to the `ZSH_HIGHLIGHT_HIGHLIGHTERS` array in
`~/.zshrc`, for example:

```zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
```

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

Styles may be set directly or by themes. If no theme is specified in
`ZSH_HIGHLIGHT_THEME` the `default` theme will be loaded. Additional themes
may be layered on top (overriding previous theme's settings) by calling
`_zsh_highlight_load_theme`.  `_zsh_highlight_load_theme` takes either an
absolute path to a theme file to load or a theme name. For a theme name the
base theme from the themes directory is loaded and then the extensions of the
theme that any active highlighter has are loaded. Names must not contain a `/`.

The `default` theme is a colorful theme that preserves the defaults the
highlighters originally had. The `error-only` theme is also available for
highlighting only syntax errors.

Some highlighters support additional configuration parameters; see each
highlighter's documentation for details and examples.


How to implement a new highlighter
----------------------------------

To create your own `acme` highlighter:

* Create your script at
    `highlighters/acme/acme-highlighter.zsh`.

* Implement the `_zsh_highlight_highlighter_acme_predicate` function.
  This function must return 0 when the highlighter needs to be called and
  non-zero otherwise, for example:

    ```zsh
    _zsh_highlight_highlighter_acme_predicate() {
      # Call this highlighter in SVN working copies
      [[ -d .svn ]]
    }
    ```

* Implement the `_zsh_highlight_highlighter_acme_paint` function.
  This function does the actual syntax highlighting, by calling
  `_zsh_highlight_add_highlight` with the start and end of the region to
  be highlighted and the `ZSH_HIGHLIGHT_STYLES` key to use. The key should
  be prefixed with your highlighter name and a colon

    _zsh_highlight_highlighter_acme_paint() {
      # Colorize the whole buffer with the 'aurora' style
      _zsh_highlight_add_highlight 0 $#BUFFER acme:aurora
    }
    ```

  If you need to test which options the user has set, test `zsyh_user_options`
  with a sensible default if the option is not present in supported zsh
  versions. For example:

    ```zsh
    [[ ${zsyh_user_options[ignoreclosebraces]:-off} == on ]]
    ```

  The option name must be all lowercase with no underscores and not an alias.

* Name your own functions and global variables `_zsh_highlight_acme_*`.

    - In zsh-syntax-highlighting 0.4.0 and earlier, the entrypoints 
        `_zsh_highlight_highlighter_acme_predicate` and
        `_zsh_highlight_highlighter_acme_paint`
        were named
        `_zsh_highlight_acme_highlighter_predicate` and
        `_zsh_highlight_highlighter_acme_paint` respectively.

        These names are still supported for backwards compatibility;
        however, support for them will be removed in a a future major or minor release (v0.x.0 or v1.0.0).

* Optionally extended the built-in themes in
    `highlighters/${myhighlighter}/themes/${themename}`.

  Define the theme's style for that key with `ZSH_HIGHLIGHT_STYLES[key]=value`,
  being sure to prefix the key with your highlighter name and a colon. For
  example:

        ZSH_HIGHLIGHT_STYLES[myhighlighter:aurora]=fg=green

* Activate your highlighter in `~/.zshrc`:

    ```zsh
    ZSH_HIGHLIGHT_HIGHLIGHTERS+=(acme)
    ```

* [Write tests](../tests/README.md).
