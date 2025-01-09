import os
import logging
import telebot
import requests
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/home/ubuntu/github-telegram-bot/bot.log'),
        logging.StreamHandler()  # Also log to console
    ]
)
logger = logging.getLogger(__name__)

# Load environment variables (optional, but can be useful for local development)
load_dotenv()

# Configuration from environment or GitHub Secrets
TELEGRAM_BOT_TOKEN = 'TELEGRAM_BOT_TOKEN'
GITHUB_TOKEN = 'GH_PAT'
REPO_OWNER = 'BURMETSKYI'
REPO_NAME = 'EPA-Wordpress-project'

# Initialize Telegram Bot
bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)

def trigger_github_workflow(workflow_file, user):
    """Trigger GitHub Actions workflow using workflow_dispatch"""
    url = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/workflows/{workflow_file}/dispatches'
    
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json'
    }
    
    payload = {
        'ref': 'main',  # or your default branch
        'inputs': {
            'reason': f'Triggered by {user} via Telegram'
        }
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        
        if response.status_code == 204:
            logger.info(f"Workflow {workflow_file} triggered by {user}")
            return f"✅ Workflow {workflow_file} triggered successfully!"
        else:
            logger.error(f"Workflow trigger failed: {response.text}")
            return f"❌ Failed to trigger workflow. Error: {response.text}"
    
    except Exception as e:
        logger.error(f"Workflow trigger error: {str(e)}")
        return f"❌ An error occurred: {str(e)}"

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    """Handle start and help commands"""
    welcome_text = """
🤖 GitHub Actions Workflow Bot Commands:

Development Deployments:
/deploy_dev - Setup Dev Environment
/deploy_dev_ec2 - Restart EC2 Dev
/deploy_dev_full - Full development EC2 + RDS
/terminate_dev - Terminate dev environment

Prodaction Deployment:
/deploy_blue_green - Blue-Green deployment

Backup Workflows:
/backup_db - Database backup
/backup_content - Content backup

Utility Commands:
/status - Check bot status
"""
    bot.reply_to(message, welcome_text)

@bot.message_handler(commands=['deploy_dev'])
def deploy_dev(message):
    """Deploy to development environment using dev-workflow.yml"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('dev-workflow.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['deploy_dev_ec2'])
def deploy_dev_ec2(message):
    """Deploy to development EC2 using dev-deploy-ec2.yml"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('dev-deploy-ec2.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['deploy_dev_full'])
def deploy_dev_full(message):
    """Full development deployment using dev-deploy-full.yml"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('dev-deploy-full.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['deploy_blue_green'])
def deploy_blue_green(message):
    """Trigger blue-green deployment"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('blue-green-deploy.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['backup_db'])
def backup_database(message):
    """Trigger database backup"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('db-backup.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['backup_content'])
def backup_content(message):
    """Trigger content backup"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('content-backup.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['terminate_dev'])
def terminate_dev(message):
    """Terminate development environment"""
    user = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('terminate-dev.yml', user)
    bot.reply_to(message, response)

@bot.message_handler(commands=['status'])
def check_status(message):
    """Check deployment status"""
    status_message = (
        "🟢 Bot Status:\n"
        f"• Connected to GitHub Repo: {REPO_NAME}\n"
        f"• Owner: {REPO_OWNER}\n"
        "• Ready to trigger workflows"
    )
    bot.reply_to(message, status_message)

def main():
    logger.info("Telegram Bot is starting...")
    try:
        bot.polling(none_stop=True)
    except Exception as e:
        logger.error(f"Bot polling error: {str(e)}")

if __name__ == '__main__':
    main()
