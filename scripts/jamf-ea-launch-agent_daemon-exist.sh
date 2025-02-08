#!/bin/zsh

## JAMF Extension Attribute: Check if LaunchAgent and LaunchDaemon are Valid
AGENT_PLIST="/Library/LaunchAgents/corp.sap.privileges.agent.plist"
AGENT_EXPECTED_PROGRAM="/Applications/Privileges.app/Contents/MacOS/PrivilegesAgent.app/Contents/MacOS/PrivilegesAgent"
AGENT_EXPECTED_TEAM="7R5ZEU67FQ"

DAEMON_PLIST="/Library/LaunchDaemons/corp.sap.privileges.daemon.plist"
DAEMON_EXPECTED_PROGRAM="/Applications/Privileges.app/Contents/MacOS/PrivilegesDaemon"
DAEMON_EXPECTED_TEAM="7R5ZEU67FQ"

status="Valid"

# Check LaunchAgent
if [[ ! -f "$AGENT_PLIST" ]]; then
    status="Missing LaunchAgent"
elif ! /usr/bin/defaults read "$AGENT_PLIST" 2>/dev/null | /usr/bin/grep -q "$AGENT_EXPECTED_PROGRAM"; then
    status="Modified LaunchAgent"
elif ! /usr/bin/defaults read "$AGENT_PLIST" 2>/dev/null | /usr/bin/grep -q "$AGENT_EXPECTED_TEAM"; then
    status="Modified LaunchAgent"
fi

# Check LaunchDaemon
if [[ ! -f "$DAEMON_PLIST" ]]; then
    status="Missing LaunchDaemon"
elif ! /usr/bin/defaults read "$DAEMON_PLIST" 2>/dev/null | /usr/bin/grep -q "$DAEMON_EXPECTED_PROGRAM"; then
    status="Modified LaunchDaemon"
elif ! /usr/bin/defaults read "$DAEMON_PLIST" 2>/dev/null | /usr/bin/grep -q "$DAEMON_EXPECTED_TEAM"; then
    status="Modified LaunchDaemon"
fi

# Output the result
echo "<result>$status</result>"
exit 0
