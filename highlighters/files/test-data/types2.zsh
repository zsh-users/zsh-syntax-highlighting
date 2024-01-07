#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2020 zsh-syntax-highlighting contributors
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

BUFFER=$': file.fi file.di file.ln file.pi file.or file.ex file.su file.sg file.ow file.tw file.di/file.fi'

ZSH_HIGHLIGHT_FILE_TYPES=('cd' 'fg=#EA6630' 'su' 'fg=#878AE0,bold' 'ex' 'fg=#BDD040' 'bd' 'fg=#AC3000' 'ln' 'fg=#B58900' 'tw' 'fg=#268BD2,bold,underline' 'or' 'fg=#FC5246,bold' 'fi' 'fg=#93A1A1' 'lp' 'fg=#657B83' 'sg' 'fg=#878AE0' 'di' 'fg=#268BD2,bold' 'ow' 'fg=#DC322F,underline' 'pi' 'fg=#D33682' 'so' 'fg=#D33682,bold')

touch file.fi
mkdir file.di
ln -s file.fi file.ln
mkfifo file.pi
ln -s bad file.or
touch file.ex; chmod 755 file.ex
touch file.su; chmod u+s file.su
touch file.sg; chmod g+s file.sg
touch file.ow; chmod o+w file.ow
mkdir file.tw; chmod o+wt file.tw
touch file.di/file.fi

expected_region_highlight=(
    '3 9 fg=#93A1A1'
    '11 17 fg=#268BD2,bold'
    '19 25 fg=#B58900'
    '27 33 fg=#D33682'
    '35 41 fg=#FC5246,bold'
    '43 49 fg=#BDD040'
    '51 57 fg=#878AE0,bold'
    '59 65 fg=#878AE0'
    '67 73 fg=#DC322F,underline'
    '75 81 fg=#268BD2,bold,underline'
    '83 90 fg=#657B83'
    '91 97 fg=#93A1A1'
)
