GAME="Retroarch"
VARIANT=""

# $1 = game install path
do_backup(){
    echo "Found ${GAME}${VARIANT}"
    cp -r "$1" "${GAME}${VARIANT}"
}


# Windows normal install
if [ $IS_WIN -eq 1 ] && [ -d "$APPDATA/Retroarch/saves" ]; then
    VARIANT=""
    do_backup "$APPDATA/Retroarch/saves"
fi

# Linux normal install
if [ $IS_WIN -eq 1 ] && [ -d "$HOME/.config/retroarch/saves" ]; then
    VARIANT=""
    do_backup "$HOME/.config/retroarch/saves"
fi
    
# Linux flatpak install
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.var/app/org.libretro.RetroArch/config/retroarch/saves/" ]; then
    VARIANT="_Flatpak"
    do_backup "$HOME/.var/app/org.libretro.RetroArch/config/retroarch/saves/"
fi
 
