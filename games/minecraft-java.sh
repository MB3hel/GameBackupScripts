GAME="Minecraft_Java"
VARIANT=""

# $1 = game install path
do_backup(){
    echo "Found ${GAME}${VARIANT}"
    cp -r "$1" "${GAME}${VARIANT}"
}


# Windows normal install
if [ $IS_WIN -eq 1 ] && [ -d "$APPDATA/.minecraft/saves" ]; then
    VARIANT=""
    do_backup "$APPDATA/.minecraft/saves"
fi

# Linux normal install
if [ $IS_NIX -eq 1 ] && [ -d "$HOME/.minecraft/saves" ]; then
    VARIANT=""
    do_backup "$HOME/.minecraft/saves"
fi
