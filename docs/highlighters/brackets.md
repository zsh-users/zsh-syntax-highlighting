zsh-syntax-highlighting / highlighters / brackets
-------------------------------------------------

This is the `brackets` highlighter, that highlights brackets and parentheses, and
matches them.

### How to tweak it

This highlighter defines the following styles:

* `bracket-error` - unmatched brackets
* `bracket-level-N` - brackets with nest level N
* `cursor-matchingbracket` - the matching bracket, if cursor is on a bracket

For style configuration syntax, see [Highlighter-independent settings](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md#highlighter-independent-settings).


```zsh
# To define styles for nested brackets up to level 4
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=yellow,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=magenta,bold'
```



