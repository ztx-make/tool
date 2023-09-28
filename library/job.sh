#!/bin/bash

_RECORD_VERSION="1"

initJob() {
    if [ -z "$ZTX_MAKE_JOB_ID" ]; then
        jobId="job_$(currentYmdHMS)"
        jobDir="$tempDir/$jobId"
        if [ -d "$jobDir" ]; then
            echoFatal "job dir [$jobDir] exists"
        fi
        createDirNoLog "$jobDir"
        export ZTX_MAKE_JOB_ID="$jobId"
    else
        jobId="$ZTX_MAKE_JOB_ID"
        jobDir="$tempDir/$jobId"
        if [ ! -d "$jobDir" ]; then
            echoFatal "job dir [$jobDir] not exists"
        fi
    fi
    patchDir="$jobDir/patch"
    if [ "$myProcess" != "run" ]; then
        recordFile="$jobDir/$myProcess.record"
        if [ -f "$recordFile" ]; then
            echoFatal "job [$jobId] contains duplication process [$myProcess]"
        fi
        createFileNoLog "$recordFile"
        createHardLinkNoLog "$recordFile" "$tempDir/$myProcess.record"
        appendRecord "RECORD_VERSION" "$_RECORD_VERSION"
        appendRecord "JOB_ID" "$jobId"
    fi
}

appendRecord() {
    if [ -n "$recordFile" ]; then
        echo "__r__$1=\"$2\"" >>"$recordFile"
    fi
}

appendTimeRecord() {
    appendRecord "$1" "$(currentSeconds)"
}

unloadRecord() {
    local variables=($(
        set -o posix
        set | awk -F '=' '{ print $1 }' | tr '\n' ' '
    ))
    local variable
    for variable in "${variables[@]}"; do
        if [[ $variable = __r__* ]]; then
            unset "$variable"
        fi
    done
}

loadRecord() {
    unloadRecord
    local job="$1"
    local process="$2"
    if [ "$1" = "last" ]; then
        local recordFile="$tempDir/$process.record"
    else
        local recordFile="$tempDir/$job/$process.record"
    fi
    if [ ! -f "$recordFile" ]; then
        echoFatal "record file [$recordFile] not exists"
    fi
    source "$recordFile"
    if [ "$(getRecord RECORD_VERSION)" != "$_RECORD_VERSION" ]; then
        local recordVersion=$(getRecord RECORD_VERSION)
        unloadRecord
        echoFatal "record file [$recordFile] version mismatch: recordVersion=[$recordVersion], requiredVersion=[$_RECORD_VERSION]"
    fi
}

getRecord() {
    local key="$1"
    local variable="__r__$key"
    echo "${!variable}"
}
