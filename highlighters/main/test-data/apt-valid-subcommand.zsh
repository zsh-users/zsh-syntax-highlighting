#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2026 zsh-syntax-highlighting contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
# -------------------------------------------------------------------------------------------------

_zsh_highlight_main__apt_subcommands=(
  list 1
  install 1
  update 1
  full-upgrade 1
  download 1
  policy 1
)
_zsh_highlight_main__apt_subcommands_loaded=1

BUFFER='apt list; apt install; apt update; apt full-upgrade; apt download; apt policy'

expected_region_highlight=(
  '1 3 command' # apt
  '5 8 command' # list
  '9 9 commandseparator' # ;
  '11 13 command' # apt
  '15 21 command' # install
  '22 22 commandseparator' # ;
  '24 26 command' # apt
  '28 33 command' # update
  '34 34 commandseparator' # ;
  '36 38 command' # apt
  '40 51 command' # full-upgrade
  '52 52 commandseparator' # ;
  '54 56 command' # apt
  '58 65 command' # download
  '66 66 commandseparator' # ;
  '68 70 command' # apt
  '72 77 command' # policy
)
