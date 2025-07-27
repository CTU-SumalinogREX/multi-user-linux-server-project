Linux System Administration Project: Secure Multi-User Server
Project Overview
This repository documents the setup and configuration of a secure, multi-user Linux server environment. The project simulates real-world system administration tasks, utilizing CentOS Stream 9 as the server and Ubuntu as the client. It covers essential skills in user management, SSH security, file permissions, network firewalling, web server deployment, and system monitoring.

Project Duration: 2-3 days
Team Size: 2-3 members

Objectives
Configure a CentOS 9 server for multi-user access.

Establish secure SSH access from an Ubuntu client.

Implement robust user and group management policies.

Configure file permissions and shared directories for secure collaboration.

Set up firewalld rules to control network traffic.

Deploy and configure a basic web server.

Create automated monitoring scripts for CPU and memory usage, with logging and status reporting.

Implemented Tasks and Detailed Configuration
1. User and Group Management
Objective: Create necessary user accounts and groups, and assign appropriate memberships.

Users Created:

adminuser (Password: @dmin!23)

devuser (Password: d3vuser!23)

guestuser (Password: gu3st!23)

Group Created:

developers

Assignments:

devuser assigned to the developers group.

adminuser assigned to the wheel (sudo) group for administrative privileges.

Commands Executed (on CentOS Server):

# Create users
sudo useradd adminuser
sudo useradd devuser
sudo useradd guestuser

# Set passwords
echo "@dmin!23" | sudo passwd --stdin adminuser
echo "d3vuser!23" | sudo passwd --stdin devuser
echo "gu3st!23" | sudo passwd --stdin guestuser

# Create group
sudo groupadd developers

# Assign devuser to developers group
sudo usermod -aG developers devuser

# Assign adminuser to wheel (sudo) group
sudo usermod -aG wheel adminuser

# Verify user and group assignments
id adminuser
id devuser
id guestuser

2. Password Policies
Objective: Enforce password expiration and warning periods for all users.

Policies:

Passwords expire every 60 days.

A warning is issued 14 days before expiration.

Commands Executed (on CentOS Server):

# Set password policy for all users
sudo chage -M 60 -W 14 adminuser
sudo chage -M 60 -W 14 devuser
sudo chage -M 60 -W 14 guestuser

# Verify password policies
sudo chage -l adminuser
sudo chage -l devuser
sudo chage -l guestuser

3. Shared Directory Configuration
Objective: Create a shared directory for the developers group with appropriate permissions and restricted access for guestuser.

Directory: /srv/devshare
Ownership: root:developers
Permissions:

Group developers: Read/Write

setgid enabled (new files/directories created inherit group ownership)

guestuser: Read-only access via ACLs

Commands Executed (on CentOS Server):

# Create the shared directory
sudo mkdir -p /srv/devshare

# Set ownership to root:developers
sudo chown root:developers /srv/devshare

# Set standard permissions (group read/write, setgid enabled)
sudo chmod 2770 /srv/devshare

# Install ACL package (if not already installed)
sudo dnf install -y acl

# Grant guestuser read-only access using ACL
sudo setfacl -m u:guestuser:r-x /srv/devshare

# Verify permissions and ACLs
ls -ld /srv/devshare
getfacl /srv/devshare

4. SSH Configuration
Objective: Set up secure SSH key-based login from the Ubuntu client and disable password login for adminuser.

Configuration:

SSH key-based login for adminuser and devuser from Ubuntu client.

Password login disabled for adminuser on the CentOS server.

Commands Executed:

On Ubuntu Client (for each user: ubuntu_admin, ubuntu_dev):

# Generate SSH key pair (press Enter for defaults, leave passphrase empty for simplicity in this project)
ssh-keygen -t rsa

# Copy public key to CentOS server (replace 192.168.1.33 with your CentOS server's IP)
# For adminuser:
ssh-copy-id adminuser@192.168.1.33
# For devuser:
ssh-copy-id devuser@192.168.1.33

On CentOS Server:

# Edit SSH daemon configuration
sudo vim /etc/ssh/sshd_config

# Add/Modify the following lines to disable password authentication for adminuser:
# (Ensure PasswordAuthentication yes is commented out or set to no globally if not using Match block)
# ...
# PasswordAuthentication no  # Set this globally if you want to disable for all users by default
# ...
Match User adminuser
    PasswordAuthentication no
# ...

# Reload SSH service to apply changes
sudo systemctl reload sshd

5. Firewall and Network Configuration
Objective: Ensure network connectivity and secure the CentOS server's incoming traffic.

Configuration:

CentOS server and Ubuntu client must be on the same network.

CentOS server allows only ports 22 (SSH) and 80 (HTTP). All other incoming traffic is denied by default.

Commands Executed (on CentOS Server):

# Check firewalld status
sudo systemctl status firewalld

# Add permanent rules for SSH (port 22) and HTTP (port 80)
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=80/tcp

# Reload firewalld to apply permanent changes
sudo firewall-cmd --reload

# Verify active firewall rules
sudo firewall-cmd --list-all

6. Web Server Deployment
Objective: Install a web server and ensure it's accessible from the Ubuntu client.

Server: Apache HTTP Server (httpd)

Commands Executed (on CentOS Server):

# Install Apache HTTP Server
sudo dnf install -y httpd

# Create a simple custom HTML page in the web root
echo "<h1>Welcome to CentOS Server!</h1><p>This is your secure multi-user environment.</p>" | sudo tee /var/www/html/index.html

# Start and enable the httpd service to run on boot
sudo systemctl enable --now httpd

# Verify httpd service status
sudo systemctl status httpd

Verification (on Ubuntu Client):

# Access the web server via curl (replace 192.168.1.33 with your CentOS server's IP)
curl http://192.168.1.33:80
# Expected: You should see the HTML content of your custom index.html page.

7. System Monitoring and Logging
Objective: Create BASH scripts to monitor CPU and memory utilization, log their status, and run periodically via cron.

Requirements:

Two BASH scripts: cpu_monitoring.sh and mem_monitoring.sh.

Output format: "<timestamp> - <STATUS> - <% utilization>"

Status thresholds:

OK: usage < 80%

WARNING: usage ≥ 80% and < 90%

CRITICAL: usage ≥ 90%

Exit codes: 0 for OK, 1 for WARNING, 2 for CRITICAL.

Scripts run every 10 minutes via cron.

Logs output to files within /var/log/monitoring_logs/.

Commands Executed (on CentOS Server):

# Create the monitoring scripts directory
sudo mkdir -p /var/log/monitoring_logs

CPU Utilization Monitor Script (scripts/cpu_monitoring.sh)
#!/bin/bash

# Configuration for CPU Monitor
LOG_DIR="/var/log/monitoring_logs"
LOG_FILE="${LOG_DIR}/cpu_monitoring.log"
WARNING_THRESHOLD=80              # Threshold for the warning message (Used for CPU)
CRITICAL_THRESHOLD=90             # Critical Range (Used for CPU)

# Ensure log directory exists
mkdir -p "$LOG_DIR"
# Ensure log file exists and is writable
touch "$LOG_FILE"

# Get current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S") # Prints timestamp in "YYYY-MM-DD H:M:S" format

# Parses the idle/free cpu then subtracts it from 100 to calculate the usage
# CPU_USAGE will hold the floating-point result (e.g., 14.3)
CPU_USAGE=$(echo "100 - $(top -bn1 | grep '%Cpu(s):' | cut -d, -f 4 | awk '{print $1}')" | bc)

# Rounds off the CPU_USAGE output for it to work with arithmetic comparison
CPU_USAGE_ROUND=$(printf "%.0f\n" "$CPU_USAGE")

# Conditional to determine the status of CPU
if (( CPU_USAGE_ROUND < WARNING_THRESHOLD )); then
    STATUS="OK"
    EXIT_CODE=0
elif (( CPU_USAGE_ROUND >= WARNING_THRESHOLD && CPU_USAGE_ROUND < CRITICAL_THRESHOLD )); then
    STATUS="WARNING"
    EXIT_CODE=1
else
    STATUS="CRITICAL"
    EXIT_CODE=2
fi

# Log the result to the specified file
# The '%' sign is appended here for display in the log.
echo "$TIMESTAMP - $STATUS - CPU Usage: ${CPU_USAGE_ROUND}%" | sudo tee -a "$LOG_FILE" > /dev/null

# Exit with the determined code (useful for external monitoring systems)
exit $EXIT_CODE

Memory Utilization Monitor Script (scripts/mem_monitoring.sh)
#!/bin/bash

# Configuration for Memory Monitor
LOG_DIR="/var/log/monitoring_logs"
LOG_FILE="${LOG_DIR}/mem_monitoring.log" # Consistent logging path
WARNING_THRESHOLD=80              # Threshold for the warning message (Used for Memory)
CRITICAL_THRESHOLD=90             # Critical Range (Used for Memory)

# Ensure log directory exists
mkdir -p "$LOG_DIR"
# Ensure log file exists and is writable
touch "$LOG_FILE"

# Get current timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Calculates memory utilization percentage directly using free -m and awk.
# It computes ((Total - Available) / Total) * 100.
MEM_UTIL_FLOAT=$(free -m | awk '/Mem:/ {printf "%.2f\n", (($2 - $7) / $2) * 100}')

# Convert to integer percentage for comparison and logging
MEM_UTIL_INT=$(printf "%.0f\n" "$MEM_UTIL_FLOAT")

# Determine the status based on thresholds
if (( MEM_UTIL_INT < WARNING_THRESHOLD )); then
    STATUS="OK"
    EXIT_CODE=0
elif (( MEM_UTIL_INT >= WARNING_THRESHOLD && MEM_UTIL_INT < CRITICAL_THRESHOLD )); then
    STATUS="WARNING"
    EXIT_CODE=1
else
    STATUS="CRITICAL"
    EXIT_CODE=2
fi

# Log the result to the specified file
# The '%' sign is appended here for display in the log.
echo "$TIMESTAMP - $STATUS - Mem Usage: ${MEM_UTIL_INT}%" | sudo tee -a "$LOG_FILE" > /dev/null

# Exit with the determined code (useful for external monitoring systems)
exit $EXIT_CODE

Script Setup Commands (on CentOS Server):

# Create/Edit CPU monitoring script
sudo vi /usr/local/bin/cpu_monitoring.sh
# Paste the CPU script content above. Save and exit (:wq).

# Make CPU script executable
sudo chmod +x /usr/local/bin/cpu_monitoring.sh

# Create/Edit Memory monitoring script
sudo vi /usr/local/bin/mem_monitoring.sh
# Paste the Memory script content above. Save and exit (:wq).

# Make Memory script executable
sudo chmod +x /usr/local/bin/mem_monitoring.sh

# Recommended: Run cleanup to remove hidden characters (e.g., if copied from Windows)
sed -i 's/\r//g; s/\xc2\xa0//g' /usr/local/bin/cpu_monitoring.sh
sed -i 's/\r//g; s/\xc2\xa0//g' /usr/local/bin/mem_monitoring.sh

Cron Job Setup (on CentOS Server):

To run the scripts every 10 minutes, add entries to the root user's crontab:

sudo crontab -e

Add the following lines at the end of the file:

# Run CPU monitoring script every 10 minutes
*/10 * * * * /usr/local/bin/cpu_monitoring.sh

# Run Memory monitoring script every 10 minutes
*/10 * * * * /usr/local/bin/mem_monitoring.sh

Save and exit the crontab editor.

Recommendations and Best Practices (from our discussions)
As your Senior SRE, here are some key recommendations and best practices highlighted during this project that you should consider for future real-world deployments:

Principle of Least Privilege: While running cron jobs as root is simple for system-wide monitoring, in a production environment, consider creating a dedicated, unprivileged user for monitoring tasks. Grant this user only the necessary sudo permissions for specific commands (e.g., tee to log files) via /etc/sudoers.d/ entries. This minimizes the impact if the script is compromised.

Robust Log Management: For long-running systems, implement log rotation (e.g., using logrotate) for your /var/log/monitoring_logs/ files. This prevents log files from growing indefinitely and consuming excessive disk space.

Alerting Integration: For critical systems, monitoring scripts are typically integrated with an alerting system (e.g., email notifications, Slack, PagerDuty). Instead of just logging, the scripts' exit codes could trigger alerts if a WARNING or CRITICAL status is detected.

Centralized Logging: In multi-server environments, consider forwarding logs to a centralized logging solution (e.g., ELK Stack, Splunk, Graylog). This makes it easier to analyze logs across your infrastructure.

Dedicated Monitoring Tools: For more advanced monitoring, tools like Prometheus, Grafana, Nagios, Zabbix, or Datadog offer richer features, historical data analysis, dashboards, and sophisticated alerting capabilities beyond simple Bash scripts.

SSH Key Passphrases: For production SSH keys, always use a strong passphrase. While we skipped it for simplicity in this project, it adds a crucial layer of security. Use ssh-agent to manage passphrases for convenience.

Firewall Zones: firewalld supports zones (e.g., public, internal, trusted). In more complex network setups, using zones can provide more granular control over traffic based on the network interface.

Idempotent Scripts: Strive to make your configuration scripts idempotent, meaning running them multiple times produces the same result without unintended side effects. This simplifies automation and error recovery.

Files in this Repository
README.md: This comprehensive documentation.

scripts/: Contains the BASH monitoring scripts.

cpu_monitoring.sh

mem_monitoring.sh

project-report/: (Optional) If you want to include your original Project.docx or a PDF version of it, place it here. Update the README.md to link to it.

License
This project is licensed under the MIT License. See the LICENSE file for details.
