#! /usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)

##############################################
# Load configuration file
CONFIG_FILE="${SCRIPT_DIR}/config.cfg"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

##############################################
# Copy the game to a working directory and prep for modification
if $CLEANUP_FILES; then
    tmp_dir=$(mktemp -d)
    echo -e "Created temporary working directory at $tmp_dir\nThis direction WILL be deleted when the script ends.\n"
    trap cleanup EXIT
    function cleanup() { rm -rf "${tmp_dir}"; exit; }
else
    tmp_dir="${SCRIPT_DIR}/working_directory"
    mkdir -p $tmp_dir
    echo -e "Using working directory at $tmp_dir\nThis directory will NOT be deleted when the script ends.\n"
fi

# Extract AppImage
game_basename=$(basename "$GAME_PATH")
tmp_game="${tmp_dir}/${game_basename}"
cp "$GAME_PATH" "${tmp_game}"
cd "$tmp_dir"
"./${game_basename}" --appimage-extract > /dev/null
if [ -d AppDir ]; then
    rm -rf AppDir
fi
mv squashfs-root AppDir
cd - > /dev/null

# Copy out app.asar and extract it
if ! command -v npx > /dev/null; then
    echo "Error: The 'npx' command could not be found, but it is required for this script.  Install it, then run the script again."
    exit 1
else
    cp -a "${tmp_dir}/AppDir/resources/app.asar" "${tmp_dir}/app.asar"
    cp -a "${tmp_dir}/AppDir/resources/app.asar.unpacked" "${tmp_dir}/app.asar.unpacked"
    npx @electron/asar extract "${tmp_dir}/app.asar" "${tmp_dir}/app.asar.unpacked"
fi

##############################################
# Make any requested modifications

## Disable auto updater
if $DISABLE_AUTOUPDATER; then
    echo -e 'Disabling the auto updater\n'
    sed -i 's/autoUpdater\["on"\]/autoUpdater\["off"\]/g' "${tmp_dir}/app.asar.unpacked/dist/main/main.js"
fi

## Change simulation speeds
if $CHANGE_SPEEDS; then
    echo -e 'Updating the in-game speed options\n'
    # There are 2 files to edit: get info for both
    # TODO: improve how this is done - shouldn't have to call grep 3 times, but it was behaving weirdly when I stored the output from that call
    FOO1_TO_EDIT=$(grep -rn 'const GAME_SECONDS_PER_SECOND' "${tmp_dir}/app.asar.unpacked/dist/renderer/public" | cut -d ":" -f 1 | head -n1)
    FOO2_TO_EDIT=$(grep -rn 'const GAME_SECONDS_PER_SECOND' "${tmp_dir}/app.asar.unpacked/dist/renderer/public" | cut -d ":" -f 1 | tail -n1)
    STR_TO_REPLACE=$(grep -rn 'const GAME_SECONDS_PER_SECOND' "${tmp_dir}/app.asar.unpacked/dist/renderer/public" | cut -d ":" -f 3- | head -n1 | awk '{$1=$1};1')
    STR_REPLACEMENT='const GAME_SECONDS_PER_SECOND = { "slow": '$(echo $NEW_SPEEDS | cut -d " " -f 1)', "normal": '$(echo $NEW_SPEEDS | cut -d " " -f 2)', "fast": '$(echo $NEW_SPEEDS | cut -d " " -f 3)', "ultrafast": '$(echo $NEW_SPEEDS | cut -d " " -f 4)' };'
    # Update each file
    sed -i 's/'"$STR_TO_REPLACE"'/'"$STR_REPLACEMENT"'/g' "${FOO1_TO_EDIT}"
    sed -i 's/'"$STR_TO_REPLACE"'/'"$STR_REPLACEMENT"'/g' "${FOO2_TO_EDIT}"
fi

##############################################
# Repack app.asar and remake the AppImage
npx @electron/asar pack "${tmp_dir}/app.asar.unpacked" "${tmp_dir}/patched_app.asar"
yes | cp -a "${tmp_dir}/patched_app.asar" "${tmp_dir}/AppDir/resources/app.asar"
if ! command -v appimagetool > /dev/null; then
    echo -e "Error: The 'appimagetool' command could not be found, but it is used to make the patched AppImage.\nIt can be found on GitHub: https://github.com/AppImage/appimagetool\nDownload the latest release with the correct architecture for your CPU (likely x86_64 or aarch64).\nEnsure this downloaded file is accessible via the command 'appimagetool' (set alias, symbolic link to somewhere in your path, etc.) and then re-run the script."
    exit 1
else
    echo -e "Creating patched AppImage\n\n*****\n"
    cd "${tmp_dir}"
    appimagetool "AppDir"
    cd - > /dev/null
    PATCHED_FILE=$(find "${tmp_dir}" -type f -exec stat -c "%y %n" {} + | sort -r | head -n 1 | cut -d " " -f 4-)
    if [[ "${PATCHED_FILE}" != *".AppImage"* || "${PATCHED_FILE}" == *"${game_basename}"* ]]; then
        echo -e "\n*****\n\nError: Patched AppImage not found.  See above output from appimagetool for info."
        exit 1
    fi
    BUILD_DIR="${SCRIPT_DIR}/builds"
    mkdir -p "${BUILD_DIR}"
    BUILD_FILE="${BUILD_DIR}/Subway_Builder_patched.AppImage"
    yes | cp -a "${PATCHED_FILE}" "${BUILD_FILE}"
    if [ -f "$PATCHED_FILE" ]; then
        echo -e "\n*****\n\nScript complete. The patched AppImage is located at\n    ${BUILD_FILE}"
    else
        # This shouldn't happen, but you never know?
        echo -e "\n*****\n\nError: Patched AppImage not found.  See above output from appimagetool for info."
        exit 1
    fi
fi

