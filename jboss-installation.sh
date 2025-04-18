#!/bin/bash

# Prompt for passphrase to decrypt
read -s -p "Enter decryption passphrase: " ENTERED_PASS
echo

# Decrypt secrets file
gpg --quiet --batch --yes --decrypt --passphrase "$ENTERED_PASS" secrets.env.gpg > temp.env 2>/dev/null

# Check if decryption was successful
if [[ $? -ne 0 ]]; then
    echo "Decryption failed. Incorrect passphrase or file missing."
    exit 1
fi

# Source variables
source ./temp.env

# Delete temporary env file immediately
rm -f temp.env

# Display masked output
echo "JBOSS_HOME=********"
echo "USERNAME=********"
echo "PASSWORD=********"
echo "SERVER_IP=********"


# Step 1: Extract the tar archive
echo "Extracting JBoss tar archive..."
tar -xf /tmp/jboss-eap-8.0.0.zip.tar -C /tmp >/dev/null

# Step 1.1: Unzip the resulting zip file
echo "Unzipping JBoss zip archive..."
unzip -q /tmp/jboss-eap-8.0.0.zip -d /tmp

# Step 2: Move to /opt
mv /tmp/jboss-eap-8.0 /opt/

# Step 3: Add management user
echo "Creating management user..."
$JBOSS_HOME/bin/add-user.sh manager admin123 --silent

# Step 4: Backup standalone.xml
cp $JBOSS_HOME/standalone/configuration/standalone.xml $JBOSS_HOME/standalone/configuration/standalone.xml.bak
echo "Backup created: standalone.xml.bak"

# Step 5: Start JBoss in the background (optional headless)
echo "Starting JBoss..."
nohup $JBOSS_HOME/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 > /dev/null 2>&1 &


# Open port 8080 and 9990 on the firewall
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=9990/tcp --permanent
firewall-cmd --reload

# Wait a few seconds for JBoss to come up
sleep 15

# Step 6: Check if JBoss is running
echo "Checking JBoss status on $SERVER_IP:8080..."
curl -s http://$SERVER_IP:8080 > /dev/null

if [[ $? -eq 0 ]]; then
    echo "JBoss is running and accessible."
else
    echo "Failed to reach JBoss. Check logs or IP."
fi
echo "&&&&&&&&&&&&&&&  CopyRight: Mylestechsolutions  &&&&&&&&&&&&&&&"



# Stop JBoss EAP gracefully
#/opt/jboss-eap-8.0/bin/jboss-cli.sh --connect --controller=10.10.8.228:9990 --command=:shutdown

#echo "JBoss EAP stopped gracefully."



