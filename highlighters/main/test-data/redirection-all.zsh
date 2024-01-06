#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2024 zsh-syntax-highlighting contributors
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

BUFFER=$': <foo 9<foo <>foo 9<>foo >foo 9>foo >|foo >\!foo >>foo >>|foo >>\!foo <<<foo <&9 >&9 <&- >&- <&p >&p >&foo &>foo >&|foo >&\!foo &>|foo &>\!foo >>&foo &>>foo >>&|foo >>&\!foo &>>|foo &>>\!foo'

expected_region_highlight=(
  '1 1 builtin' # :
  '3 3 redirection' # <
  '4 6 default' # foo
  '8 9 redirection' # 9<
  '10 12 default' # foo
  '14 15 redirection' # <>
  '16 18 default' # foo
  '20 22 redirection' # 9<>
  '23 25 default' # foo
  '27 27 redirection' # >
  '28 30 default' # foo
  '32 33 redirection' # 9>
  '34 36 default' # foo
  '38 39 redirection' # >|
  '40 42 default' # foo
  '44 45 redirection' # >\!
  '46 48 default' # foo
  '50 51 redirection' # >>
  '52 54 default' # foo
  '56 58 redirection' # >>|
  '59 61 default' # foo
  '63 65 redirection' # >>\!
  '66 68 default' # foo
  '70 72 redirection' # <<<
  '73 75 default' # foo
  '77 78 redirection' # <&
  '79 79 numeric-fd' # 9
  '81 82 redirection' # >&
  '83 83 numeric-fd' # 9
  '85 86 redirection' # <&
  '87 87 redirection' # -
  '89 90 redirection' # >&
  '91 91 redirection' # -
  '93 94 redirection' # <&
  '95 95 redirection' # p
  '97 98 redirection' # >&
  '99 99 redirection' # p
  '101 102 redirection' # >&
  '103 105 default' # foo
  '107 108 redirection' # &>
  '109 111 default' # foo
  '113 115 redirection' # >&|
  '116 118 default' # foo
  '120 122 redirection' # >&\!
  '123 125 default' # foo
  '127 129 redirection' # &>|
  '130 132 default' # foo
  '134 136 redirection' # &>\!
  '137 139 default' # foo
  '141 143 redirection' # >>&
  '144 146 default' # foo
  '148 150 redirection' # &>>
  '151 153 default' # foo
  '155 158 redirection' # >>&|
  '159 161 default' # foo
  '163 166 redirection' # >>&\!
  '167 169 default' # foo
  '171 174 redirection' # &>>|
  '175 177 default' # foo
  '179 182 redirection' # &>>\!
  '183 185 default' # foo
)
