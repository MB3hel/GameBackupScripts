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
# script:      sfc-custom-distro.sh
# description: Backup Starfleet Command game saves from my custom distribution / installation
#              structure. This structure is non-standard. Thus, this script will be of little if any
#              use to anyone except me :)
####################################################################################################

GAME="SFC"
VARIANT=""

# $1 = game install path
do_backup(){
    # Setup for backup
    echo "Found ${GAME}${VARIANT}"
    mkdir "${GAME}${VARIANT}"
    oldcwd="$(pwd)"
    
    # Custom SFC distro has a saves manager script that already handles backing up all relevant
    # data. And it's kind of a mess to replicate that here. So just call it instead
    # as it was already designed for / tested in windows busybox so compatability isn't a concern
    cd "$1/SAVES_MANAGER"
    rm -f SFC_SAVES_BackupFromScript.tar.gz
    printf "1\nBackupFromScript\n3\n3\n" | ./SavesManager.sh > /dev/null 2>&1
    cp SFC_SAVES_BackupFromScript.tar.gz "$oldcwd/${GAME}${VARIANT}"
    
    # Restore cwd
    cd "$oldcwd"
}


# Windows install
if [ $IS_WIN -eq 1 ] && [ -d "C:/StarfleetCommandGames" ]; then
    VARIANT=""
    do_backup "C:/StarfleetCommandGames"
fi

# Linux install within bottles installed as a flatpak
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/" ]; then
    find "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/" -maxdepth 1 -mindepth 1 -type d -print0 | while IFS= read -r -d '' bottle_dir; do
        bottle_name="$(basename "$bottle_dir")"
        if [ -d "$bottle_dir/drive_c/StarfleetCommandGames/" ]; then
            VARIANT="Bottle${bottle_name}FP"
            do_backup "$bottle_dir/drive_c/StarfleetCommandGames/"
        fi
    done
fi
