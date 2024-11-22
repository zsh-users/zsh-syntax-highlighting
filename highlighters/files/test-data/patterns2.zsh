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

BUFFER=$': file.tar file.tgz Makefile #file.bak# file.PgP file.flv'

ZSH_HIGHLIGHT_FILE_PATTERNS=('Makefile' 'fg=#F0BE45,bold' 'SConstruct' 'fg=#F0BE45,bold' 'CMakeLists.txt' 'fg=#F0BE45,bold' 'BUILD' 'fg=#F0BE45,bold' 'README*' 'fg=#F0BE45,bold' '(#i)*.png' 'fg=#B50769' '(#i)*.jpeg' 'fg=#B50769' '(#i)*.jpg' 'fg=#B50769' '(#i)*.gif' 'fg=#B50769' '(#i)*.bmp' 'fg=#B50769' '(#i)*.tiff' 'fg=#B50769' '(#i)*.tif' 'fg=#B50769' '(#i)*.ppm' 'fg=#B50769' '(#i)*.pgm' 'fg=#B50769' '(#i)*.pbm' 'fg=#B50769' '(#i)*.pnm' 'fg=#B50769' '(#i)*.webp' 'fg=#B50769' '(#i)*.heic' 'fg=#B50769' '(#i)*.raw' 'fg=#B50769' '(#i)*.arw' 'fg=#B50769' '(#i)*.svg' 'fg=#B50769' '(#i)*.stl' 'fg=#B50769' '(#i)*.eps' 'fg=#B50769' '(#i)*.dvi' 'fg=#B50769' '(#i)*.ps' 'fg=#B50769' '(#i)*.cbr' 'fg=#B50769' '(#i)*.jpf' 'fg=#B50769' '(#i)*.cbz' 'fg=#B50769' '(#i)*.xpm' 'fg=#B50769' '(#i)*.ico' 'fg=#B50769' '(#i)*.cr2' 'fg=#B50769' '(#i)*.orf' 'fg=#B50769' '(#i)*.nef' 'fg=#B50769' '(#i)*.avi' 'fg=#D33682' '(#i)*.flv' 'fg=#D33682' '(#i)*.m2v' 'fg=#D33682' '(#i)*.m4v' 'fg=#D33682' '(#i)*.mkv' 'fg=#D33682' '(#i)*.mov' 'fg=#D33682' '(#i)*.mp4' 'fg=#D33682' '(#i)*.mpeg' 'fg=#D33682' '(#i)*.mpg' 'fg=#D33682' '(#i)*.ogm' 'fg=#D33682' '(#i)*.ogv' 'fg=#D33682' '(#i)*.vob' 'fg=#D33682' '(#i)*.wmv' 'fg=#D33682' '(#i)*.webm' 'fg=#D33682' '(#i)*.m2ts' 'fg=#D33682' '(#i)*.aac' 'fg=#F1559C' '(#i)*.m4a' 'fg=#F1559C' '(#i)*.mp3' 'fg=#F1559C' '(#i)*.ogg' 'fg=#F1559C' '(#i)*.wma' 'fg=#F1559C' '(#i)*.mka' 'fg=#F1559C' '(#i)*.opus' 'fg=#F1559C' '(#i)*.alac' 'fg=#F1559C' '(#i)*.ape' 'fg=#F1559C' '(#i)*.flac' 'fg=#F1559C' '(#i)*.wav' 'fg=#F1559C' '(#i)*.asc' 'fg=#6A7F00' '(#i)*.enc' 'fg=#6A7F00' '(#i)*.gpg' 'fg=#6A7F00' '(#i)*.pgp' 'fg=#6A7F00' '(#i)*.sig' 'fg=#6A7F00' '(#i)*.signature' 'fg=#6A7F00' '(#i)*.pfx' 'fg=#6A7F00' '(#i)*.p12' 'fg=#6A7F00' '(#i)*.djvu' 'fg=#878AE0' '(#i)*.doc' 'fg=#878AE0' '(#i)*.docx' 'fg=#878AE0' '(#i)*.dvi' 'fg=#878AE0' '(#i)*.eml' 'fg=#878AE0' '(#i)*.eps' 'fg=#878AE0' '(#i)*.fotd' 'fg=#878AE0' '(#i)*.odp' 'fg=#878AE0' '(#i)*.odt' 'fg=#878AE0' '(#i)*.pdf' 'fg=#878AE0' '(#i)*.ppt' 'fg=#878AE0' '(#i)*.pptx' 'fg=#878AE0' '(#i)*.rtf' 'fg=#878AE0' '(#i)*.xls' 'fg=#878AE0' '(#i)*.xlsx' 'fg=#878AE0' '(#i)*.zip' 'fg=#657B83,bold' '(#i)*.tar' 'fg=#657B83,bold' '(#i)*.Z' 'fg=#657B83,bold' '(#i)*.z' 'fg=#657B83,bold' '(#i)*.gz' 'fg=#657B83,bold' '(#i)*.bz2' 'fg=#657B83,bold' '(#i)*.a' 'fg=#657B83,bold' '(#i)*.ar' 'fg=#657B83,bold' '(#i)*.7z' 'fg=#657B83,bold' '(#i)*.iso' 'fg=#657B83,bold' '(#i)*.dmg' 'fg=#657B83,bold' '(#i)*.tc' 'fg=#657B83,bold' '(#i)*.rar' 'fg=#657B83,bold' '(#i)*.par' 'fg=#657B83,bold' '(#i)*.tgz' 'fg=#657B83,bold' '(#i)*.xz' 'fg=#657B83,bold' '(#i)*.txz' 'fg=#657B83,bold' '(#i)*.lzma' 'fg=#657B83,bold' '(#i)*.deb' 'fg=#657B83,bold' '(#i)*.rpm' 'fg=#657B83,bold' '(#i)*.zst' 'fg=#657B83,bold' '*~' 'fg=#586E75' '\#*\#' 'fg=#586E75' '(#i)*.tmp' 'fg=#586E75' '(#i)*.swp' 'fg=#586E75' '(#i)*.swo' 'fg=#586E75' '(#i)*.swn' 'fg=#586E75' '(#i)*.bak' 'fg=#586E75' '(#i)*.bk' 'fg=#586E75' '(#i)*.class' 'fg=#5158A9' '(#i)*.elc' 'fg=#5158A9' '(#i)*.o' 'fg=#5158A9' '(#i)*.pyc' 'fg=#5158A9')


touch file.tar file.tgz Makefile '#file.bak#' file.PgP file.flv

expected_region_highlight=(
    '3 10 fg=#657B83,bold'
    '12 19 fg=#657B83,bold'
    '21 28 fg=#F0BE45,bold'
    '30 39 fg=#586E75'
    '41 48 fg=#6A7F00'
    '50 57 fg=#D33682'
)
