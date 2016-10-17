up to d37c55c788cd




# Changes in version 0.5.0


## Added highlighting of:

- 'pkexec' (a precommand).
  (#248, 4f3910cbbaa5)

- Aliases that cannot be defined normally nor invoked normally (highlighted as an error).
  (#263 (in part), 28932316cca6)

- The `isearch` and `suffix` [`$zle_highlight` settings][zshzle-Character-Highlighting].
  (79e4d3d12405; requires zsh 5.3 for `$ISEARCHMATCH_ACTIVE` / `$SUFFIX_ACTIVE` support)

[zshzle-Character-Highlighting]: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting


## Fixed highlighting of:

- Command separator tokens in syntactically-invalid positions.
  (09c4114eb980)

- Redirections with a file descriptor number at command word.
  (#238 (in part), 73ee7c1f6c4a)

- The `select` prompt, `$PS3`.
  (#268, 451665cb2a8b)

- Values of variables in `vared`.
  (e500ca246286)

- `!` as an argument (neither a history expansion nor a reserved word).
  (4c23a2fd1b90)

- "division by zero" error under the `brackets` highlighter when `$ZSH_HIGHLIGHT_STYLES` is empty.
  (f73f3d53d3a6)

- Process substitutions, `<(pwd)` and `>(wc -l)`.
  (#302, 6889ff6bd2ad, bfabffbf975c, fc9c892a3f15)


## API changes (for highlighter authors):

- New interface `_zsh_highlight_add_highlight`.
  (341a3ae1f015, c346f6eb6fb6)

- tests: Specify the style key, not its value, in test expectations.
  (a830613467af, fd061b5730bf, eaa4335c3441, among others)

- Module author documentation improvements.
  (#306 (in part), 217669270418, 0ff354b44b6e, and others)


## Developer-visible changes:

- Add `make quiet-test`.
  (9b64ad750f35)

- test harness: Better quote replaceables in error messages.
  (30d8f92df225)

- test harness: Fix exit code for XPASS.
  (bb8d325c0cbd)

- tests: Add the "NONE" expectation.
  (4da9889d1545, 13018f3dd735, d37c55c788cd)

- Create [HACKING.md](HACKING.md).

- tests: Emit a description for PASS test points.
  (6aa57d60aa64, f0bae44b76dd)

- tests: consider a test that writes to stderr to have failed.
  (#291, 1082067f9315)


## Other changes:

- Under zsh≤5.2, widgets whose names start with a `_` are no longer excluded
  from highlighting.
  (ed33d2cb1388; reverts part of 186d80054a40 which was for #65)

- Under zsh≤5.2, widgets implemented by a function named after the widget are
  no longer excluded from highlighting.
  (487b122c480d; reverts part of 776453cb5b69)

- Under zsh≤5.2, shell-unsafe widget names can now be wrapped.
  (#278, 6a634fac9fb9, et seq)

- Correct some test expectations.
  (78290e043bc5)

- `zsh-syntax-highlighting.plugin.zsh`: Convert from symlink to plain file
  for msys2 compatibility.
  (#292, d4f8edc9f3ad)

- Document installation under some plugin managers.
  (e635f766bef9, 9cab566f539b)

- Don't leak the `PATH_DIRS` option.
  (7b82b88a7166)


# Changes in version 0.4.1

## Fixes:

- Arguments to widgets were not properly dash-escaped.  Only matters for widgets
  that take arguments (i.e., that are invoked as `zle ${widget} -- ${args}`).
  (282c7134e8ac, reverts c808d2187a73)


# Changes in version 0.4.0


## Added highlighting of:

- incomplete sudo commands
  (a3047a912100, 2f05620b19ae)

        sudo;
        sudo -u;

- command words following reserved words
  (#207, #222, b397b12ac139 et seq, 6fbd2aa9579b et seq, 8b4adbd991b0)

        if ls; then ls; else ls; fi
        repeat 10 do ls; done

    (The `ls` are now highlighted as a command.)

- comments (when `INTERACTIVE_COMMENTS` is set)
  (#163, #167, 693de99a9030)

        echo Hello # comment

- closing brackets of arithmetic expansion, subshells, and blocks
  (#226, a59f442d2d34, et seq)

        (( foo ))
        ( foo )
        { foo }

- command names enabled by the `PATH_DIRS` option
  (#228, 96ee5116b182)

        # When ~/bin/foo/bar exists, is executable, ~/bin is in $PATH,
        # and 'setopt PATH_DIRS' is in effect
        foo/bar

- parameter expansions with braces inside double quotes
  (#186, 6e3720f39d84)

        echo "${foo}"

- parameter expansions in command word
  (#101, 4fcfb15913a2)

        x=/bin/ls
        $x -l

- the command separators '|&', '&!', '&|'

        view file.pdf &!  ls


## Fixed highlighting of:

- precommand modifiers at non-command-word position
  (#209, 2c9f8c8c95fa)

        ls command foo

- sudo commands with infix redirections
  (#221, be006aded590, 86e924970911)

        sudo -u >/tmp/foo.out user ls

- subshells; anonymous functions
  (#166, #194, 0d1bfbcbfa67, 9e178f9f3948)

        (true)
        () { true }

- parameter assignment statements with no command
  (#205, 01d7eeb3c713)

        A=1;

    (The semicolon used to be highlighted as a mistake)

- cursor highlighter: Remove the cursor highlighting when accepting a line.
  (#109, 4f0c293fdef0)


## Removed features:

- Removed highlighting of approximate paths (`path_approx`).
  (#187, 98aee7f8b9a3)


## Other changes:

- main highlighter refactored to use states rather than booleans.
  (2080a441ac49, et seq)

- Fix initialization when sourcing `zsh-syntax-highlighting.zsh` via a symlink
  (083c47b00707)

- docs: Add screenshot.
  (57624bb9f64b)

- widgets wrapping: Don't add '--' when invoking widgets.
  (c808d2187a73) [_reverted in 0.4.1_]

- Refresh highlighting upon `accept-*` widgets (`accept-line` et al).
  (59fbdda64c21)

- Stop leaking match/mbegin/mend to global scope (thanks to upstream
  `WARN_CREATE_GLOBAL` improvements).
  (d3deffbf46a4)

- 'make install': Permit setting `$(SHARE_DIR)` from the environment.
  (e1078a8b4cf1)

- driver: Tolerate KSH_ARRAYS being set in the calling context.
  (#162, 8f19af6b319d)

- 'make install': Install documentation fully and properly.
  (#219, b1619c001390, et seq)

- docs: Improve 'main' highlighter's documentation.
  (00de155063f5, 7d4252f5f596)

- docs: Moved to a new docs/ tree; assorted minor updates
  (c575f8f37567, 5b34c23cfad5, et seq)

- docs: Split README.md into INSTALL.md
  (0b3183f6cb9a)

- driver: Report `$ZSH_HIGHLIGHT_REVISION` when running from git
  (84734ba95026)


## Developer-visible changes:

- Test harness converted to [TAP](http://testanything.org/tap-specification.html) format
  (d99aa58aaaef, et seq)

- Run each test in a separate subprocess, isolating them from each other
  (d99aa58aaaef, et seq)

- Fix test failure with nonexisting $HOME
  (#216, b2ac98b98150)

- Test output is now colorized.
  (4d3da30f8b72, 6fe07c096109)

- Document `make install`
  (a18a7427fd2c)

- tests: Allow specifying the zsh binary to use.
  (557bb7e0c6a0)

- tests: Add 'make perf' target
  (4513eaea71d7)

- tests: Run each test in a sandbox directory
  (c01533920245)


# Changes in version 0.3.0


## Added highlighting of:

- suffix aliases (requires zsh 5.1.1 or newer):

        alias -s png=display
        foo.png

- prefix redirections:

        <foo.txt cat

- redirection operators:

        echo > foo.txt

- arithmetic evaluations:

        (( 42 ))

- $'' strings, including \x/\octal/\u/\U escapes

        : $'foo\u0040bar'

- multiline strings:

        % echo "line 1
        line 2"

- string literals that haven't been finished:

        % echo "Hello, world

- command words that involve tilde expansion:

        % ~/bin/foo


## Fixed highlighting of:

- quoted command words:

        % \ls

- backslash escapes in "" strings:

        % echo "\x41"

- noglob after command separator:

        % :; noglob echo *

- glob after command separator, when the first command starts with 'noglob':

        % noglob true; echo *

- the region (vi visual mode / set-mark-command) (issue #165)

- redirection and command separators that would be highlighted as `path_approx`

        % echo foo;‸
        % echo <‸

    (where `‸` represents the cursor location)

- escaped globbing (outside quotes)

        % echo \*


## Other changes:

- implemented compatibility with zsh's paste highlighting (issue #175)

- `$?` propagated correctly to wrapped widgets

- don't leak $REPLY into global scope


## Developer-visible changes:

- added makefile with `install` and `test` targets

- set `warn_create_global` internally

- document release process




# Version 0.2.1

(Start of changelog.)

