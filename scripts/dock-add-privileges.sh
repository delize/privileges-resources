#!/bin/zsh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 
# version 2.2
# Modified by: Andrew Doering
# Based on original work by: Mischa van der Bent
# 
# DESCRIPTION
# This script ensures Privileges.app is in the Dock at the end, replacing it if already present.
# It uses dockutil to manage the Dock and safely exits to prevent Jamf Pro policy failures.
#
# REQUIREMENTS
# dockutil Version 3.0.0 or higher installed to /usr/local/bin/
# Compatible with macOS 11.x and higher
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Variables
appPath="/Applications/Privileges.app"
position="end"
dockutil="/usr/local/bin/dockutil"

# Get the currently logged-in user
currentUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }' )
uid=$(id -u "${currentUser}")
userHome=$(dscl . -read /users/${currentUser} NFSHomeDirectory | cut -d " " -f 2)
plist="${userHome}/Library/Preferences/com.apple.dock.plist"

# Function to run commands as the logged-in user
runAsUser() {
    if [[ "${currentUser}" != "loginwindow" ]]; then
        launchctl asuser "$uid" sudo -u "${currentUser}" "$@"
    else
        echo "No user logged in"
        exit 1
    fi
}

# Check if dockutil is installed
if [[ ! -x "$dockutil" ]]; then
    echo "dockutil not installed in /usr/local/bin, exiting"
    exit 1
fi

# Add or replace Privileges.app in the Dock
echo "Ensuring Privileges.app is in the Dock at the end."
runAsUser "$dockutil" --add "$appPath" --position "$position" --replacing "Privileges" "$plist"

# Ensure script exits cleanly to avoid Jamf Pro failures
exit 0
