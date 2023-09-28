#!/bin/bash

export SCL_FEATURE_KEY_PREFIX="ZTX_MACRO_"

initFeature() {
    features=("${features[@]}")
    local item
    for item in "${@}"; do
        local key="${item%=*}"
        local value="${item#*=}"

        local exist
        for exist in "${features[@]}"; do
            if [ "$exist" = "$key" ]; then
                echoFatal "duplicate feature: $key in [${*}]"
            fi
        done

        features[${#features[@]}]="$key"
        export ${SCL_FEATURE_KEY_PREFIX}$key="$value"
    done
}

setFeature() {
    local key="$1"
    local value="$2"
    echoGray "setFeature: $key = $value"

    local envName="${SCL_FEATURE_KEY_PREFIX}$key"

    set +o errexit
    declare -p "$envName" >/dev/null 2>&1
    local exitCode="$?"
    set -o errexit

    if [ "$exitCode" = "0" ]; then
        export ${SCL_FEATURE_KEY_PREFIX}$key="$value"
    else
        echoFatal "unexpected feature: $key"
    fi
}

getFeature() {
    local key="$1"
    local envName="${SCL_FEATURE_KEY_PREFIX}$key"
    echo "${!envName}"
}

printFeature() {
    local key
    for key in "${features[@]}"; do
        echoBlue "$key = $(getFeature $key)"
    done
}

adjustFeature() {
    initFeature "SUPPORT=1" "TARGET=$target" "BUILD_TIME=$buildTime"

    safeExec baseInitFeature
    safeExec seriesInitFeature
    safeExec baseAdjustFeature
    safeExec seriesAdjustFeature
    safeExec targetAdjustFeature
}

checkFeature() {
    printFeature

    if [ "$(getFeature SUPPORT)" != "1" ]; then
        echoFatal "feature SUPPORT must be 1"
    fi

    safeExec baseCheckFeature
    safeExec seriesCheckFeature
    safeExec targetCheckFeature
}
