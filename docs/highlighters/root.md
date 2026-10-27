zsh-syntax-highlighting / highlighters / root
---------------------------------------------

This is the `root` highlighter, that highlights the whole line if the current
user is root.

### How to tweak it

This highlighter defines the following styles:

* `root` - the style for the whole line if the current user is root.

For style configuration syntax, see [Highlighter-independent settings](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md#highlighter-independent-settings).


```zsh
ZSH_HIGHLIGHT_STYLES[root]='bg=red'
```



