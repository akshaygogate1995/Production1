#!/bin/bash

# Function to print memory usage information
function check_memory_usage {
  free -h
}

# Function to check top memory-consuming processes
function check_top_processes {
  top -b -n 1 | head -n 20
}

# Function to check processes using swap space
function check_swap_processes {
  ps -eo pid,cmd,%mem,%cpu --sort=-%mem | head -n 20
}

# List of servers to check
SERVERS=("private-1" "private-2")

# MySQL database configuration
DB_USER="memory"
DB_PASS="Memory_123"
DB_NAME="memory"

# Loop through each server and run memory checks
for HOST in "${SERVERS[@]}"; do
  # Get the memory usage data
  MEMORY_USAGE=$(ssh "$HOST" "$(typeset -f check_memory_usage); check_memory_usage")

  # Get the top memory-consuming processes data
  TOP_PROCESSES=$(ssh "$HOST" "$(typeset -f check_top_processes); check_top_processes")

  # Get the processes using swap space data
  SWAP_PROCESSES=$(ssh "$HOST" "$(typeset -f check_swap_processes); check_swap_processes")

  # Insert the data into the MySQL database
  mysql -u"$DB_USER" -p"$DB_PASS" -e "INSERT INTO memory (hostname, check_memory_usage, check_top_processes, check_swap_processes) VALUES ('$HOST', '$MEMORY_USAGE', '$TOP_PROCESSES', '$SWAP_PROCESSES')" "$DB_NAME"
done
