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
cd "$(dirname "$(realpath "$0")")"

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
            DEST_NOPREFIX="$(echo "$DEST" | sed 's#smb://##g')"
            DEST_SERVER="$(echo "$DEST_NOPREFIX" | cut -d/ -f1)"
            DEST_SHARE="$(echo "$DEST_NOPREFIX" | cut -d/ -f2)"
            DEST_PATH="$(echo "$DEST_NOPREFIX" | sed "s#$DEST_SERVER/$DEST_SHARE/##g")"
            read -p "SMB User: " DEST_USER
            read -p "SMB Pass: " -s DEST_PASS
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
    DEST=""
done

# Save settings
cat << EOF > "$CONFIG_DIR/settings.sh"
DEST="$DEST"
EOF
