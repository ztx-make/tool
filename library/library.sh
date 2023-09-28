#!/bin/bash
set -o errexit
shopt -s inherit_errexit

cpuNum=$(cat /proc/cpuinfo | grep processor | wc -l)

if [ -z "$myPath" ]; then
    echo "myPath not set"
    exit 1
fi
if [ -z "$myFile" ]; then
    echo "myFile not set"
    exit 1
fi
if [ -z "$toolDir" ]; then
    echo "toolDir not set"
    exit 1
fi
myProcess="${myFile%.*}"
if [ "$myPath" = "$toolDir/$myFile" ]; then
    internalFile="true"
else
    internalFile="false"
fi

source "$toolDir/library/time.sh"
source "$toolDir/library/echo.sh"
source "$toolDir/library/string.sh"
source "$toolDir/library/exec.sh"
source "$toolDir/library/process.sh"
source "$toolDir/library/file.sh"
source "$toolDir/library/feature.sh"
source "$toolDir/library/job.sh"

loadTimeOffset

projectDir=$(
    cd $toolDir/../
    pwd
)
if [ -n "$ZTX_MAKE_EXTENSION_DIR" ]; then
    if [ ! -d "$ZTX_MAKE_EXTENSION_DIR" ]; then
        echoFatal "extension dir [$ZTX_MAKE_EXTENSION_DIR] not exists"
    fi
    extensionDir="$ZTX_MAKE_EXTENSION_DIR"
else
    extensionDir="$projectDir/extension"
fi
sourceDir="$projectDir/source"
logDir="$projectDir/log"
tempDir="$projectDir/temp"
outputDir="$projectDir/output"
developerDir="$projectDir/developer"

createDirNoLog "$logDir"
createDirNoLog "$tempDir"
createDirNoLog "$outputDir"

if [ -z "$ZTX_MAKE_ENTRYPOINT_TIME" ]; then
    export ZTX_MAKE_ENTRYPOINT_TIME=$(currentSeconds)
fi

if [ "$internalFile" = "true" ]; then
    checkProcessExists

    if [ "$myProcess" != "run" ]; then
        initJob

        if [ -z "$ZTX_MAKE_PROCESS_START_TIME" ]; then
            export ZTX_MAKE_PROCESS_START_TIME=$(currentSeconds)
            rootProcess="true"
        else
            rootProcess="fasle"
        fi

        appendRecord "ENTRYPOINT_TIME" "$ZTX_MAKE_ENTRYPOINT_TIME"
        appendRecord "PROCESS_START_TIME" "$ZTX_MAKE_PROCESS_START_TIME"

        parentFile="$ZTX_MAKE_LAST_EXEC_FILE"
        export ZTX_MAKE_LAST_EXEC_FILE="$myFile"
    fi

    if [ "$myProcess" != "run" ] && [ "$myProcess" != "init" ]; then
        if [ -d "$sourceDir/.git" ]; then
            versionControl="git"
        elif [ -d "$sourceDir/.repo" ]; then
            versionControl="repo"
        else
            echoFatal "[$sourceDir] must use 'git' or 'repo' as version control"
        fi
        if [ "$rootProcess" = "true" ]; then
            execTask "cleanup"
            execTask "update extension"
        fi
        source "$toolDir/library/option.sh"
        execTask "options" "$@"
    fi
fi
