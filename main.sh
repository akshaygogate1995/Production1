#!/bin/bash

# Name - Akshay Gogate
# EMail - akshay.gogate@hotmail.com
# Date - 21/09/2023
# Script to check admin password change date on each golden servers and notifying them via Email
# Requirements - 1. Does Jump Server / Bastion has access to all the Golden Servers
#                2. Need an Excel file which contains all the IPs of Golden servers

#Excel file has all the IPs of golden servers
excel_file="machine_ips.xlsx"

#Outut file has all the changes made
output_excel_file="output.xlsx"

# Which user to check password
username="admin"

# Change this to your email address
email="akshay.gogate@hotmail.com"  

# Function to check password change date 
check_password_change_date() {
    machine=$1
    password_change_date=$(ssh "$machine" "chage -l $username | grep 'Last password change' | awk -F: '{print \$2}' | tr -d ' '")
    current_date=$(date +%s)
    password_change_epoch=$(date -d "$password_change_date" +%s)
    days_since_change=$(( (current_date - password_change_epoch) / (60*60*24) ))
    
    if [ $days_since_change -ge 30 ]; then
        status="Needs to Change the Password"
    else
        status="OK"
    fi


    # Write the result to a temporary file
    echo "$machine,$status" >> temp_output.csv

# Created a Function to send email 
send_email() {
    machine=$1
    days_since_change=$2
    subject="Password Change Alert"
    message="The password for user '$username' on '$machine' was last changed $days_since_change days ago."
    echo "$message" | mail -s "$subject" "$email"
}

# Read Golden Server IPs from Excel file and use loop in it
while IFS=, read -r machine; do
    check_password_change_date "$machine"
done < <(xlsx2csv "$excel_file" | tail -n +2)


# Conversion of temporary created CSV to Excel file which has all changes recorded
csv2xlsx() {
    local input_file="$1"
    local output_file="$2"
    local temp_csv_file="$(mktemp)"

    mv "$input_file" "$temp_csv_file"
    
 # Convert using ssconvert from csv file to excel file   
    ssconvert "$temp_csv_file" "$output_file"
    rm "$temp_csv_file"
}

csv2xlsx "temp_output.csv" "$output_excel_file"
