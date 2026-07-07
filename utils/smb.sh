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
# script:      smb.sh
# description: Cross platform helper for SMB file operations. Backed by smbclient on Linux or macOS,
#              and native support on windows (via busybox or msys2 since this is a shell script)
####################################################################################################

[ -z "$SMB_USER" ] && SMB_USER=""
[ -z "$SMB_PASS" ] && SMB_PASS=""

if [ -z "$IS_WIN" ]; then
    case "$(uname -o)" in
        Msys)
            IS_WIN=1
            ;;
        MS/Windows)
            IS_WIN=1
            ;;
        *)
            IS_WIN=0
            ;;
    esac
fi

# Split smb paths in one of the following forms into their parts
#   Linux format:   smb://SERVER/SHARE/PATH
#   Windows format: \\SERVER\SHARE\PATH
# This function executes in a subshell so variables here are "local"
# Function Arguments:
#   $1 = Path to split
# This function outputs varaible settings which can be eval'ed. The following are set:
#   SMB_SERVER
#   SMB_SHARE
#   SMB_PATH
smb-split-path(){(
    # Argument parsing
    if [ $# -ne 1 ]; then
        echo "return 1"
        return 1
    fi
    P="$1"

    # Replace backslash with forward slash and remove // prefix
    # This will match nothing on Linux style paths
    P="$(echo "$P" | sed 's#\\#/#g')"
    P="$(echo "$P" | sed 's#^//##g')"

    # Strip smb:// prefix. This will match nothing on Windows style paths
    P="$(echo "$P" | sed 's#^smb://##g')"

    # Replace any duplicated slashes with a single slash
    # Makes the splitting below tolerant of typos
    P="$(echo "$P" | sed 's#//#/#g')"

    # Use sed to split and output the variable settings
    # Note: Use of single quotes in printed string is important since this is intended to be
    #       eval'ed, but the input of this function could be user provided. Double quotes
    #       would allow arbitrary command execution
    SPLIT="$(echo "$P" | sed -n -E 's#([^/]+)/([^/]+)/?(.*)#SMB_SERVER='\''\1'\''\nSMB_SHARE='\''\2'\''\nSMB_PATH='\''/\3'\''\n#p')"
    if [ -n "$SPLIT" ]; then
        echo "$SPLIT"
    else
        echo "return 1"
        return 1
    fi
)}

# Prompt for SMB credentials and store them in globals
# This script currently only supports a single set of SMB credentials at
# a time
# $1 = SMB destination path
smb-auth(){
    [ $# -ne 1 ] && return 1
    
    # Prompt for credentials and store them for future
    _OLD_SMB_USER="$SMB_USER"
    read -p "SMB User ($SMB_USER): " SMB_USER
    if [ "$SMB_USER" = "" ]; then
        SMB_USER="$_OLD_SMB_USER"
    fi
    unset _OLD_SMB_USER

    ec=$?
    [ $ec -ne 0 ] && return $ec
    read -p "SMB Pass: " -s SMB_PASS
    return $ec
}

# SMB copy
# $1 = local source path
# $2 = smb destination path including file name (assumed to be in proper format)
smb-cp(){(
    [ $# -ne 2 ] && return 1
    # This will set SMB_SERVER, SMB_SHARE, and SMB_PATH
    eval "$(smb-split-path "$2")" || return 1
    if [ $IS_WIN -eq 0 ]; then
        # Not windows. Use smbclient
        smbclient "//$SMB_SERVER/$SMB_SHARE" -U "$SMB_USER%$SMB_PASS" -c "cd \"$(dirname "$SMB_PATH")\"; put \"$1\" \"$(basename "$SMB_PATH")\""
        return $?
    else
        # Windows. Use builtin copy commands with proper path format
        
        # Authenticate
        net.exe use "\\\\$SMB_SERVER\\$SMB_SHARE" "$SMB_PASS" /user:"$SMB_USER"
        ec=$?
        [ $ec -ne 0 ] && return $ec

        # Copy (works in busybox and msys2)
        cp "$1" "//$SMB_SERVER/$SMB_SHARE/$SMB_PATH"
        return $?
    fi
)}
