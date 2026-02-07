GAME="SFC_CustomDistro"
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
            VARIANT="_Bottles_Flatpak_${bottle_name}"
            do_backup "$bottle_dir/drive_c/StarfleetCommandGames/"
        fi
    done
fi
