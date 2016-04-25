Hacking on zsh-syntax-highlighting itself
=========================================

This document includes information for people working on z-sy-h itself: on the
core driver (`zsh-syntax-highlighting.zsh`), on the highlighters in the
distribution, and on the test suite.  It does not target third-party
highlighter authors (although they may find it an interesting read).

The `main` highlighter
----------------------

The following function `pz` is useful when working on the `main` highlighting:

    pq() {
      (( $#argv )) || return 0
      print -r -l -- ${(qqqq)argv}
    }
    pz() {
      local arg
      for arg; do
        pq ${(z)arg}
      done
    }

It prints, for each argument, its token breakdown, similar to how the main
loop of the `main` highlighter sees it.

Testing the `brackets` highlighter
----------------------------------

Since the test harness empties `ZSH_HIGHLIGHT_STYLES` and the `brackets`
highlighter interrogates `ZSH_HIGHLIGHT_STYLES` to determine how to highlight,
tests must set the `bracket-level-#` keys themselves.  For example:

    ZSH_HIGHLIGHT_STYLES[bracket-level-1]=
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]=

    BUFFER='echo ({x})'

    expected_region_highlight=(
      "6  6  bracket-level-1" # (
      "7  7  bracket-level-2" # {
      "9  9  bracket-level-2" # }
      "10 10 bracket-level-1" # )
    )

IRC channel
-----------

We're on #zsh-syntax-highlighting on freenode.

