GAME="Hytale"
VARIANT=""

# $1 = game install path
do_backup(){
    # Setup for backup
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
    VARIANT="_Flatpak"
    do_backup "$HOME/.var/app/com.hypixel.HytaleLauncher/data/Hytale/UserData/Saves/"
fi
 
