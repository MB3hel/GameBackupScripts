GAME="Minecraft_PrismLauncher"
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
    VARIANT="_Flatpak"
    do_backup "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/"
fi
 
