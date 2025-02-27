#!/bin/bash

LOG_FILE="/home/ubuntu/bot-setup.log"

# Function to check exit status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed." | tee -a $LOG_FILE
        exit 1
    else
        echo "$1 succeeded." | tee -a $LOG_FILE
    fi
}

# Clear log
> $LOG_FILE

# Step 1: Update and upgrade packages
echo "Running apt update..." | tee -a $LOG_FILE
sudo apt-get update -y
check_exit_status "apt update"

echo "Running apt upgrade..." | tee -a $LOG_FILE
sudo apt-get upgrade -y
check_exit_status "apt upgrade"

# Step 2: Set permissions
REPO_PATH="/home/ubuntu/EPA-Wordpress-project"
echo "Changing permissions of the cloned repository..." | tee -a $LOG_FILE
sudo chmod -R 755 $REPO_PATH
check_exit_status "chmod"

# Step 3: Install dependencies
echo "Installing required packages..." | tee -a $LOG_FILE
sudo apt-get install -y python3 python3-pip git python3.12-venv python3-dev libsystemd-dev gcc
check_exit_status "package installation"

# Step 4: Set up virtual environment
PROJECT_DIR="$REPO_PATH/telegram"
cd $PROJECT_DIR

echo "Setting up Python virtual environment..." | tee -a $LOG_FILE
python3 -m venv venv
check_exit_status "create virtual environment"

source venv/bin/activate

# Step 5: Install Python dependencies
echo "Installing Python dependencies..." | tee -a $LOG_FILE
pip install --upgrade pip
pip install pyTelegramBotAPI requests python-dotenv
check_exit_status "Python dependencies installation"

# Step 6: Run the bot script
BOT_SCRIPT="$PROJECT_DIR/bot.py"
if [ -f "$BOT_SCRIPT" ]; then
    echo "Running bot script in the background..." | tee -a $LOG_FILE
    nohup python3 "$BOT_SCRIPT" > bot.log 2>&1 &
    BOT_PID=$!
    sleep 5
    if ps -p $BOT_PID > /dev/null; then
        echo "Bot is running with PID $BOT_PID" | tee -a $LOG_FILE
    else
        echo "Error: Bot failed to start." | tee -a $LOG_FILE
        exit 1
    fi
else
    echo "Error: bot.py not found in $PROJECT_DIR" | tee -a $LOG_FILE
    exit 1
fi

echo "Setup completed successfully!" | tee -a $LOG_FILE
