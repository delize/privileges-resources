#!/bin/zsh

CACHE_FILE="/private/var/tmp/datadog_offline_logs.json"

# Function to check network connectivity
check_network() {
    /sbin/ping -c 1 8.8.8.8 >/dev/null 2>&1
    return $?
}

# Function to send logs to Datadog
send_log_to_datadog() {
    local log_data="$1"
    local response_code

    response_code=$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" -X POST "$DATADOG_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: $DATADOG_API_KEY" \
        -d "$log_data")

    if [[ "$response_code" -ne 202 ]]; then
        /bin/echo "Failed to send log to Datadog. HTTP response: $response_code"
        return 1
    fi

    return 0
}

# Function to process cached logs
process_cached_logs() {
    if [[ -f "$CACHE_FILE" ]]; then
        /bin/echo "Processing cached logs..."
        
        while IFS= read -r line; do
            send_log_to_datadog "$line" && /usr/bin/sed -i '' '1d' "$CACHE_FILE"
        done < "$CACHE_FILE"

        # If file is empty, remove it
        [[ ! -s "$CACHE_FILE" ]] && /bin/rm -f "$CACHE_FILE"
    fi
}

# Prepare JSON log data
LOG_DATA=$(cat <<EOF
{
  "ddsource": "macos",
  "service": "Privileges",
  "ddtags": "$addtags",
  "hostname": "$hostname",
  "username": "$currentUser",
  "serialnumber": "$serialNumber", 
  "timestamp": "$timestamp",
  "message": "$(echo "$logMessage" | sed 's/"/\\"/g')"
}
EOF
)

# Check network status
if check_network; then
    # Process any cached logs first
    process_cached_logs

    # Send current log to Datadog
    if ! send_log_to_datadog "$LOG_DATA"; then
        /bin/echo "$LOG_DATA" >> "$CACHE_FILE"
    fi
else
    /bin/echo "No network. Caching log..."
    /bin/echo "$LOG_DATA" >> "$CACHE_FILE"
fi

exit 0
