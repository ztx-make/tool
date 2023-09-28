#!/bin/bash

parseOptions() {
    target=""
    module=""
    clean=""
    buildTime=""
    releaseTime=""
    production="false"
    developer=""

    if [ "$#" != "0" ]; then
        local longoptions="target:,module:,clean,buildTime:,releaseTime:,production,developer:"
        local args
        set +o errexit
        args=$(getopt --options "" --longoptions "$longoptions" -- "$@")
        local exitCode="$?"
        set -o errexit
        if [ "$exitCode" != "0" ]; then
            echoFatal "parse options error"
        fi

        eval set -- "$args"
        while [ true ]; do
            case "$1" in
            --target)
                target="$2"
                shift
                ;;
            --module)
                module="$2"
                shift
                ;;
            --clean)
                clean="true"
                ;;
            --buildTime)
                buildTime="$2"
                shift
                ;;
            --releaseTime)
                releaseTime="$2"
                shift
                ;;
            --production)
                production="true"
                ;;
            --developer)
                developer="$2"
                shift
                ;;
            --)
                shift
                break
                ;;
            esac
            shift
        done
    fi

    if [ -z "$clean" ]; then
        if [ "$production" = "true" ]; then
            clean="true"
        else
            clean="false"
        fi
    fi

    if [ "$production" = "true" ]; then
        if [ -n "$developer" ]; then
            echoFatal "build production not support --developer"
        fi
    fi

    if [ -n "$developer" ] && [ ! -d "$developerDir/$developer" ]; then
        echoFatal "developer dir [$developerDir/$developer] not exists"
    fi

    if [ -z "$buildTime" ]; then
        buildTime=$(currentLocalSeconds)
    fi

    if [ -z "$releaseTime" ]; then
        releaseTime="$SCL_ENTRYPOINT_TIME"
    fi
}

sourceTargetFiles() {
    series="${target:0:1}"
    if [ -n "$ZTX_EXTENSION_SERIES" ] && [ "$series" != "$ZTX_EXTENSION_SERIES" ]; then
        echoFatal "[input:series-$series] != [env:series-$ZTX_EXTENSION_SERIES]"
    fi

    baseDir="$extensionDir/base"
    seriesDir="$extensionDir/series-$series"
    if [ ! -d "$baseDir" ]; then
        echoFatal "$baseDir not found"
    elif [ ! -d "$seriesDir" ]; then
        echoFatal "$seriesDir not found"
    else
        local baseFile="$baseDir/bash.sh"
        if [ ! -f "$baseFile" ]; then
            echoFatal "$baseFile not found"
        fi
        local seriesFile="$seriesDir/series.sh"
        if [ ! -f "$seriesFile" ]; then
            echoFatal "$seriesFile not found"
        fi
        local targetFile="$seriesDir/$target.sh"
        if [ ! -f "$targetFile" ]; then
            echoFatal "$targetFile not found"
        fi
        source "$baseFile"
        source "$seriesFile"
        source "$targetFile"
        echoAndCheckEmptyValues "series"
    fi

    buildTimestamp=$(date -d @$buildTime +%Y%m%d%H%M%S)
    releaseTimestamp=$(date -d @$releaseTime +%Y%m%d%H%M%S)
    if [ "$production" = "true" ]; then
        backupOutputDir="$outputDir/release/backup/backup_${releaseTimestamp}_${target}_${variant}"
        # TODO
    else
        backupOutputDir="$outputDir/debug/backup_${releaseTimestamp}_${target}_${variant}"
        # TODO
    fi
}

loadOptionsReocrd() {
    loadRecord "last" "build"
    target="$(getRecord OPTIONS_TARGET)"
    module="$(getRecord OPTIONS_MODULE)"
    clean="$(getRecord OPTIONS_CLEAN)"
    buildTime="$(getRecord OPTIONS_BUILD_TIME)"
    releaseTime="$(getRecord OPTIONS_RELEASE_TIME)"
    production="$(getRecord OPTIONS_PRODUCTION)"
    developer="$(getRecord OPTIONS_DEVELOPER)"
    unloadRecord
}

saveOptionsRecord() {
    echoAndCheckEmptyValues "clean" "buildTime" "releaseTime" "production"
    echoValues "module"
    if [ -n "$fromBuild" ]; then
        echoValues "fromBuild"
    fi
    if [ -n "$developer" ]; then
        echoValues "developer"
    fi
    appendRecord "OPTIONS_TARGET" "$target"
    appendRecord "OPTIONS_MODULE" "$module"
    appendRecord "OPTIONS_CLEAN" "$clean"
    appendRecord "OPTIONS_BUILD_TIME" "$buildTime"
    appendRecord "OPTIONS_RELEASE_TIME" "$releaseTime"
    appendRecord "OPTIONS_PRODUCTION" "$production"
    appendRecord "OPTIONS_DEVELOPER" "$developer"
}

options() {
    if [ "$myProcess" = "build" ]; then
        parseOptions "$@"
    elif [ "$myProcess" = "patch" ]; then
        if [ "$1" = "--build" ]; then
            fromBuild="true"
            loadOptionsReocrd
        else
            parseOptions "$@"
        fi
    elif [ "$myProcess" = "assemble" ]; then
        if [ "$1" = "--disableCheck" ]; then
            disableCheck="true"
        fi
        loadOptionsReocrd
    else
        loadOptionsReocrd
    fi

    echoAndCheckEmptyValues "target"

    sourceTargetFiles
    saveOptionsRecord

    safeExec baseCheckOptions
    safeExec seriesCheckOptions
    safeExec targetCheckOptions

    adjustFeature
    checkFeature
}
