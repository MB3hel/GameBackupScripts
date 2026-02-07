GAME="Minecraft_Bedrock"
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
    VARIANT="_MCPELauncher_Flatpak"
    do_backup "$HOME/.var/app/io.mrarm.mcpelauncher/data/mcpelauncher/games/com.mojang/minecraftWorlds"
fi
