#!/opt/homebrew/bin/python3
import os
import sys
import json
import urllib.request
import urllib.error
import urllib.parse
import ssl
import subprocess
import configparser

# Set up logging
import logging
logging.basicConfig(filename='/tmp/gpt_assist.log', level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')

logging.info(f"Script started. Python version: {sys.version}")

def notify_app(status, message=None):
    """Send status notification to companion app via URL scheme."""
    try:
        url = f"mailmate-ai://status/{status}"
        if message:
            encoded_message = urllib.parse.quote(message)
            url += f"?message={encoded_message}"

        logging.debug(f"Notifying app: {url}")
        subprocess.run(["open", url], check=False)
    except Exception as e:
        logging.warning(f"Failed to notify app: {e}")

def get_config_value(key):
    """Retrieve value from ~/.mailmateai/config.json."""
    config_file = os.path.expanduser("~/.mailmateai/config.json")
    try:
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
                value = config.get(key)
                return value if value else None
        logging.debug(f"Config file not found: {config_file}")
        return None
    except Exception as e:
        logging.warning(f"Error reading config file: {e}")
        return None

# Load configuration
config = configparser.ConfigParser()
script_dir = os.path.dirname(os.path.abspath(__file__))
config.read(os.path.join(script_dir, 'config.ini'))

# Try config file first, then environment variables, then config.ini
# Priority: ~/.mailmateai/config.json > Environment > config.ini
API_PROVIDER = (
    get_config_value("provider") or
    os.environ.get('GPT_ASSIST_PROVIDER') or
    config['DEFAULT'].get('ApiProvider', 'anthropic')
)

# Read API key and model from provider-specific section (for backwards compatibility with config.ini)
provider_section = 'OPENAI' if API_PROVIDER == 'openai' else 'ANTHROPIC'
API_KEY = (
    get_config_value("apiKey") or
    os.environ.get('GPT_ASSIST_API_KEY') or
    config[provider_section].get('ApiKey')
)
MODEL = (
    get_config_value("model") or
    os.environ.get('GPT_ASSIST_MODEL') or
    config[provider_section].get('Model')
)

if not API_KEY:
    raise ValueError(f"API key not found. Set GPT_ASSIST_API_KEY environment variable or ApiKey in [{provider_section}] section of config.ini")

# Load custom prompt if available
CUSTOM_PROMPT = get_config_value("customPrompt")

DEFAULT_PROMPT = """Your task is to rewrite email text so it is clearer, more concise, and more professional, while maintaining the original message and intent.

Guidelines:
- Use simple, direct language
- Ensure a professionally friendly tone
- Use active voice where appropriate
- Remove unnecessary repetition
- Correct any grammar or spelling errors

Output ONLY the revised email text, nothing else."""

def call_api(prompt):
    if API_PROVIDER == 'anthropic':
        return call_anthropic_api(prompt)
    elif API_PROVIDER == 'openai':
        return call_openai_api(prompt)
    else:
        raise ValueError(f"Unsupported API provider: {API_PROVIDER}")

def call_anthropic_api(prompt):
    url = "https://api.anthropic.com/v1/messages"
    data = json.dumps({
        "model": MODEL,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 1000
    }).encode('utf-8')

    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Content-Type', 'application/json')
    req.add_header('X-Api-Key', API_KEY)
    req.add_header('anthropic-version', '2023-06-01')

    context = ssl._create_unverified_context()
    with urllib.request.urlopen(req, context=context) as response:
        response_data = json.loads(response.read().decode('utf-8'))

    return response_data['content'][0]['text'].strip()

def call_openai_api(prompt):
    url = "https://api.openai.com/v1/chat/completions"
    data = json.dumps({
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
        "max_tokens": 1000
    }).encode('utf-8')

    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Content-Type', 'application/json')
    req.add_header('Authorization', f'Bearer {API_KEY}')

    context = ssl._create_unverified_context()
    with urllib.request.urlopen(req, context=context) as response:
        response_data = json.loads(response.read().decode('utf-8'))

    logging.debug(f"OpenAI response: {json.dumps(response_data, indent=2)}")

    return response_data['choices'][0]['message']['content'].strip()

try:
    # Notify app that processing has started
    notify_app("started")

    # Get the draft file path from MailMate
    edit_filepath = os.environ.get('MM_EDIT_FILEPATH')
    if not edit_filepath:
        raise ValueError("MM_EDIT_FILEPATH not set. This command must be run from a Composer window.")

    logging.debug(f"Edit filepath: {edit_filepath}")

    # Read the current draft content
    with open(edit_filepath, 'r', encoding='utf-8') as f:
        email_content = f.read()

    logging.debug(f"Email content length: {len(email_content)}")
    logging.debug(f"Email content: {repr(email_content[:500])}")

    # Prepare the prompt for AI
    # Use custom prompt if available, otherwise use default
    base_prompt = CUSTOM_PROMPT if CUSTOM_PROMPT else DEFAULT_PROMPT

    # If the prompt contains {email_content} placeholder, use it directly
    if "{email_content}" in base_prompt:
        prompt = base_prompt.format(email_content=email_content)
    else:
        # Otherwise, append the email content
        prompt = f"""{base_prompt}

Email draft to improve:
<email draft>
{email_content}
</email draft>

Output ONLY the improved email text:"""

    # Call the appropriate API
    generated_text = call_api(prompt)

    logging.debug(f"Generated text: {generated_text}")

    # Write the generated response back to the draft file
    with open(edit_filepath, 'w', encoding='utf-8') as f:
        f.write(generated_text)

    logging.info("Script completed successfully - draft updated")

    # Notify app of successful completion
    notify_app("finished")

except Exception as e:
    logging.error(f"Unexpected error: {str(e)}")
    logging.exception("An unexpected error occurred:")

    # Notify app of error with error message
    error_message = str(e)
    notify_app("error", error_message)

    # For saveForEditing mode, we can't easily show errors to the user
    # They'll need to check the log file
    sys.exit(1)

logging.info("Script completed")
