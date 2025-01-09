import os
import logging
import time
import threading
import telebot
import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/bot-setup.log'),
        logging.StreamHandler()  # Also log to console
    ]
)
logger = logging.getLogger(__name__)

# Configuration from environment or GitHub Secrets
TELEGRAM_BOT_TOKEN = 'S_TELEGRAM_BOT_TOKEN'
GITHUB_TOKEN = 'GH_PAT'
REPO_OWNER = 'BURMETSKYI'
REPO_NAME = 'EPA-Wordpress-project'

# Initialize Telegram Bot
bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)

def monitor_workflow(workflow_file, chat_id, user):
    """
    Monitor workflow status and send a message when completed
    Runs in a separate thread
    """
    max_wait_time = 3600  # 1 hour maximum wait
    start_time = time.time()
    
    # Wait for the workflow to actually start
    time.sleep(30)  # Wait 30 seconds to ensure workflow has begun
    
    while time.time() - start_time < max_wait_time:
        try:
            # Get the most recent workflow run
            url = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/workflows/{workflow_file}/runs'
            
            headers = {
                'Authorization': f'token {GITHUB_TOKEN}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            response = requests.get(url, headers=headers, params={'per_page': 1})
            
            if response.status_code == 200:
                runs = response.json().get('workflow_runs', [])
                
                if runs:
                    latest_run = runs[0]
                    status = latest_run.get('status', 'unknown')
                    conclusion = latest_run.get('conclusion', 'unknown')
                    workflow_url = latest_run.get('html_url', '')
                    
                    # Check if workflow is in a final state
                    if status in ['completed', 'failure', 'cancelled']:
                        # Prepare completion message
                        if conclusion == 'success':
                            message = (
                                f"✅ Workflow *{workflow_file}* Completed Successfully!\n\n"
                                f"Triggered by: {user}\n"
                                f"Status: {conclusion.upper()}\n"
                                f"Workflow Details: {workflow_url}"
                            )
                        else:
                            message = (
                                f"❌ Workflow *{workflow_file}* Failed\n\n"
                                f"Triggered by: {user}\n"
                                f"Status: {conclusion.upper()}\n"
                                f"Workflow Details: {workflow_url}"
                            )
                        
                        # Send message back to the chat
                        bot.send_message(chat_id, message, parse_mode='Markdown')
                        logger.info(f"Workflow {workflow_file} monitoring completed")
                        return
                    
                    # If status is not final, continue monitoring
                    logger.info(f"Current workflow status: {status}")
            
            # Wait before checking again
            time.sleep(30)  # Check every 30 seconds
        
        except Exception as e:
            logger.error(f"Error monitoring workflow: {str(e)}")
            time.sleep(30)
    
    # Timeout message if workflow doesn't complete
    bot.send_message(
        chat_id, 
        f"⏰ Workflow *{workflow_file}* monitoring timed out after 1 hour.", 
        parse_mode='Markdown'
    )

def trigger_github_workflow(workflow_file, chat_id, user):
    """Trigger GitHub Actions workflow using workflow_dispatch"""
    url = f'https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/workflows/{workflow_file}/dispatches'
    
    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json'
    }
    
    payload = {
        'ref': 'main',
        'inputs': {
            'reason': f'Triggered by {user} via Telegram'
        }
    }
    
    try:
        logger.info(f"Attempting to trigger workflow: {workflow_file}")
        logger.info(f"Payload: {payload}")
        
        response = requests.post(url, json=payload, headers=headers)
        
        logger.info(f"Workflow trigger response status: {response.status_code}")
        logger.info(f"Workflow trigger response text: {response.text}")
        
        if response.status_code == 204:
            logger.info(f"Workflow {workflow_file} triggered by {user}")
            
            # Start workflow monitoring in a separate thread
            monitor_thread = threading.Thread(
                target=monitor_workflow, 
                args=(workflow_file, chat_id, user)
            )
            monitor_thread.start()
            
            return f"🚀 Workflow *{workflow_file}* triggered successfully! Monitoring in progress...", True
        else:
            logger.error(f"Workflow trigger failed: {response.text}")
            return f"❌ Failed to trigger workflow. Error: {response.text}", False
    
    except Exception as e:
        logger.error(f"Workflow trigger error: {str(e)}")
        return f"❌ An error occurred: {str(e)}", False

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
    response, success = trigger_github_workflow('dev-workflow.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')


@bot.message_handler(commands=['deploy_dev_ec2'])
def deploy_dev_ec2(message):
    """Deploy to development EC2 using dev-deploy-ec2.yml"""
    user = message.from_user.username or message.from_user.first_name
    response, success = trigger_github_workflow('dev-deploy-ec2.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')


@bot.message_handler(commands=['deploy_dev_full'])
def deploy_dev_full(message):
    """Full development deployment using dev-deploy-full.yml"""
    user = message.from_user.username or message.from_user.first_name
    response, success  = trigger_github_workflow('dev-deploy-full.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['deploy_blue_green'])
def deploy_blue_green(message):
    """Trigger blue-green deployment"""
    user = message.from_user.username or message.from_user.first_name
    response, success  = trigger_github_workflow('blue-green-deploy.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['backup_db'])
def backup_database(message):
    """Trigger database backup"""
    user = message.from_user.username or message.from_user.first_name
    response, success = trigger_github_workflow('db-backup.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['backup_content'])
def backup_content(message):
    """Trigger content backup"""
    user = message.from_user.username or message.from_user.first_name
    response, success  = trigger_github_workflow('content-backup.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['terminate_dev'])
def terminate_dev(message):
    """Terminate development environment"""
    user, success  = message.from_user.username or message.from_user.first_name
    response = trigger_github_workflow('terminate-dev.yml', message.chat.id, user)
    bot.reply_to(message, response, parse_mode='Markdown')

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
    
    # Retry mechanism for bot polling
    while True:
        try:
            logger.info("Connecting to Telegram Bot API...")
            bot.polling(none_stop=True, interval=3, timeout=30)
        except Exception as e:
            logger.error(f"Bot polling error: {str(e)}")
            logger.info("Attempting to reconnect in 10 seconds...")
            time.sleep(10)

if __name__ == '__main__':
    main()
