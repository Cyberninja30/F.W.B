#!/bin/bash

# Automatically fetch network details dynamically
loginURL="http://172.15.15.1:1000/login?0263b3a631633500"

# Securely retrieve credentials from keyring (or use your preferred secure method)
getCredentials() {
	case "$(uname)" in
		Linux*)
			username=$(secret-tool lookup service autofirewall username)
			password=$(secret-tool lookup service autofirewall password)
			;;
		Darwin*)
			# For macOS, you can use `security` or pass command line tools for credential storage
			username=$(security find-generic-password -w -s autofirewall -a username)
			password=$(security find-generic-password -w -s autofirewall -a password)
			;;
		MINGW*|CYGWIN*|MSYS*)
			# For Windows, consider using Windows Credential Store or PowerShell secrets
			username=$(powershell.exe -Command "Get-Secret -Name autofirewall_username")
			password=$(powershell.exe -Command "Get-Secret -Name autofirewall_password")
			;;
		*)
			echo "Unsupported OS detected."
			exit 1
			;;
	esac
}

# Log file location
logFile="$HOME/autofirewall.log"

# Function to log and send notifications
logAndNotify() {
	local message="$1"
	local urgency="$2"
	echo "$(date): $message" >> "$logFile"
	if [[ "$urgency" == "critical" ]]; then
		notify-send -u "$urgency" "AutoFirewall" "$message"
	fi
}

# Function to detect VPN (Linux & macOS only)
detectVPN() {
	case "$(uname)" in
		Linux*)
			vpnStatus=$(nmcli con show --active | grep vpn)
			;;
		Darwin*)
			vpnStatus=$(scutil --nc status)
			;;
	esac
	
	if [[ ! -z "$vpnStatus" ]]; then
		logAndNotify "VPN detected. AutoFirewall will not run." "critical"
		exit 0
	fi
}

# Function to get network information dynamically
getNetworkInfo() {
	# Get the currently connected WiFi SSID
	ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
	
	# Check if connected to a specified network
	if [ -z "$ssid" ]; then
		logAndNotify "Error: Not connected to any WiFi network." "critical"
		exit 1
	fi
	
	# Get IP address and gateway details
	ipAddress=$(nmcli -g ip4.address dev show | grep -oP '^\d{1,3}(\.\d{1,3}){3}')
	gateway=$(nmcli -g ip4.gateway dev show)
	
	logAndNotify "Connected to SSID: $ssid (IP: $ipAddress, Gateway: $gateway)" "normal"

	# Only proceed if connected to the specific network (e.g., college WiFi)
	if [[ "$ssid" != "Your_College_SSID" ]]; then
		logAndNotify "Not connected to the specified network (college). Exiting." "normal"
		exit 0
	fi
}

# Function to perform login and get keep-alive URL
doLoginAndGetKeepAlive() {
	# Log startup
	logAndNotify "Starting AutoFirewall login..." "normal"
	
	# Get network information
	getNetworkInfo
	
	# 1. Retrieve 'magic' token from the Captive Portal
	magic=$(curl -s "$loginURL" --insecure | grep -oP 'name="magic" value="\K[^"]+')
	
	if [ -z "$magic" ]; then
		logAndNotify "Error: Could not retrieve 'magic' token." "critical"
		return 1
	fi
	
	logAndNotify "Magic token retrieved: $magic" "normal"
	
	# 2. Perform login
	loginResponse=$(curl -i -s -X POST "http://172.15.15.1:1000/" \
		-H 'Content-Type: application/x-www-form-urlencoded' \
		--data-urlencode "4Tredir=$loginURL" \
		--data-urlencode "magic=$magic" \
		--data-urlencode "username=$username" \
		--data-urlencode "password=$password" \
		--insecure)

	# 3. Extract keepalive URL from the login response
	keepAliveURL=$(echo "$loginResponse" | grep -oP 'Location: \K[^ ]+')
	
	if [ -z "$keepAliveURL" ]; then
		logAndNotify "Error: Could not retrieve keepalive URL." "critical"
		return 1
	fi
	
	cleanedURL=$(echo "$keepAliveURL" | tr -d '\r\n')
	logAndNotify "Keepalive URL retrieved: $cleanedURL" "normal"
	
	echo "$cleanedURL"
}

# Function to handle retries with exponential backoff
retryWithBackoff() {
	local retries=5
	local waitTime=2
	local success=0
	
	for ((i=0; i<$retries; i++)); do
		"$@" && success=1 && break || logAndNotify "Attempt $(($i+1)) failed. Retrying in $waitTime seconds..." "critical"
		sleep $waitTime
		waitTime=$(($waitTime * 2))
	done
	
	if [ $success -ne 1 ]; then
		logAndNotify "Max retries reached. Exiting..." "critical"
		exit 1
	fi
}

# Main execution starts here
getCredentials
detectVPN

# Login and get the keep-alive URL
cleanedURL=$(retryWithBackoff doLoginAndGetKeepAlive)

# Keep the session alive in the background
while true; do
	httpStatus=$(curl -s -o /dev/null -w "%{http_code}" "$cleanedURL")
	
	if [[ $httpStatus -ge 200 && $httpStatus -lt 400 ]]; then
		logAndNotify "Session kept alive. HTTP status: $httpStatus" "normal"
	else
		logAndNotify "Keepalive failed. Re-attempting login..." "critical"
		retryWithBackoff doLoginAndGetKeepAlive
	fi
	
	# Sleep for 5 minutes before next keepalive
	sleep 300 &
	wait $!
done &
