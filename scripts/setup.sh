#!/bin/bash

# Variables
FILE_PATH="/home/ubuntu/scripts/start_app.sh"  
REMOTE_IP="10.0.132.86"                
SSH_KEY="/home/ubuntu/.ssh/app-key.pem"

# Step 1: Secure copy the file to the remote server
# Chatgpt prompt: How do I ssh and avoid prompts to verify the identity of the remote server i'm connecting to?
# Chatgpt answer: StrictHostKeyChecking=no
scp -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${FILE_PATH}" ubuntu@"${REMOTE_IP}":"${FILE_PATH}"

# Check the exit status of the scp command
# $? holds the exit status of the last executed command (0 means success, non-zero means failure)
# The if else statements here and throughout + the echo commands are suggestions from chatgpt
if [ $? -eq 0 ]; then
    echo "File copied successfully."
else
    echo "Failed to copy the file."
    exit 1
fi

# Step 2: SSH into the remote server
# The '<< 'EOF'' syntax is used to create a "here document," which allows you to pass a block of commands directly to the remote server over SSH.
# Everything between << 'EOF' and EOF will be treated as a set of commands to execute on the remote server.
# single quotes around EOF means the shell treats the content between << 'EOF' and EOF as a literal string, meaning any variables will not be interpolated.
# The << 'EOF' syntax is a suggestion from chatgpt. 
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no ubuntu@"${REMOTE_IP}" << 'EOF'
    if [ $? -ne 0 ]; then
        echo "Failed to connect to the remote server."
        exit 1
    fi
    echo "Connected to the remote server."
    echo "The IP address of this server is: $(hostname -I | awk '{print $1}')"

    echo "Running the Start App Script.........."
    source /home/ubuntu/scripts/start_app.sh

    # Check if the script executed successfully
    if [ $? -eq 0 ]; then
        echo "Start App Script executed successfully."
    else
        echo "Failed to run Start App Script."
        exit 1
    fi
EOF

# Check the SSH exit status
if [ $? -eq 0 ]; then
    echo "Remote commands executed successfully."
else
    echo "Failed to execute remote commands."
    exit 1
fi

exit 0 