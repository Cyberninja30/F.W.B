# F.W.B: AutoFirewall - Automated Captive Portal Login & Session Maintenance

### Introduction

AutoFirewall is a cross-platform Bash script designed to automate the login process for captive portals, such as those commonly used in college networks. The script keeps your session alive by continuously sending keep-alive requests. It is designed to run in the background and supports dynamic network detection, credential storage, VPN detection, and retry mechanisms for failed login attempts.

### Key Features

Dynamic Network Detection: Automatically detects if you're connected to a specific Wi-Fi network (e.g., your college's network) and runs only on that network.
Secure Credential Storage: Utilizes system keyring for secure username and password retrieval on Linux, macOS, and Windows platforms.
VPN Detection: Automatically stops execution if a VPN is detected, ensuring the script does not run when you're connected to a non-college network.
Retry Mechanism: Implements an exponential backoff for retrying failed login or keep-alive requests, increasing reliability.
Cross-Platform Compatibility: Works on Linux, macOS, and Windows with platform-specific adaptations for secure credential management.
Background Keep-Alive: Sends keep-alive requests in the background to maintain the session without interrupting other processes.
Structured Logging and Notifications: Logs events with timestamps and sends notifications for critical issues (e.g., failed login, network disconnection).

### Requirements

## Linux
NetworkManager for network detection (nmcli)
libsecret for secure credential storage (secret-tool)
curl for handling HTTP requests
notify-send for notifications

## macOS
scutil for network information and VPN detection
security for secure credential storage
curl for handling HTTP requests
osascript for notifications (substitute for notify-send)

## Windows
PowerShell Secret Management for secure credential storage
curl for handling HTTP requests
PowerShell for notifications (or install notify-send equivalent)

### Installation

## Clone the Repository
git clone https://github.com/yourusername/autofirewall.git
cd autofirewall

## Set Up Secure Credentials

## For Linux: Use secret-tool to store your credentials.

secret-tool store --label="AutoFirewall Username" service autofirewall username
secret-tool store --label="AutoFirewall Password" service autofirewall password

## For macOS: Use the security command to store your credentials.

security add-generic-password -a username -s autofirewall -w "your_username"
security add-generic-password -a password -s autofirewall -w "your_password"

## For Windows: Store credentials using PowerShell Secret Management.

Set-Secret -Name autofirewall_username -Secret "your_username"
Set-Secret -Name autofirewall_password -Secret "your_password"

## Make the Script Executable
bash
Copy code
chmod +x autofirewall.sh

## Configure the Script
Edit the script to specify your college network's SSID:
ssid="Your_College_SSID"
Modify the loginURL if necessary:
loginURL="http://172.15.15.1:1000/login?0263b3a631633500"

### Usage

## Running the Script

Simply run the script in the background once you are connected to your college Wi-Fi network:
./autofirewall.sh &

### Script Functionality

The script will:

1.Automatically detect your network, check the SSID, and log in using the credentials stored securely in your system's keyring.
2.Send keep-alive requests every 5 minutes to maintain your session.
3.Log the process and send notifications if critical issues arise.

## Stopping the Script

To stop the script, you can find its process ID and kill it:

ps aux | grep autofirewall.sh
kill <process_id>

### Scheduling the Script to Run at Login

## On Linux
Use crontab to add the script to your startup:

bash
Copy code
crontab -e
Add the following line:
@reboot /path/to/autofirewall.sh &

## On macOS
Use Automator or add the script to Login Items in System Preferences > Users & Groups.

## On Windows
Use Task Scheduler to schedule the script to run at login.

### Logs and Notifications
The script logs all actions, including successful logins, network detection, and failures, in the log file located at ~/autofirewall.log. You will receive desktop notifications for critical issues such as network disconnection or failed login attempts.

### Testing
## SSID Detection
Connect to a non-college network and verify that the script exits gracefully.
Connect to the college Wi-Fi and ensure that the login is automated.

## Login & Keep-Alive
Temporarily disable the captive portal or change the login credentials to test the retry mechanism.

## VPN Detection
Enable a VPN connection and verify that the script exits without logging in.

## Log File
Check the log file (~/autofirewall.log) for any issues or debug information.

### Troubleshooting

## Login Fails
Check the log file for detailed error messages. Ensure that the loginURL is correct and that the network is reachable.

## VPN Detection
If you are using a non-standard VPN client, the detection might not work. You may need to modify the script to check for your specific VPN setup.

## Credentials Not Found
Ensure that your system keyring or secrets management tool has the correct entries (username and password) under the service name autofirewall.

### Contributing
If you find any issues or want to add new features, feel free to submit a pull request or open an issue on GitHub.

### License
This project is licensed under the MIT License. See the LICENSE file for more details.
