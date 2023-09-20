#!/bin/bash

# List of VM hostnames or IP addresses
vms=("vm1.example.com" "vm2.example.com" "vm3.example.com")

# Sysadmin username
sysadmin_user="sysadmin"

# Path to the .pem key file
pem_key="/path/to/your/key.pem"

# Function to check password age
check_password_age() {
    vm=$1

    # Get the password change date from passwd -S command
    password_change_date=$(ssh -i "$pem_key" "$vm" "sudo passwd -S $sysadmin_user | awk '{print \$3}'")

    if [ -z "$password_change_date" ]; then
        echo "Error: Unable to retrieve password change information for $sysadmin_user on $vm."
    else
        echo "Password change date for $sysadmin_user on $vm: $password_change_date"
    fi
}

# Loop through the list of VMs and check password age
for vm in "${vms[@]}"; do
    check_password_age "$vm"
done
