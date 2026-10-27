zsh-syntax-highlighting / highlighters / pattern
------------------------------------------------

This is the `pattern` highlighter, that highlights user-defined patterns.

### How to tweak it

To use this highlighter, associate patterns with styles in the
`ZSH_HIGHLIGHT_PATTERNS` associative array, for example in `~/.zshrc`:

```zsh
# Declare the variable
typeset -A ZSH_HIGHLIGHT_PATTERNS

# To have commands starting with `rm -rf` in red:
ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=white,bold,bg=red')
```

For style configuration syntax, see [Highlighter-independent settings](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md#highlighter-independent-settings).

