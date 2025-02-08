#!/bin/zsh

## JAMF Extension Attribute: Check if the Privileges Scripts Exist
TARGET_DIR="/Users/Shared/privileges-scripts"
TARGET_FILE="$TARGET_DIR/on-action.sh"

if [[ -d "$TARGET_DIR" && -f "$TARGET_FILE" ]]; then
    echo "<result>Exists</result>"
else
    echo "<result>Missing</result>"
fi

exit 0
