#!/bin/bash


PRIVATE_HOSTS=("private-1" "private-2")


# MySQL database configuration
DB_USER="reboot"
DB_PASS="Reboot_123"
DB_NAME="reboot"

# Loop through each private host
for HOST in "${PRIVATE_HOSTS[@]}"; do
  # Get the last reboot information from the host
  LAST_REBOOT=$(ssh "$HOST" 'who -b')

  # Extract the hostname and last reboot date
  HOSTNAME="$HOST"
  REBOOT_DATE=$(echo "$LAST_REBOOT" | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}')

  # Insert the data into the MySQL database
  mysql -u"$DB_USER" -p"$DB_PASS" -e "INSERT INTO reboot_data (hostname, last_reboot_date) VALUES ('$HOSTNAME', '$REBOOT_DATE')" "$DB_NAME"

  # Print the result
  echo "Last reboot on $HOSTNAME: $REBOOT_DATE"
done
