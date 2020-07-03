zsh-syntax-highlighting / highlighters / regexp
------------------------------------------------

This is the `regexp` highlighter, that highlights user-defined regular
expressions. It's similar to the `pattern` highlighter, but allows more complex
patterns.

### How to tweak it

To use this highlighter, associate regular expressions with styles in the
`ZSH_HIGHLIGHT_REGEXP` associative array, for example in `~/.zshrc`:

```zsh
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('^rm .*' fg="red",bold)
```

This will highlight the whole line starting with `rm` (for all operating systems, 
in contrast to the below example).

Some regex patterns are [subject to the host platform][MAN_ZSH_REGEX], especially
the kernel. To highlight `sudo` only as a complete word, i.e., `sudo cmd`, but 
not `sudoedit`:

* GNU-Linux

  ```zsh
  typeset -A ZSH_HIGHLIGHT_REGEXP
  ZSH_HIGHLIGHT_REGEXP+=('\<sudo\>' fg=123,bold)
  ```

* BSD-based platforms

  ```zsh
  typeset -A ZSH_HIGHLIGHT_REGEXP
  ZSH_HIGHLIGHT_REGEXP+=('[[:<:]]sudo[[:>:]]' fg=123,bold)
  ```

Both would give the same results, but do not work on each other's system.

The syntax for values is the same as the syntax of "types of highlighting" of
the zsh builtin `$zle_highlight` array, which is documented in [the `zshzle(1)`
manual page][zshzle-Character-Highlighting].

See also: [regular expressions tutorial][perlretut], zsh regexp operator `=~`
in [the `zshmisc(1)` manual page][zshmisc-Conditional-Expressions]

[MAN_ZSH_REGEX]: http://zsh.sourceforge.net/Doc/Release/Zsh-Modules.html#The-zsh_002fregex-Module
[zshzle-Character-Highlighting]: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
[perlretut]: http://perldoc.perl.org/perlretut.html
[zshmisc-Conditional-Expressions]: http://zsh.sourceforge.net/Doc/Release/Conditional-Expressions.html#Conditional-Expressions
