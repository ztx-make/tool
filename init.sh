#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

options() {
    sourceVersionControl="git"

    if [ -z "$1" ]; then
        if [ -z "$ZTX_EXTENSION_SERIES" ]; then
            echoFatal "tar file path missing"
        else
            if [ -f "/origin/series-$ZTX_EXTENSION_SERIES/artifact/source.repo.tar" ]; then
                sourceTarFile="/origin/series-$ZTX_EXTENSION_SERIES/artifact/source.repo.tar"
                sourceVersionControl="repo"
            else
                sourceTarFile="/origin/series-$ZTX_EXTENSION_SERIES/artifact/source.git.tar"
            fi
        fi
    else
        sourceTarFile=$(realpath $1)
        if [ -n "$2" ]; then
            sourceVersionControl="$2"
        fi
    fi

    echoAndCheckEmptyValues "sourceTarFile" "sourceVersionControl"
    if [ ! -f "$sourceTarFile" ]; then
        echoFatal "tar file [$sourceTarFile] not exists"
    fi
    if [[ ! "$sourceVersionControl" =~ ^(git|repo)$ ]]; then
        echoFatal "version control must be one of [git, repo]"
    fi
}

check() {
    local diskFree=$(df -k --output=avail "$projectDir" | tail -n1)
    if [ "$diskFree" -lt "314572800" ]; then
        echoFatal "disk free space is less than 300GB"
    fi
    if [ -d "$sourceDir" ] && [ $(ls -A $sourceDir) != "" ]; then
        echoFatal "source dir [$sourceDir] exists and not empty"
    fi
}

downloadModule() {
    if [ -d "$extensionDir" ]; then
        execCmd "rm -rf $extensionDir"
    fi
    # TODO: download extension to $extensionDir
}

decompressSource() {
    createDir "$sourceDir"
    execCmd "cd $sourceDir"
    execCmd "tar --no-same-owner -mxvf $sourceTarFile"
}

checkoutSource() {
    execCmd "cd $sourceDir"
    if [ "$sourceVersionControl" = "git" ]; then
        execCmd "git reset --hard"
        execCmd "git clean -df"
        execCmd "git status"
    elif [ "$sourceVersionControl" = "repo" ]; then
        execCmd "repo sync -l -j$cpuNum"
        execCmd "repo status"
    fi
}

decompressPatch() {
    local patchTarFile="$sourceDir/.patch.tar.gz"
    echoAndCheckEmptyValues "patchTarFile"
    if [ -f "$patchTarFile" ]; then
        execCmd "cd $sourceDir"
        execCmd "tar --no-same-owner -mxzvf $patchTarFile"
    else
        echoInfo "no patch required"
    fi
}

execTask "options" "$@"
execTask "check"
execTask "download module"
execTask "decompress source"
execTask "checkout source"
execTask "decompress patch"
echoCompleted
