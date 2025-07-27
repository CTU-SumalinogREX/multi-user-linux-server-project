#!/bin/bash

LOG_DIR="/var/log/monitoring_logs"
LOG_FILE="${LOG_DIR}/cpu_monitoring.log"

WARNING_THRESHOLD=80              		# Threshold for the warning message (Used for CPU)
CRITICAL_THRESHOLD=90            		# Critical Range (Used for CPU)

sudo mkdir -p "$LOG_DIR"
sudo touch "$LOG_FILE"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S") 		# Prints timestamp in "YYYY-MM-DD H:M:S" format


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


echo "$TIMESTAMP - $STATUS - CPU Usage: ${CPU_USAGE_ROUND}%" | sudo tee -a "$LOG_FILE" > /dev/null
exit $EXIT_CODE
