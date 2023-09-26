#!/bin/bash

# Define the IP addresses or hostnames of the machines
machine1="private-1"
machine2="private-2"

# Function to check password change date and send email notification
check_password_change() {
    local machine="$1"
    local username="admin_user"
    
    # SSH into the machine and check password change date
    last_password_change_date=$(ssh "$machine" "sudo chage -l $username | grep 'Last password change' | awk '{print \$NF}'")
    
    # Calculate the difference in days
    current_date=$(date +%s)
    last_change_date_seconds=$(date -d "$last_password_change_date" +%s)
    days_since_last_change=$(( (current_date - last_change_date_seconds) / 86400 ))
    
    if [ "$days_since_last_change" -ge 30 ]; then
        # Password change is required
        echo "Password for '$username' on $machine was last changed $days_since_last_change days ago."
        
        # Sending email notification (replace with your email sending command)
        echo "Sending email notification to admin@example.com."
        # Example: mail -s "Password Change Required" admin@example.com <<< "Please change your password on $machine."
    fi
}

# Check password change on machine1
check_password_change "$machine1"

# Check password change on machine2
check_password_change "$machine2
