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
# script:      prism-launcher.sh
# description: Backup Minecraft Java Edition saves from Prism Launcher instances
####################################################################################################

GAME="MCPrism"
VARIANT=""

# $1 = game install path
do_backup(){
    # Setup for backup
    echo "Found ${GAME}${VARIANT}"
    mkdir "${GAME}${VARIANT}"
    oldcwd="$(pwd)"
    cd ${GAME}${VARIANT}

    # Backup the saves folder of each instance
    find "$1" -maxdepth 1 -mindepth 1 -type d -print0  | while IFS= read -r -d '' instance_dir; do
        saves_dir=""
        [ -d "$instance_dir/minecraft/saves" ] && saves_dir="$instance_dir/minecraft/saves"
        [ -d "$instance_dir/.minecraft/saves" ] && saves_dir="$instance_dir/.minecraft/saves"
        if [ -n "$saves_dir" ]; then
            cp -r "$saves_dir" "$(basename "$instance_dir")_saves"
        fi
    done
    
    # Restore cwd
    cd "$oldcwd"
}


# Windows normal install
if [ $IS_WIN -eq 1 ] && [ -d "$APPDATA/PrismLauncher/instances/" ]; then
    VARIANT=""
    do_backup "$APPDATA/PrismLauncher/instances/"
fi

# Linux normal install
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.local/share/PrismLauncher/instances" ]; then
    VARIANT=""
    do_backup "$HOME/.local/share/PrismLauncher/instances"
fi
    
# Linux flatpak install
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/" ]; then
    VARIANT="FP"
    do_backup "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/"
fi
 
