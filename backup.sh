#!/usr/bin/env sh
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
# script:      backup.sh
# description: Backup game saves to a local or smb share location. Game detection is handled via
#              additoional scripts for each game located in the games/ subdirectory. smb share
#              backup is only supported on Linux systems with the smbclient command.
#              Running on windows requires either msys2 or busybox. While compatability with busybox
#              is intended, it is not tested often and may have issues.
####################################################################################################


####################################################################################################
# Setup
####################################################################################################
# Only allow this script to run interactive
if ! [ -t 0 ]; then
    echo "Must run interactive" >&2
    exit 1
fi

# Run in same directory as this script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"
####################################################################################################


####################################################################################################
# Argument parsing
####################################################################################################

usage(){
    echo "backup.sh [--devtest]"
    echo "    --devtest: DO NOT USE THIS. Use a test backup instead of a real one"
    exit 1
}

[ $# -gt 1 ] && usage
if [ "$1" = "" ]; then
    DEVTEST=0
elif [ "$1" = "--devtest" ]; then
    DEVTEST=1
else
    usage
fi

####################################################################################################


####################################################################################################
# OS Detection
####################################################################################################
IS_WIN="0"
IS_MAC="0"
IS_NIX="0"
CONFIG_DIR=""

# Detect OS and set variables
case "$(uname -o)" in
    # MSYS2 -> Msys
    # Busybox -> MS/Windows
    Msys)
        IS_WIN="1"
        CONFIG_DIR="$APPDATA/GameBackupScripts/"
        ;;
    MS/Windows)
        IS_WIN="1"
        CONFIG_DIR="$APPDATA/GameBackupScripts/"
        echo "WARNING: busybox on windows can't handle long paths."
        echo "         This may result in failures backing up some game saves"
        echo "         Using MSYS2 instead is highly recommended."
        ;;
    Darwin)
        IS_MAC="1"
        CONFIG_DIR="" # TODO
        ;;
    GNU/Linux|FreeBSD)
        IS_NIX="1"
        CONFIG_DIR="$HOME/.config/GameBackupScripts/"
        ;;
    *)
        echo "Unknown OS" >&2
        exit 1
        ;;
esac

# macos support not implemented b/c I don't use anymore
if [ $IS_MAC -eq 1 ]; then
    echo "MacOS is not currently supported" >&2
    exit 1
fi

# Load other util scripts
. "$SCRIPT_DIR/utils/smb.sh"
####################################################################################################



####################################################################################################
# Destination selection
####################################################################################################
# Load saved settings (if any)
DEST=""                 # Destination path (either local or smb)
mkdir -p "$CONFIG_DIR"
[ -f "$CONFIG_DIR/settings.sh" ] && . "$CONFIG_DIR/settings.sh"


# Prompt for settings
while true; do
    DEST_OLD="$DEST"
    read -p "Destination ($DEST): " DEST
    if [ "$DEST" = "" ]; then
        DEST="$DEST_OLD"
    fi
    case "$DEST" in
        "")
            ;;
        "smb://"*|"\\"*|"//"*)
            CP="smb-cp"
            smb-auth "$DEST"
            echo ""
            ;;
        *)
            CP="cp"
            ;;
    esac

    # Make sure we can write a file into the destination
    TEST_FILE="$(mktemp)"
    echo "write test" > "$TEST_FILE"
    if "$CP" "$TEST_FILE" "$DEST/test_$(hostname)_$USER" > /dev/null 2>&1; then
        break
    else
        echo "Destination is not writable, does not exist, or credentials are incorrect."
    fi
done


# Save settings
cat << EOF > "$CONFIG_DIR/settings.sh"
DEST="$DEST"
SMB_USER="$SMB_USER"
EOF
####################################################################################################



####################################################################################################
# Create backup tar
####################################################################################################

# Setup temp working directory where we will copy saves to create tar
DATESTRING="$(date '+%Y%m%d_%I%M%p')"
BACKUP_NAME="$(hostname)_${USER}_${DATESTRING}"
WORKDIR="$SCRIPT_DIR/work"
mkdir -p "$WORKDIR"
trap "rm -rf \"$WORKDIR\"" EXIT
mkdir "$WORKDIR/$BACKUP_NAME"

# Make backup
oldcwd="$(pwd)"
cd "$WORKDIR/$BACKUP_NAME"
if [ $DEVTEST -eq 1 ]; then
    # Development test backup (small and quick to create and copy)
    # Used to test file transfer and script procedure. Not backup of specific games
    echo "Hello, backup!" > test_backup.txt
else
    # Not a devtest. Run a real backup of each game
    for game_script in "$SCRIPT_DIR/games/"*.sh; do
        . "$game_script"
    done
fi
cd "$oldcwd"

# Choose compression method (busybox for windows has xz, but it can only decompress)
COMPRESS=".gz"
oldcwd="$(pwd)"
cd "$WORKDIR"
echo "test" > test.txt
rm -f test.txt.xz
if xz -z -T0 test.txt >/dev/null 2>&1; then
    COMPRESS=".xz"
fi
cd "$oldcwd"

# Make tar & compress
oldcwd="$(pwd)"
cd "$WORKDIR"
echo "Making tar"
tar -cf "$BACKUP_NAME.tar" "$BACKUP_NAME/"
echo "Compressing"
case "$COMPRESS" in
    ".xz")
        xz -z -T0 "$BACKUP_NAME.tar"
        ;;
    ".gz")
        gzip "$BACKUP_NAME.tar"
        ;;
    *)
        echo "Unknown compression method attempted. Skipping"
        COMPRESS=""
        ;;
esac
cd "$oldcwd"

# Move backup to destination
if ! "$CP" "$WORKDIR/$BACKUP_NAME.tar$COMPRESS" "$DEST/$BACKUP_NAME.tar$COMPRESS" > /dev/null 2>&1; then
    echo "Failed to save backup"
    exit 1
fi

echo "Backup complete!"

####################################################################################################

