#!/bin/zsh

# Determine the Datadog API key
DATADOG_API_KEY="${4:-$(/usr/bin/security find-generic-password -s "DatadogAPI" -a "DatadogUploader" -w 2>/dev/null)}"

if [[ -z "$DATADOG_API_KEY" ]]; then
    /bin/echo "Error: Datadog API key not found."
    exit 1
fi

DATADOG_ENDPOINT="https://http-intake.logs.datadoghq.eu/api/v2/logs"

# Get system information
currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ { print $3 }')
hostname=$(/bin/hostname)
timestamp=$(/bin/date +"%Y-%m-%d %H:%M:%S")
futureTime=$(/bin/date -v+14M -v+56S +"%Y-%m-%d %H:%M:%S")
serialNumber=$(/usr/sbin/ioreg -l | /usr/bin/awk -F'"' '/IOPlatformSerialNumber/ {print $4}')
logfile="/private/tmp/user-initiated-privileges-change.tmp"
passedPromotionReason="$3"

# Check if the user is currently an admin
adminUsers=$(/usr/bin/dscl . -read /Groups/admin GroupMembership 2>/dev/null | /usr/bin/awk '{$1=""; print $0}' | /usr/bin/tr -s ' ')
if echo "$adminUsers" | /usr/bin/grep -qw "$currentUser"; then
    previousStatus="Administrator"
    userWasAdmin=true
else
    previousStatus="Standard User"
    userWasAdmin=false
fi

# Wait for user promotion (up to 5 seconds)
wait_time=0
while ! $userWasAdmin && (( wait_time < 5 )); do
    /bin/echo "Waiting for admin privileges... ($wait_time sec)"
    /bin/sleep 1
    ((wait_time++))
    
    # Recheck admin status
    if echo "$adminUsers" | /usr/bin/grep -qw "$currentUser"; then
        userWasAdmin=true
    fi
done

# Determine new status
privilegeStatus=$([[ $userWasAdmin == true ]] && /bin/echo "Administrator" || /bin/echo "Standard User")
/bin/echo "$privilegeStatus"

# Capture the reason for promotion
if [[ "$privilegeStatus" == "Administrator" ]]; then
    promotionReason="$passedPromotionReason"
    if [[ -z "$promotionReason" ]]; then
        /bin/sleep 5
        logOutput=$(/usr/bin/log show --style syslog --predicate 'process == "PrivilegesDaemon" && eventMessage CONTAINS "SAPCorp"' --info --last 5m 2>/dev/null)
        promotionReason=$(echo "$logOutput" | /usr/bin/grep -oE 'User .* now has administrator privileges for the following reason: ".*"' | /usr/bin/tail -n1 | /usr/bin/sed -E 's/.*for the following reason: "(.*)"/\1/' | /usr/bin/tr -d '\n')
        if [[ -z "$promotionReason" ]]; then
            promotionReason="Failed to obtain reason."
        fi
    fi
else
    promotionReason="User was demoted to standard user automatically."
fi

# Capture installation logs for demotion
installLogEntries="N/A"
if [[ "$privilegeStatus" == "Standard User" ]]; then
    installLogEntries=$(/usr/bin/awk -v d="$($(/bin/date -v-20M +"%b %d %H:%M:%S"))" '$0 > d && ($0 ~ /Installer\[/ || $0 ~ /installd\[/) && ($0 ~ /Installation Log/ || $0 ~ /Install: \"/ || $0 ~ /PackageKit: Installed/)' /var/log/install.log 2>/dev/null)
fi

# Sanitize LogMessage
sanitizedReason="${promotionReason//[^[:print:]]/}"
sanitizedInstallLog="${installLogEntries//[^[:print:]]/}"

# Construct log message
logMessage="User $currentUser changed privilege status at $timestamp on $hostname. Expected removal at $futureTime. Status: $privilegeStatus. Reason: $sanitizedReason"
[[ "$privilegeStatus" == "Standard User" ]] && logMessage+="\n\nInstall Log:\n\n$sanitizedInstallLog"

/bin/echo "$logMessage" | /usr/bin/tee "$logfile"

# Determine dynamic Datadog tag
addtags=$([[ "$privilegeStatus" == "Administrator" ]] && /bin/echo "privilege-escalation-request" || /bin/echo "privilege-escalation-revoke")

# Prepare JSON log data for Datadog
LOG_DATA=$(/bin/cat <<EOF
{
  "ddsource": "macos",
  "service": "Privileges",
  "ddtags": "$addtags",
  "hostname": "$hostname",
  "username": "$currentUser",
  "serialnumber": "$serialNumber", 
  "timestamp": "$timestamp",
  "message": "$(/bin/echo "$logMessage" | /usr/bin/sed 's/"/\\"/g')"
}
EOF
)

# Send log to Datadog
/usr/bin/curl -s -o /dev/null -w "%{http_code}" -X POST "$DATADOG_ENDPOINT" \
     -H "Content-Type: application/json" \
     -H "DD-API-KEY: $DATADOG_API_KEY" \
     -d "$LOG_DATA" | /usr/bin/grep -q 202 || { /bin/echo "Failed to send log to Datadog."; exit 1; }

exit 0
