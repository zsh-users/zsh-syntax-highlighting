Hacking on zsh-syntax-highlighting itself
=========================================

This document includes information for people working on z-sy-h itself: on the
core driver (`zsh-syntax-highlighting.zsh`), on the highlighters in the
distribution, and on the test suite.  It does not target third-party
highlighter authors (although they may find it an interesting read).

The 'main' highlighter
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

IRC channel
-----------

We're on #zsh-syntax-highlighting on freenode.

