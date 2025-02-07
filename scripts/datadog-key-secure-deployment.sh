#!/bin/zsh

# Ensure an API key is provided
if [[ -z "$4" ]]; then
    echo "Error: No API key provided."
    exit 1
fi

# Store the API key in Keychain
security add-generic-password -s "DatadogAPI" -a "DatadogUploader" -w "$4" -U

# Verify the API key is stored
if security find-generic-password -s "DatadogAPI" -a "DatadogUploader" -w >/dev/null 2>&1; then
    echo "Datadog API key successfully added to Keychain."
else
    echo "Error: Failed to store Datadog API key in Keychain."
    exit 1
fi

exit 0