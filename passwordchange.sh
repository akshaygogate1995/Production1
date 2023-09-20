#!/bin/bash

# Check if required tools are installed
if ! command -v xlsx2csv &> /dev/null; then
    echo "xlsx2csv is not installed. Please install it."
    exit 1
fi

# Paths to Excel files
ip_excel_file="machine_ips.xlsx"
credentials_excel_file="machine_credentials.xlsx"

# Convert Excel files to CSV
ip_csv_file="machine_ips.csv"
credentials_csv_file="machine_credentials.csv"

xlsx2csv "$ip_excel_file" "$ip_csv_file"
xlsx2csv "$credentials_excel_file" "$credentials_csv_file"

# Function to check password change date
check_password_change() {
    target_machine="$1"
    admin_user="$2"
    admin_password="$3"
    admin_email="$4"

    # SSH into the target machine and check password change date
    last_change=$(ssh "$target_machine" "echo $admin_password | sudo -S chage -l $admin_user | grep 'Last password change' | cut -d ':' -f 2-")

    # Calculate the password change date in seconds since epoch
    last_change_epoch=$(date -d "$last_change" +%s)

    # Calculate 30 days ago in seconds since epoch
    thirty_days_ago=$(( $(date +%s) - 30 * 24 * 60 * 60 ))

    # Compare the dates and send an email if necessary
    if [ "$last_change_epoch" -lt "$thirty_days_ago" ]; then
        echo "Password on $target_machine for user $admin_user last changed more than 30 days ago."
        
        # Send an email to the user to remind them to change their password
        # You can use a command or script to send email based on the user's email address.
        # For example, using the 'mail' command or a mailer script.
        # mail -s "Password Change Reminder" "$admin_email" <<< "Password on $target_machine for user $admin_user last changed more than 30 days ago. Please change it."
        
        # For the sake of this example, we'll just print a reminder.
        echo "Reminder: Please change your password on $target_machine for user $admin_user."
    else
        echo "Password on $target_machine for user $admin_user changed within the last 30 days."
    fi
}

# Loop through the CSV files and check password change
while IFS=, read -r machine_ip; do
    IFS=, read -r admin_user admin_password admin_email < <(grep "$machine_ip" "$credentials_csv_file")
    if [ -n "$admin_user" ] && [ -n "$admin_password" ] && [ -n "$admin_email" ]; then
        echo "Checking $machine_ip..."
        check_password_change "$machine_ip" "$admin_user" "$admin_password" "$admin_email"
    else
        echo "Credentials not found for $machine_ip."
    fi
done < "$ip_csv_file"
