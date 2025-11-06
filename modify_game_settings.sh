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
# Sanity check - stop if the game file doesn't exist
if [ -f "$GAME_PATH" ]; then
    echo -e "Base AppImage used:\n    ${GAME_PATH}\n"
else
    echo -e "Base AppImage not found at specified location:\n    ${GAME_PATH}"
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

# Paths to index and interlinedRoutes files
FINDEX=$(ls ${tmp_dir}/app.asar.unpacked/dist/renderer/public/index*.js)
FROUTES=$(ls ${tmp_dir}/app.asar.unpacked/dist/renderer/public/interlinedRoutes*.js)

##############################################
# Make any requested modifications

## Disable auto updater
if [ -n "$DISABLE_AUTOUPDATER" ] && $DISABLE_AUTOUPDATER; then
    if [ -f "${tmp_dir}/app.asar.unpacked/dist/main/main.jsc" ]; then
        echo -e "Disabling the auto-updater was requested, but this is only possible for versions <=0.7.3.  The AppImage contents suggest that the version provided is >=0.7.6.  Continuing without disabling the auto-updater.\n"
    else
        echo -e 'Disabling the auto updater\n'
        sed -i 's/autoUpdater\["on"\]/autoUpdater\["off"\]/g' "${tmp_dir}/app.asar.unpacked/dist/main/main.js"
    fi
fi

## Change simulation speeds
if [ -n "$CHANGE_SPEEDS" ] && $CHANGE_SPEEDS; then
    echo -e 'Updating the in-game speed options\n'
    NEW_SPEEDS=($NEW_SPEEDS)
    sed -i -E '{
      s/"slow":[[:space:]]*[0-9]+/"slow": '"${NEW_SPEEDS[0]}"'/
      s/"normal":[[:space:]]*[0-9]+/"normal": '"${NEW_SPEEDS[1]}"'/
      s/"fast":[[:space:]]*[0-9]+/"fast": '"${NEW_SPEEDS[2]}"'/
      s/"ultrafast":[[:space:]]*[0-9]+/"ultrafast": '"${NEW_SPEEDS[3]}"'/
    }' "${FINDEX}"
    sed -i -E '{
      s/"slow":[[:space:]]*[0-9]+/"slow": '"${NEW_SPEEDS[0]}"'/
      s/"normal":[[:space:]]*[0-9]+/"normal": '"${NEW_SPEEDS[1]}"'/
      s/"fast":[[:space:]]*[0-9]+/"fast": '"${NEW_SPEEDS[2]}"'/
      s/"ultrafast":[[:space:]]*[0-9]+/"ultrafast": '"${NEW_SPEEDS[3]}"'/
    }' "${FROUTES}"
fi

## Change minimum turn radius
if [ -n "$CHANGE_MIN_TURN_RAD" ] && $CHANGE_MIN_TURN_RAD; then
    echo -e 'Updating the minimum allowed turn radius\n'
    sed -i -E 's/("MIN_TURN_RADIUS":)[[:space:]]*[^,]*/\1 '"$MIN_TURN_RAD"'/' "${FINDEX}"
    sed -i -E 's/("MIN_TURN_RADIUS":)[[:space:]]*[^,]*/\1 '"$MIN_TURN_RAD"'/' "${FROUTES}"
fi

## Change max slope percentage
if [ -n "$CHANGE_MAX_SLOPE" ] && $CHANGE_MAX_SLOPE; then
    echo -e 'Updating the maximum allowed slope\n'
    # Allowed maximum
    sed -i -E 's/("MAX_SLOPE_PERCENTAGE":)[[:space:]]*[^,]*/\1 '"$MAX_SLOPE"'/' "${FINDEX}"
    sed -i -E 's/("MAX_SLOPE_PERCENTAGE":)[[:space:]]*[^,]*/\1 '"$MAX_SLOPE"'/' "${FROUTES}"
    # Update speed penalty range
    sed -i -E 's/("maxSlopePercentage":)[[:space:]]*[^,]*/\1 '"$MAX_SLOPE"'/2' "${FINDEX}"
    sed -i -E 's/("maxSlopePercentage":)[[:space:]]*[^,]*/\1 '"$MAX_SLOPE"'/2' "${FROUTES}"
fi

## Change starting money
if [ -n "$CHANGE_START_MONEY" ] && $CHANGE_START_MONEY; then
    echo -e 'Updating the starting money amount\n'
    sed -i -E 's/("STARTING_MONEY":)[[:space:]]*[^,]*/\1 '"$START_MONEY"'e9/' "${FINDEX}"
    sed -i -E 's/("STARTING_MONEY":)[[:space:]]*[^,]*/\1 '"$START_MONEY"'e9/' "${FROUTES}"
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
    echo $PATCHED_FILE
    if [[ "${PATCHED_FILE}" != *".AppImage"* ]]; then
        echo -e "\n*****\n\nError: Patched AppImage not found.  See above output from appimagetool for info."
        exit 1
    fi
    BUILD_DIR="${SCRIPT_DIR}/builds"
    echo "Creating builds directory at ${BUILD_DIR} to hold the patched AppImage"
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

