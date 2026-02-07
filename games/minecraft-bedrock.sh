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
# script:      minecraft-bedrock.sh
# description: Backup Minecraft Bedrock edition game saves. Supports both the UWP and GDK versions
#              of the windows game. Also supports the unofficial MCPELuancher on Linux
####################################################################################################

GAME="MCBedrock"
VARIANT=""

# $1 = game install path
do_backup(){
    echo "Found ${GAME}${VARIANT}"
    cp -r "$1" "${GAME}${VARIANT}"
}


# Windows UWP version install
if [ $IS_WIN -eq 1 ] && [ -d "$LOCALAPPDATA/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/LocalState/games/com.mojang/minecraftWorlds" ]; then
    VARIANT="UWP"
    do_backup "$LOCALAPPDATA/Packages/Microsoft.MinecraftUWP_8wekyb3d8bbwe/LocalState/games/com.mojang/minecraftWorlds"
fi

# Windows GDK version install
if [ $IS_WIN -eq 1 ] && [ -d "$APPDATA/Minecraft Bedrock/users/" ]; then
    VARIANT="GDK"
    user_dir="$(find "$APPDATA/Minecraft Bedrock/users/" -mindepth 1 -maxdepth 1 -type d | grep -v -i 'shared' | head -n 1)"
    if [ -n "$user_dir" ] && [ -d "$user_dir" ]; then
        do_backup "$user_dir/games/com.mojang/minecraftWorlds"
    fi
fi

# Linux MCPELauncher Flatpak
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.var/app/io.mrarm.mcpelauncher/data/mcpelauncher/games/com.mojang/minecraftWorlds" ]; then
    VARIANT="3rdPartyFP"
    do_backup "$HOME/.var/app/io.mrarm.mcpelauncher/data/mcpelauncher/games/com.mojang/minecraftWorlds"
fi
