#!/bin/bash
### Check_firewall_and_signing_status.sh
## Description  : This script checks the firewall settings and signing status for allowed applications and exports the results to a CSV file.
## Author       : Rohi Rikman
## Version      : 1.0
## Date         : 2023-05-18
## usege:       : ./Check_firewall_and_signing_status.sh
## Part of      : macOS/macOS complince automation Scripts  
logDir="/Library/Logs/Microsoft/IntuneScripts"
logFile="$logDir/Check_firewall_and_signing_status.log"
csvFile="./app_firewall_and_signing_status.csv"
Time_of_Day="$(date +'%H:%M:%S')"

# Function to log messages
log() {
    local message="$1"
    if [ ! -d "$logDir" ]; then
        echo "${Time_of_Day} | [INFO] Creating [$logDir] to store logs"
        mkdir -p "$logDir"
    fi
    echo "${Time_of_Day} | [INFO] $message" >> "$logFile"
}

# Function to get allowed applications from the firewall and extract bundle IDs
get_allowed_apps() {
    log "Fetching allowed applications from the firewall"
    echo "Fetching allowed applications from the firewall"
    # Get the list of allowed applications
    allowed_apps=$(defaults read /Library/Preferences/com.apple.alf.plist applications)
    
    # Extract bundle IDs
    bundle_ids=$(echo "$allowed_apps" | grep -o 'bundleid = ".*";' | sed 's/bundleid = "\(.*\)";/\1/')
    
    # Check if there are no allowed applications
    if [[ -z "$bundle_ids" ]]; then
        log "No applications are allowed through the firewall. Exiting."
        exit 0
    fi
    
    echo "$bundle_ids"

}

# Function to check the signing status of apps using bundle IDs and export to CSV
check_signing_status() {
    local bundle_ids="$1"
    log "Checking signing status for apps using bundle IDs"
    echo "Checking signing status"
    # Initialize CSV file with header if it doesn't exist
    if [ ! -f "$csvFile" ]; then
        echo "Bundle ID,Signing Status" > "$csvFile"
    fi
    
    # Iterate over bundle IDs and find the app paths
    for bundle_id in $bundle_ids; do
        echo "Checking signing status for app with bundle ID: $bundle_id"
        # Find the application path using mdfind
        app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_id'")
        
        if [[ -z "$app_path" ]]; then
            log "Application with bundle ID $bundle_id not found"
            continue
        fi
        
        log "Checking application with bundle ID $bundle_id at $app_path"
        echo "Checking application with bundle ID $bundle_id at $app_path"
        # Check the signing status
        spctl_output=$(spctl --assess --verbose "$app_path" 2>&1)
        
        if [[ $spctl_output == *"accepted"* ]]; then
            signing_status="Signed"
            log "App is signed by Apple ID: $bundle_id ($app_path)"
            echo "App is signed by Apple ID: $bundle_id ($app_path)"
        elif [[ $spctl_output == *"rejected"* ]]; then
            signing_status="Not Signed"
            log "App not signed by Apple ID: $bundle_id ($app_path)"
            echo "App not signed by Apple ID: $bundle_id ($app_path)"
        else
            signing_status="Unknown"
            log "Signing status unknown for app with bundle ID: $bundle_id ($app_path)"
            echo "Signing status unknown for app with bundle ID: $bundle_id ($app_path)"
        fi
        
        # Append bundle ID and signing status to CSV file
        echo "\"$bundle_id\",\"$signing_status\"" >> "$csvFile"
    done
    
    log "Finished checking signing status for apps using bundle IDs"
}



### Main script ###
log "Start checking firewall Settings"
echo "Checking firewall Settings"

# Fetch allowed applications and extract bundle IDs
bundle_ids=$(get_allowed_apps)

log "Start checking signing status for the allowed apps"
echo "Checking the signing status for the allowed apps"
# Check signing status for the extracted bundle IDs and export to CSV
check_signing_status "$bundle_ids"

log "Script finished"
echo "Script finished"
