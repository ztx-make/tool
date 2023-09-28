#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

# TODO: system / module replace to generic name
# TODO: abstract img / ota / file output

assembleSystem() {
    loadRecord "last" "build"
    if [ -z $(getRecord TASK_BUILD_SYSTEM_SUCCESS_TIME) ]; then
        echoFatal "build system not success"
    fi
    unloadRecord

    safeExec baseAssembleSystem
    safeExec seriesAssembleSystem
    safeExec targetAssembleSystem
}

assembleBackup() {
    loadRecord "last" "build"
    local buildJobId=$(getRecord JOB_ID)
    unloadRecord

    initBackupOutputDir

    if [ "$buildJobId" != "$jobId" ]; then
        if [ -z "$buildJobId" ]; then
            echoFatal "last build job_id is empty"
        fi
        if [ ! -d "$tempDir/$buildJobId" ]; then
            echoFatal "job dir [$tempDir/$buildJobId] not exists"
        fi

        local files
        readarray -t files < <(find $tempDir/$buildJobId -maxdepth 1 -mindepth 1 -type f -name "*.log" -o -name "*.record")
        local file
        for file in "${files[@]}"; do
            local dest=$(getAlternateFile "$backupOutputDir/$(basename $file)")
            createHardLink "$file" "$dest"
        done
    fi

    local files
    readarray -t files < <(find $jobDir -maxdepth 1 -mindepth 1 -type f -name "*.log" -o -name "*.record")
    local file
    for file in "${files[@]}"; do
        local dest=$(getAlternateFile "$backupOutputDir/$(basename $file)")
        createHardLink "$file" "$dest"
    done

    safeExec baseAssembleBackup
    safeExec seriesAssembleBackup
    safeExec targetAssembleBackup
}

assembleModule() {
    loadRecord "last" "build"
    if [ -z $(getRecord TASK_BUILD_MODULE_SUCCESS_TIME) ]; then
        echoFatal "build module not success"
    fi
    unloadRecord

    initModuleOutoutDir

    safeExec baseAssembleModule
    safeExec seriesAssembleModule
    safeExec targetAssembleModule
}

if [ -z "$module" ]; then
    if [ "$disableCheck" != "true" ]; then
        execFile "check"
    fi
    execTask "assemble system"
    execTask "assemble backup"
else
    execTask "assemble module"
fi
if [ -d "$imgOutputDir" ]; then
    execTask "create dir check tool" "$imgOutputDir"
fi
if [ -d "$otaOutputDir" ]; then
    execTask "create dir check tool" "$otaOutputDir"
fi
if [ -d "$fileOutputDir" ]; then
    execTask "create dir check tool" "$fileOutputDir"
fi
echoCompleted
