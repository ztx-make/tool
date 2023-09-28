#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

trap 'onCtrlC' INT
onCtrlC() {
    if [ "$quiet" != "true" ]; then
        local exists=$(getProcessPidExists $process)
        if [ "$exists" = "true" ]; then
            echo
            echo
            echoGreen "$process run in background"
            echoGreen "execute the command to view log:"
            echoGreen "tail -f $logFile"
            echoGreen "or"
            echoGreen "tail -f $logLink"
            echo
            echo
        else
            echo
        fi
    fi
    exit 0
}

options() {
    if [ "$#" = "0" ]; then
        echoFatal "params missing"
    fi

    foreground="false"
    quiet="false"
    params=()

    local count="$#"
    if [ "$count" -gt "9" ]; then
        count="9"
    fi

    local index
    for ((index = 1; index <= $#; index++)); do
        local param="${!index}"
        if [ "$param" = "--foreground" ] || [ "$param" = "-f" ]; then
            foreground="true"
        elif [ "$param" = "--quiet" ] || [ "$param" = "-q" ]; then
            quiet="true"
        elif [ -z "$process" ]; then
            process="$param"
        else
            params=("${@:$index}")
            break
        fi
    done
    if [ -z "$process" ]; then
        echoFatal "process missing"
    fi
    if [ -f "$toolDir/$process.sh" ]; then
        internal="true"
    elif [ -f "$(realpath $process)" ]; then
        internal="false"
        process="$(realpath $process)"
    else
        echoFatal "process [$process] not found"
    fi
    if [ "$process" = "run" ] || [ "$process" = "$myPath" ]; then
        echoFatal "process [$process] not support"
    fi
}

runInternal() {
    initJob
    logFile="$jobDir/$process.log"
    logLink="$logDir/$process.log"
    createFileNoLog "$logFile"
    createHardLinkNoLog "$logFile" "$logLink"

    if [ "$foreground" = "true" ]; then
        bash "$toolDir/$process.sh" "${params[@]}" >"$logFile" 2>&1
    else
        setsid bash "$toolDir/$process.sh" "${params[@]}" >"$logFile" 2>&1 &
        if [ "$quite" != "true" ]; then
            tail --retry -f "$logFile" 2>/dev/null
        fi
    fi
}

runExternal() {
    if [ "$foreground" = "true" ]; then
        bash "$process"
    else
        setsid bash "$process" &
    fi
}

options "$@"
if [ "$internal" = "true" ]; then
    runInternal
else
    runExternal
fi
