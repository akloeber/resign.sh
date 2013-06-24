#!/bin/bash

#set -e
ARGS=("$@")

function _usage {
    echo "Usage: resign.sh <PRESIGNED_PACKAGE> <PROVISIONING_PROFILE> <SIGNATURE_NAME> <SIGNED_PACKAGE>"
    echo "    e.g. './resign.sh ./app_presigned.ipa ./Distribution.mobileprovision \"iPhone Distribution: Company\" ./app.ipa'"
    echo
    echo "Note: The signature referenced by <SIGNATURE_NAME> has to be present in one of the keychains on the keychain search list."
}

function _init {
    PACKAGE_PRESIGNED="${ARGS[0]}"
    PROVISIONING_PROFILE="${ARGS[1]}"
    SIGNATURE="${ARGS[2]}"
    PACKAGE_SIGNED="${ARGS[3]}"
}

function _prepare {
    if [ ! -e "$PACKAGE_PRESIGNED" ]; then
      echo "ERROR: Presigned package '$PACKAGE_PRESIGNED' not found"
      exit -1
    fi
    if [ ! -e "$PROVISIONING_PROFILE" ]; then
        echo "ERROR: Provisioning profile '$PROVISIONING_PROFILE' not found"
        exit -1
    fi
}

function _resign {
    echo "Resigning package '$PACKAGE_PRESIGNED' with provisioning profile '$PROVISIONING_PROFILE' and signature '$SIGNATURE'"

    TEMP_DIR=`mktemp -d -t package.resigning`
    echo "Using temporary directory '$TEMP_DIR'"

    echo "Inflating presigned package '$PACKAGE_PRESIGNED'"
    unzip -q "$PACKAGE_PRESIGNED" -d "$TEMP_DIR"

    APP_NAME=`ls "$TEMP_DIR/Payload"`
    APP_DIR="$TEMP_DIR/Payload/$APP_NAME"
    echo "App directory is '$APP_DIR'"

    echo "Removing old code signature"
    rm -r "$APP_DIR/_CodeSignature" "$APP_DIR/CodeResources" 2> /dev/null | true

    echo "Replacing embedded mobile provisioning profile with '$PROVISIONING_PROFILE'"
    cp "$PROVISIONING_PROFILE" "$APP_DIR/embedded.mobileprovision"

    echo "Checking if signature '$SIGNATURE' is available"
    # Note: omit force flag to determine whether build fails through ivalid certificate or because package is already signed 
    SIGNATURE_CHECK=`/usr/bin/codesign -s "$SIGNATURE" -v "$APP_DIR" 2>&1`
    if [[ "$SIGNATURE_CHECK" == *"no identity found"* ]]; then
        echo "ERROR: Signature '$SIGNATURE' is not available in the keychains on the keychain search list"
        exit -1
    fi

    echo "Resigning app with signature '$SIGNATURE'"
    /usr/bin/codesign -s "$SIGNATURE" --resource-rules "$APP_DIR/ResourceRules.plist" -vf "$APP_DIR"

    echo "Repackaging app into '$PACKAGE_SIGNED'"
    (cd "$TEMP_DIR" && zip -qr app.ipa Payload)
    mv "$TEMP_DIR/app.ipa" "$PACKAGE_SIGNED"

    echo "Removing temporary directory '$TEMP_DIR'"
    rm -rf "$TEMP_DIR"
    echo "SUCCESS: Resigning of package was successful"
}

if [ $# -ne 4 ]; then
    _usage
    exit -1
else
    _init
    _prepare
    _resign
    exit 0
fi

