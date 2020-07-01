zsh-syntax-highlighting / highlighters / regexp
------------------------------------------------

This is the `regexp` highlighter, that highlights user-defined regular
expressions. It's similar to the `pattern` highlighter, but allows more complex
patterns.

### How to tweak it

To use this highlighter, associate regular expressions with styles in the
`ZSH_HIGHLIGHT_REGEXP` associative array, for example in `~/.zshrc`:

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

This will highlight "sudo" only as a complete word, i.e., "sudo cmd", but not "sudoedit".

As in the example, some regex patterns are platform-dependent. Refer to the 
manual page of `re_format` before applying regular expressions to avoid confusing 
results. If portability matters, using only [POSIX ERE (extended regular 
expressions)][POSIX_ERE] could be an option.

The syntax for values is the same as the syntax of "types of highlighting" of
the zsh builtin `$zle_highlight` array, which is documented in [the `zshzle(1)`
manual page][zshzle-Character-Highlighting].

See also: [regular expressions tutorial][perlretut], zsh regexp operator `=~`
in [the `zshmisc(1)` manual page][zshmisc-Conditional-Expressions], GNU

[POSIX_ERE]: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04
[zshzle-Character-Highlighting]: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
[perlretut]: http://perldoc.perl.org/perlretut.html
[zshmisc-Conditional-Expressions]: http://zsh.sourceforge.net/Doc/Release/Conditional-Expressions.html#Conditional-Expressions
