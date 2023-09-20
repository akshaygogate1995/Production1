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

    # SSH into the target machine and check password change date
    last_change=$(ssh "$target_machine" "echo $admin_password | sudo -S chage -l $admin_user | grep 'Last password change' | cut -d ':' -f 2-")

    # Calculate the password change date in seconds since epoch
    last_change_epoch=$(date -d "$last_change" +%s)

    # Calculate 30 days ago in seconds since epoch
    thirty_days_ago=$(( $(date +%s) - 30 * 24 * 60 * 60 ))

    # Compare the dates and send an email if necessary
    if [ "$last_change_epoch" -lt "$thirty_days_ago" ]; then
        echo "Password on $target_machine for user $admin_user last changed more than 30 days ago."
        # You can send an email here (replace the placeholder with your email-sending logic)
        # For example, you can use the 'mail' command or a mailer script.
        # mail -s "Password Change Reminder" "$admin_email" <<< "Password on $target_machine for user $admin_user last changed more than 30 days ago."
    else
        echo "Password on $target_machine for user $admin_user changed within the last 30 days."
    fi
}

# Loop through the CSV files and check password change
while IFS=, read -r machine_ip; do
    IFS=, read -r admin_user admin_password < <(grep "$machine_ip" "$credentials_csv_file")
    if [ -n "$admin_user" ] && [ -n "$admin_password" ]; then
        echo "Checking $machine_ip..."
        check_password_change "$machine_ip" "$admin_user" "$admin_password"
    else
        echo "Credentials not found for $machine_ip."
    fi
done < "$ip_csv_file"
