#!/bin/bash

# Check if required tools are installed
if ! command -v xlsx2csv &> /dev/null; then
    echo "xlsx2csv is not installed. Please install it."
    exit 1
fi

# Paths to Excel files
ip_excel_file="machine_ips.xlsx"
output_excel_file="password_change_log.xlsx"

# Convert Excel file to CSV
ip_csv_file="machine_ips.csv"
xlsx2csv "$ip_excel_file" "$ip_csv_file"

# Function to check password change date
check_password_change() {
    target_machine="$1"
    admin_user="$2"
    admin_email="$3"

    # SSH into the target machine via the bastion host and check password change date
    last_change=$(ssh bastion_user@bastion_host "ssh $admin_user@$target_machine 'chage -l $admin_user | grep \"Last password change\" | cut -d \":\" -f 2-'")

    # Calculate the password change date in seconds since epoch
    last_change_epoch=$(date -d "$last_change" +%s)

    # Calculate 30 days ago in seconds since epoch
    thirty_days_ago=$(( $(date +%s) - 30 * 24 * 60 * 60 ))

    # Calculate days since last change
    days_since_change=$(( (last_change_epoch - thirty_days_ago) / (24 * 60 * 60) ))

    # If the password hasn't been changed within the last 30 days, send a notification
    if [ "$days_since_change" -ge 30 ]; then
        echo "Sending notification to $admin_email for $target_machine..."

        # Send an email to the user to remind them to change their password
        # You can use a command or script to send email based on the user's email address.
        # For example, using the 'mail' command or a mailer script.
        # mail -s "Password Change Reminder" "$admin_email" <<< "Password on $target_machine for user $admin_user last changed more than 30 days ago. Please change it."
        
        # For the sake of this example, we'll just print a reminder.
        echo "Reminder: Please change your password on $target_machine for user $admin_user."

        # Log the result in the output Excel file
        echo "$target_machine,$admin_user,$admin_email,$days_since_change" >> "$output_excel_file"
    else
        echo "No notification sent for $target_machine."
    fi
}

# Create the header row for the Excel log file
echo "IP,Admin User,Admin Email,Days Since Last Change" > "$output_excel_file"

# Loop through the CSV file, check password change, and add data to the Excel log file
while IFS=, read -r target_machine admin_user admin_email; do
    echo "Checking $target_machine..."
    check_password_change "$target_machine" "$admin_user" "$admin_email"
done < "$ip_csv_file"

# Email the Excel log file to a specific email address
# You can use a command or script to send the email. Make sure to configure your email settings.
# For example, using the 'mail' command or a mailer script.
# mail -s "Password Change Log" "recipient@example.com" < "$output_excel_file"

# For the sake of this example, we'll just print a message
echo "Password change log sent to recipient@example.com."
