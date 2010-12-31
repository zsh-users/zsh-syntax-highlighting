#!/usr/bin/env zsh
# Copyleft 2010 zsh-syntax-highlighting contributors
# http://github.com/nicoulaj/zsh-syntax-highlighting
# All wrongs reserved.
# vim: ft=zsh sw=2 ts=2 et

# Token types styles.
# See http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#SEC135
typeset -A ZSH_SYNTAX_HIGHLIGHTING_STYLES
ZSH_SYNTAX_HIGHLIGHTING_STYLES=(
  default                       'none'
  isearch                       'fg=magenta,standout'
  special                       'fg=magenta,standout'
  unknown-token                 'fg=red,bold'
  reserved-word                 'fg=yellow'
  alias                         'fg=green'
  builtin                       'fg=green'
  function                      'fg=green'
  command                       'fg=green'
  path                          'underline'
  globbing                      'fg=blue'
  single-hyphen-option          'none'
  double-hyphen-option          'none'
  back-quoted-argument          'none'
  single-quoted-argument        'fg=yellow'
  double-quoted-argument        'fg=yellow'
  dollar-double-quoted-argument 'fg=cyan'
  back-double-quoted-argument   'fg=cyan'
)

# Tokens that are always followed by a command.
ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS=(
  '|'
  '||'
  ';'
  '&'
  '&&'
  'sudo'
  'start'
  'time'
  'strace'
  'noglob'
  'command'
  'builtin'
)

# ZLE events that trigger an update of the highlighting.
ZSH_HIGHLIGHT_ZLE_UPDATE_EVENTS=(
  accept-and-hold
  accept-and-infer-next-history
  accept-line
  accept-line-and-down-history
  backward-delete-char
  backward-delete-word
  backward-kill-word
  beginning-of-buffer-or-history
  beginning-of-history
  beginning-of-history
  beginning-of-line-hist
  complete-word
  delete-char
  delete-char-or-list
  down-history
  down-line-or-history
  down-line-or-history
  down-line-or-search
  end-of-buffer-or-history
  end-of-history
  end-of-line-hist
  expand-or-complete
  expand-or-complete-prefix
  history-beginning-search-backward
  history-beginning-search-forward
  history-incremental-search-backward
  history-incremental-search-forward
  history-search-backward
  history-search-forward
  infer-next-history
  insert-last-word
  kill-word
  magic-space
  quoted-insert
  redo
  self-insert
  undo
  up-history
  up-line-or-history
  up-line-or-history
  up-line-or-search
  up-line-or-search
  vi-backward-kill-word
  vi-down-line-or-history
  vi-fetch-history
  vi-history-search-backward
  vi-history-search-forward
  vi-quoted-insert
  vi-repeat-search
  vi-rev-repeat-search
  vi-up-line-or-history
  yank
)

