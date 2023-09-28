#!/bin/bash

if [ -z "$MAX_JOB_DIR_COUNT" ]; then
    MAX_JOB_DIR_COUNT="100"
fi
if [ -z "$MAX_OUTPUT_DEBUG_DIR_DAYS" ]; then
    MAX_OUTPUT_DEBUG_DIR_DAYS="7"
fi

getAlternateDir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "$dir"
    else
        local index=1
        while [ true ]; do
            local alternateDir="${dir}_$index"
            if [ ! -d "$alternateDir" ]; then
                echo "$alternateDir"
                break
            else
                index=$((index + 1))
            fi
        done
    fi
}

getAlternateFile() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "$file"
    else
        local dir=$(dirname $file)
        local fullName=$(basename "$file")
        local shortName="${fullName%.*}"
        local extension="${fullName##*.}"
        local index=1
        while [ true ]; do
            local alternateFile="$dir/${shortName}_$index.$extension"
            if [ ! -d "$alternateFile" ]; then
                echo "$alternateFile"
                break
            else
                index=$((index + 1))
            fi
        done
    fi
}

makeBaseSourcePatch() {
    execCmd "python3 $toolDir/macro/app.py $baseDir/source/$1 $patchDir"
}

makeBaseBinaryPatch() {
    execCmd "cp -rf $baseDir/binary/$1/* $patchDir"
}

makeSeriesSourcePatch() {
    execCmd "python3 $toolDir/macro/app.py $seriesDir/source/$1 $patchDir"
}

makeSeriesBinaryPatch() {
    execCmd "cp -rf $seriesDir/binary/$1/* $patchDir"
}

createDir() {
    if [ ! -d "$1" ]; then
        execCmd "mkdir -p $1"
    fi
}

createDirNoLog() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

clearDir() {
    if [ -d "$1" ]; then
        execCmd "rm -rf $1"
    fi
    execCmd "mkdir -p $1"
}

clearDirNoLog() {
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
    mkdir -p "$1"
}

createFileNoLog() {
    if [ ! -f "$1" ]; then
        touch "$1"
    fi
}

createSoftLinkNoLog() {
    ln -sf "$1" "$2"
}

createHardLink() {
    execCmd "ln -f $1 $2"
}

createHardLinkNoLog() {
    ln -f "$1" "$2"
}

deleteFile() {
    if [ -f "$1" ]; then
        execCmd "rm -f $1"
    fi
}

deleteFileNoLog() {
    if [ -f "$1" ]; then
        rm -f "$1"
    fi
}

deleteDir() {
    if [ -d "$1" ]; then
        execCmd "rm -rf $1"
    fi
}

deleteDirNoLog() {
    if [ -d "$1" ]; then
        rm -rf "$1"
    fi
}

cleanup() {
    local maxJobDirCount="$1"
    local maxOutputDebugDirDays="$2"

    if [ -z "$maxJobDirCount" ]; then
        maxJobDirCount="$MAX_JOB_DIR_COUNT"
    fi
    if [ -z "$maxOutputDebugDirDays" ]; then
        maxOutputDebugDirDays="$MAX_OUTPUT_DEBUG_DIR_DAYS"
    fi

    # 清理 temp/job_* 目录
    if [ -d "$tempDir" ]; then
        local dirs
        readarray -t dirs < <(find $tempDir -maxdepth 1 -mindepth 1 -type d -name "job_*" -printf "%T@\t%p\n" | sort -r | cut -f 2)
        local i
        for ((i = $maxJobDirCount; i < ${#dirs[@]}; i++)); do
            local dir="${dirs[$i]}"
            deleteDir "$dir"
            echo "[$(logTimestamp)] delete $dir" >>$logDir/cleanup.log
        done
    fi
    # 清理 temp/download 目录
    if [ -d "$tempDir/download" ]; then
        local parentDirs
        readarray -t parentDirs < <(find $tempDir/download -maxdepth 1 -mindepth 1 -type d)
        local parentDir
        for parentDir in "${parentDirs[@]}"; do
            local dirs
            readarray -t dirs < <(find $parentDir -maxdepth 1 -mindepth 1 -type d -printf "%T@\t%p\n" | sort -r | cut -f 2)
            local i
            for ((i = 1; i < ${#dirs[@]}; i++)); do
                local dir="${dirs[$i]}"
                deleteDir "$dir"
                echo "[$(logTimestamp)] delete $dir" >>$logDir/cleanup.log
            done
        done
    fi
    # 清理 output/debug 目录
    if [ -d "$outputDir/debug" ]; then
        local dirs
        readarray -t dirs < <(find $outputDir/debug -maxdepth 1 -mindepth 1 -type d -mtime +$maxOutputDebugDirDays)
        local dir
        for dir in "${dirs[@]}"; do
            deleteDir "$dir"
            echo "[$(logTimestamp)] delete $dir" >>$logDir/cleanup.log
        done
    fi
}

createDirCheckTool() {
    local dir="$1"
    echoAndCheckEmptyValues "dir"
    if [ -d "$dir" ]; then
        local shFile="$dir/__check__.sh"
        local batFile="$dir/__check__.bat"

        cat "$toolDir/template/check_md5.sh" >"$shFile"
        cat "$toolDir/template/check_md5.bat" >"$batFile"

        local fileNames
        readarray -t fileNames < <(cd $dir && find . -type f)
        local fileName
        for fileName in "${fileNames[@]}"; do
            if [[ "$fileName" =~ ^\.\/ ]]; then
                fileName="${fileName:2}"
            else
                echoFatal "file name [$fileName] not starts with [./]"
            fi
            local file=$(realpath "$dir/$fileName")
            if [ "$file" = "$shFile" ] || [ "$file" = "$batFile" ]; then
                continue
            fi
            local md5=$(md5sum -b "$file" | cut -d " " -f 1)
            echoGray "file [$fileName] md5 [$md5]"
            echo "checkFile \"$fileName\" \"$md5\"" >>"$shFile"
            echo "CALL:checkFile \"$fileName\" \"$md5\" || EXIT /B %ERRORLEVEL%" >>"$batFile"
        done
        echo "echo -e \\\\nsuccess" >>"$shFile"
        echo "ECHO. && ECHO success && ECHO." >>"$batFile"
        echo "PAUSE" >>"$batFile"
        echo "EXIT /B 0" >>"$batFile"
        execCmd "unix2dos -q \"$batFile\""
    else
        echoFatal "dir [$dir] not exists"
    fi
}

updateExtension() {
    execCmd "git -C $extensionDir pull"
}
