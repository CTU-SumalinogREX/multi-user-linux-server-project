#!/bin/bash

LOG_DIR="/var/log/monitoring_logs"
LOG_FILE="${LOG_DIR}/mem_monitoring.log"

WARNING_THRESHOLD=80             		 # Threshold for the warning message (Used for Memory)
CRITICAL_THRESHOLD=90            		 # Critical Range (Used for Memory)

sudo mkdir -p "$LOG_DIR"
sudo touch "$LOG_FILE"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")		# Get the current timestamp

# Calculates memory utilization percentage
# This computes ((Total - Available) / Total) * 100.
MEM_UTIL_FLOAT=$(free -m | awk '/Mem:/ {printf "%.2f\n", (($2 - $7) / $2) * 100}')

# Convert to integer percentage for comparison
MEM_UTIL_INT=$(printf "%.0f\n" "$MEM_UTIL_FLOAT")

# Determine the status based on the specified threshold
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
echo "$TIMESTAMP - $STATUS - Mem Usage: ${MEM_UTIL_INT}%" | sudo tee -a "$LOG_FILE" > /dev/null

# Exit with the determined code (useful for external monitoring systems)
exit $EXIT_CODE
