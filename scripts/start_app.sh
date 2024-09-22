#!/bin/bash

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Add the deadsnakes PPA to get more Python versions
echo "Adding deadsnakes PPA for Python..."
sudo add-apt-repository ppa:deadsnakes/ppa -y

# Install Python 3.9 and venv
echo "Installing Python 3.9 and python3.9-venv..."
sudo apt install python3.9 python3.9-venv -y

# Install pip (Python package installer)
echo "Installing Python 3 pip..."
sudo apt install python3-pip -y

# Install software-properties-common (useful for managing PPAs)
echo "Installing software-properties-common..."
sudo apt install software-properties-common -y

# Install additional development tools (in case they're needed for Python packages)
echo "Installing build tools for Python package compilation..."
sudo apt install build-essential libssl-dev libffi-dev -y

# Install Git for version control
echo "Installing Git..."
sudo apt install git -y

# Clone the Git repository
echo "Cloning Git repository..."
GIT_REPO_URL="https://github.com/tjwkura5/microblog_VPC_deployment.git"  # Update with your repo URL
git clone "${GIT_REPO_URL}" || { echo "Git clone failed!"; exit 1; }

# Extract the name of the repository from the URL and move into the repository directory
REPO_NAME=$(basename -s .git "${GIT_REPO_URL}")
cd "${REPO_NAME}" || { echo "Failed to enter repo directory!"; exit 1; }

# Store the current working directory (repository root) as a variable
REPO_DIR=$(pwd)
echo "Repository directory is: ${REPO_DIR}"

# Create a Python virtual environment in the root of the cloned repository
echo "Creating a Python virtual environment in the repository root..."
python3.9 -m venv venv || { echo "Failed to create virtual environment!"; exit 1; }

# Activate the virtual environment
echo "Activating the virtual environment..."
source venv/bin/activate

# Upgrade pip in the virtual environment
echo "Upgrading pip..."
pip install --upgrade pip || { echo "Pip upgrade failed!"; exit 1; }

# Install dependencies from a requirements.txt file if available
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt || { echo "Failed to install dependencies!"; exit 1; }

# Install additional dependencies
echo "Installing gunicorn, pymysql and cryptography"
pip install gunicorn pymysql cryptography || { echo "Failed to install additional dependencies!"; exit 1; }

# Set the Flask application
echo "Setting Flask application..."
export FLASK_APP=microblog.py

# Compile translations and upgrade database
echo "Compiling source code..."
flask translate compile || { echo "Translation compile failed!"; exit 1; }
flask db upgrade || { echo "Database upgrade failed!"; exit 1; }

# Create a gunicorn service file
echo "Creating gunicorn service file..."
cat << EOF | sudo tee /etc/systemd/system/gunicorn.service
[Unit]
Description=Gunicorn instance to serve microblog
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=${REPO_DIR}
Environment="PATH=${REPO_DIR}/venv/bin"
# Set the FLASK_APP variable
Environment="FLASK_APP=microblog.py"  
ExecStart=${REPO_DIR}/venv/bin/gunicorn -b :5000 -w 4 microblog:app

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and enable Gunicorn service
echo "Starting gunicorn service..."
sudo systemctl daemon-reload
sudo systemctl start gunicorn.service
sudo systemctl enable gunicorn.service

# Check if the gunicorn service is running
sudo systemctl is-active --quiet gunicorn.service && echo "Gunicorn is running" || echo "Gunicorn failed to start"
