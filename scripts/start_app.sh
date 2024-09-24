#!/bin/bash

# Update and upgrade system packages
# Including these echo command before installing a package was a suggestion from chatGpt 
echo "Updating and upgrading system packages..."
# This line comes from mike majors promgraf.sh and other scripts
sudo apt update && sudo apt upgrade -y

# Add the deadsnakes PPA to get more Python versions
# This line comes from installing jenkins
echo "Adding deadsnakes PPA for Python..."
sudo add-apt-repository ppa:deadsnakes/ppa -y

# Install Python 3.9 and venv
# This line comes from installing jenkins
echo "Installing Python 3.9 and python3.9-venv..."
sudo apt install python3.9 python3.9-venv -y

# Install pip (Python package installer)
# This line came from a fellow student
echo "Installing Python 3 pip..."
sudo apt install python3-pip -y

# Install software-properties-common (useful for managing PPAs)
# The suggestion to install the software-properties-common package came from a fellow student
# provides tools to manage software repositories
echo "Installing software-properties-common..."
sudo apt install software-properties-common -y

# Install additional development tools (in case they're needed for Python packages)
echo "Installing build tools for Python package compilation..."
# build-essential: includes essential tools needed to compile and build software from source code.
# libssl-dev: This package contains the development libraries for OpenSSL, which provides cryptographic functions such as encryption, decryption, and secure communications.
# libffi-dev: Libffi allows a program written in one programming language to call functions or use data types defined in another language.
# The preceding packages were recommended by chatgpt. 
sudo apt install build-essential libssl-dev libffi-dev -y

# Install Git for version control
echo "Installing Git..."
sudo apt install git -y

# Clone the Git repository
echo "Cloning Git repository..."
GIT_REPO_URL="https://github.com/tjwkura5/microblog_VPC_deployment.git"
# git clone succeeds (returns an exit code of 0), the part after || is skipped.
# git clone fails (returns a non-zero exit code), the block { echo "Git clone failed!"; exit 1; } is executed.
# The Or echo git clone failed exit 1 was a suggestion from chat gpt and has been used throughout
git clone "${GIT_REPO_URL}" || { echo "Git clone failed!"; exit 1; }

# Extract the name of the repository from the URL and move into the repository directory
# The basename command extracts the last part of a file path or URL.
# The -s option allows you to strip a suffix in this case .git ( got this from chatgpt I already knew about basename)
REPO_NAME=$(basename -s .git "${GIT_REPO_URL}")
cd "${REPO_NAME}" || { echo "Failed to enter repo directory!"; exit 1; }

# Store the current working directory (repository root) as a variable
REPO_DIR=$(pwd)
echo "Repository directory is: ${REPO_DIR}"

# Create a Python virtual environment in the root of the cloned repository
# The following lines up until Creating gunicron service file came from the jenkinsfile
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
# The following lines for creating the service and the config file came from Mike majors promgraf.sh
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
# The suggestion to add the following line came from chat GPT
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
# The && echo gunicorn or gunicron failed to start was a suggestion from chatGPT
sudo systemctl is-active --quiet gunicorn.service && echo "Gunicorn is running" || echo "Gunicorn failed to start"
