#!/bin/bash

# Function to send email
send_email() {
    # Implement your email sending logic here
    # Example: mail -s "Password Change Reminder" user@example.com <<< "Your password needs to be changed."
    echo "Sending email to $1"
}

# Initialize counters for statistics
total_ips=0
password_change_needed=0
password_change_not_needed=0

# Parse CSV file with VM IPs
csv_file="vm_ips.csv"

# MySQL database credentials
db_user="mysqladmin"
db_password="password"
db_name="your_database"

while IFS=',' read -r vm_ip; do
    # SSH from the bastion server to the target VM
    ssh admin@$vm_ip << EOF
        # Check when the password was last changed for the 'admin' user
        last_password_change_date=$(chage -l admin | grep "Last password change" | awk '{print $NF}')
        
        # Calculate the difference in days
        current_date=$(date +%s)
        last_change_date_seconds=$(date -d "$last_password_change_date" +%s)
        days_since_last_change=$(( (current_date - last_change_date_seconds) / 86400 ))
        
        if [ "$days_since_last_change" -ge 30 ]; then
            # Password change is required
            echo "Password for 'admin' user on $vm_ip was last changed $days_since_last_change days ago."
            echo "Sending a notification email."
            send_email "admin@example.com"
            
            # Increment the password_change_needed counter
            ((password_change_needed++))
        else
            # Increment the password_change_not_needed counter
            ((password_change_not_needed++))
        fi
EOF

    # Increment the total_ips counter
    ((total_ips++))
done < "$csv_file"

# Log the statistics into the MySQL database
mysql -u "$db_user" -p"$db_password" "$db_name" << MYSQL_STATS
    INSERT INTO password_change_stats (total_ips, change_needed, change_not_needed)
    VALUES ($total_ips, $password_change_needed, $password_change_not_needed);
MYSQL_STATS
