####################################################################################################
#
# Copyright 2026 Marcus Behel
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted 
# provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of 
# conditions and the following disclaimer in the documentation and/or other materials provided with 
# the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to 
# endorse or promote products derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR 
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
####################################################################################################
# script:      hytale.sh
# description: Backup Hytale game saves
####################################################################################################

GAME="Hytale"
VARIANT=""

# $1 = game install path
do_backup(){
    echo "Found ${GAME}${VARIANT}"
    cp -r "$1" "${GAME}${VARIANT}"
}


# Windows normal install
if [ $IS_WIN -eq 1 ] && [ -d "$APPDATA/Hytale/UserData/Saves" ]; then
    VARIANT=""
    do_backup "$APPDATA/Hytale/UserData/Saves"
fi

# Linux normal install
if [ $IS_WIN -eq 1 ] && [ -d "$HOME/.local/share/Hytale/UserData/Saves" ]; then
    VARIANT=""
    do_backup "$HOME/.local/share/Hytale/UserData/Saves"
fi
    
# Linux flatpak install
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/UserData/Saves/" ]; then
    VARIANT="FP"
    do_backup "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/UserData/Saves/"
fi
 
