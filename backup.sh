#!/usr/bin/env sh
# TODO: HEader comment



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
    Msys|MS/Windows)
       IS_WIN="1"
       CONFIG_DIR="$APPDATA/GameBackupScripts/"
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
####################################################################################################



####################################################################################################
# Destination selection
####################################################################################################
# Load saved settings (if any)
DEST=""                 # 'Normal' path (local file or smb://SERVER/SHARE/path/to/destination)
DEST_SERVER=""          # SMB server name
DEST_SHARE=""           # SMB share name
DEST_PATH=""            # SMB path
DEST_USER=""            # SMB username
DEST_PASS=""            # SMB password
DEST_TYPE=""            # normal or smb
mkdir -p "$CONFIG_DIR"
[ -f "$CONFIG_DIR/settings.sh" ] && . "$CONFIG_DIR/settings.sh"

# smbclient wrapper to run commands
# Argument is passed to -c flag
smbc(){
    smbclient "//$DEST_SERVER/$DEST_SHARE" -U "$DEST_USER%$DEST_PASS" -c "$1"
}

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
        "smb://"*)
            DEST_TYPE="smb"
            DEST_NOPREFIX="$(echo "$DEST" | sed 's#smb://##g')"
            DEST_SERVER="$(echo "$DEST_NOPREFIX" | cut -d/ -f1)"
            DEST_SHARE="$(echo "$DEST_NOPREFIX" | cut -d/ -f2)"
            DEST_PATH="$(echo "$DEST_NOPREFIX" | sed "s#$DEST_SERVER/$DEST_SHARE/##g")"
            read -p "SMB User: " DEST_USER
            read -p "SMB Pass: " -s DEST_PASS
            echo ""
            if smbc "cd \"$DEST_PATH\"" >/dev/null 2>&1; then
                TEST_FILE="$(mktemp)"
                echo "write test" > "$TEST_FILE"
                if smbc "cd \"$DEST_PATH\"; put \"$TEST_FILE\" \"test_$(hostname)\"" >/dev/null 2>&1; then
                    break
                else
                    echo "Destination is not writable"
                fi
            else
                echo "Destination does not exist or credentials are incorrect"
            fi
            ;;
        *)
            # Make sure destination exists and is writable
            DEST_TYPE="normal"
            if [ -d "$DEST" ]; then
                if echo "write test" > "$DEST/test_$(hostname)" 2>&1; then
                    break
                else
                    echo "Destination is not writable"
                fi
            else
                echo "Destination does not exist"
            fi
            ;;
    esac
done

# Save settings
cat << EOF > "$CONFIG_DIR/settings.sh"
DEST="$DEST"
EOF
####################################################################################################



####################################################################################################
# Create backup tar
####################################################################################################

# Setup temp working directory where we will copy saves to create tar
DATESTRING="$(date '+%Y%m%d_%I%M%p')"
BACKUP_NAME="$(hostname)_$DATESTRING"
WORKDIR="$SCRIPT_DIR/work"
mkdir -p "$WORKDIR"
trap "rm -rf \"$WORKDIR\"" EXIT
mkdir "$WORKDIR/$BACKUP_NAME"

# Make backup
oldcwd="$(pwd)"
cd "$WORKDIR/$BACKUP_NAME"
for game_script in "$SCRIPT_DIR/games/"*.sh; do
    . "$game_script"
done
cd "$oldcwd"

# Choose compression method (busybox for windows has xz, but it can only decompress)
COMPRESS=".gz"
oldcwd="$(pwd)"
cd "$WORKDIR"
echo "test" > test.txt
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
case "$DEST_TYPE" in
    normal)
        if ! cp "$WORKDIR/$BACKUP_NAME.tar$COMPRESS" "$DEST/"; then
            echo "Failed to save backup"
            exit 1
        fi
        ;;
    smb)
        if ! smbc "cd \"$DEST_PATH\"; put \"$WORKDIR/$BACKUP_NAME.tar$COMPRESS\" \"$BACKUP_NAME.tar$COMPRESS\""; then
            echo "Failed to save backup"
            exit 1
        fi
        ;;
    *)
        echo "Uknonwn destination type. This is a script bug!!!"
        echo "No backup has been saved!!!"
        exit 1
        ;;
esac
echo "Backup complete!"
# TODO: Pause before exit

####################################################################################################

