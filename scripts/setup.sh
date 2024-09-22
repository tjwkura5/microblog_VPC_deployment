#!/bin/bash

# Variables
LOCAL_FILE_PATH="/home/ubuntu/scripts/start_app.sh"  
REMOTE_IP="10.0.132.86"                
REMOTE_FILE_PATH="/home/ubuntu/scripts/start_app.sh" 
SSH_KEY="/home/ubuntu/.ssh/app-key.pem"

# Step 1: Secure copy the file to the remote server
scp -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${LOCAL_FILE_PATH}" ubuntu@"${REMOTE_IP}":"${REMOTE_FILE_PATH}"

if [ $? -eq 0 ]; then
    echo "File copied successfully."
else
    echo "Failed to copy the file."
    exit 1
fi

# Step 2: SSH into the remote server and print its IP address
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no ubuntu@"${REMOTE_IP}" << 'EOF'
    if [ $? -ne 0 ]; then
        echo "Failed to connect to the remote server."
        exit 1
    fi
    echo "Connected to the remote server."
    echo "The IP address of this server is: $(hostname -I | awk '{print $1}')"

    echo "Running the Start App Scrip.........."
    bash /home/ubuntu/scripts/start_app.sh
EOF

exit 0 