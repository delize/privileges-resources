#!/bin/zsh

# Get the currently logged-in user
currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Exclude specific users from demotion
if [[ "$currentUser" == "administrator" || "$currentUser" == "root" ]]; then
    echo "Skipping demotion for $currentUser."
    exit 0
fi

# Path to PrivilegesCLI
PRIVILEGES_CLI="/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI"

# Ensure PrivilegesCLI exists
if [[ ! -x "$PRIVILEGES_CLI" ]]; then
    echo "Error: PrivilegesCLI not found. Ensure Privileges.app is installed."
    exit 1
fi

# Run PrivilegesCLI as the current user to demote them
/bin/launchctl asuser $(/usr/bin/id -u "$currentUser") sudo -u "$currentUser" "$PRIVILEGES_CLI" --remove 2>/dev/null

# Verify demotion
sleep 2
demotionStatus=$(/bin/launchctl asuser $(/usr/bin/id -u "$currentUser") sudo -u "$currentUser" "$PRIVILEGES_CLI" --status)

if echo "$demotionStatus" | /usr/bin/grep -q "standard user"; then
    echo "User $currentUser is already a standard user, skipping demotion."
    exit 0
else
    echo "Failed to demote $currentUser, but user may already be a standard user."
    exit 0
fi