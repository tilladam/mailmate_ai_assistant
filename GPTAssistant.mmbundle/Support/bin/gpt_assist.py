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

def get_keychain_value(service, account):
    """Retrieve value from macOS Keychain."""
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", service, "-a", account, "-w"],
            capture_output=True,
            text=True,
            check=True
        )
        value = result.stdout.strip()
        return value if value else None
    except subprocess.CalledProcessError:
        logging.debug(f"Keychain value not found for service={service}, account={account}")
        return None
    except Exception as e:
        logging.warning(f"Error accessing Keychain: {e}")
        return None

# Load configuration
config = configparser.ConfigParser()
script_dir = os.path.dirname(os.path.abspath(__file__))
config.read(os.path.join(script_dir, 'config.ini'))

# Try Keychain first, then environment variables, then config file
# Priority: Keychain > Environment > Config file
API_PROVIDER = (
    get_keychain_value("MailMateAI", "provider") or
    os.environ.get('GPT_ASSIST_PROVIDER') or
    config['DEFAULT'].get('ApiProvider', 'anthropic')
)

# Read API key and model from provider-specific section (for backwards compatibility)
provider_section = 'OPENAI' if API_PROVIDER == 'openai' else 'ANTHROPIC'
API_KEY = (
    get_keychain_value("MailMateAI", "api_key") or
    os.environ.get('GPT_ASSIST_API_KEY') or
    config[provider_section].get('ApiKey')
)
MODEL = (
    get_keychain_value("MailMateAI", "model") or
    os.environ.get('GPT_ASSIST_MODEL') or
    config[provider_section].get('Model')
)

if not API_KEY:
    raise ValueError(f"API key not found. Set GPT_ASSIST_API_KEY environment variable or ApiKey in [{provider_section}] section of config.ini")

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
    url = "https://api.openai.com/v1/responses"
    data = json.dumps({
        "model": MODEL,
        "input": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": prompt
                    }
                ]
            }
        ],
        "text": {
            "format": {
                "type": "text"
            }
        },
        "reasoning": {
            "effort": "medium",
            "summary": "auto"
        },
        "store": False
    }).encode('utf-8')

    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Content-Type', 'application/json')
    req.add_header('Authorization', f'Bearer {API_KEY}')

    context = ssl._create_unverified_context()
    with urllib.request.urlopen(req, context=context) as response:
        response_data = json.loads(response.read().decode('utf-8'))

    logging.debug(f"OpenAI response: {json.dumps(response_data, indent=2)}")

    # Extract text from the response
    for item in response_data.get('output', []):
        if item.get('type') == 'message':
            for content in item.get('content', []):
                if content.get('type') == 'output_text':
                    return content.get('text', '').strip()

    raise ValueError("No text output found in response")

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
    prompt = f"""Your task is to rewrite email text so it is clearer, more concise, and more professional, while maintaining the original message and intent.
Follow these detailed steps:

**Guidelines for Improvement**
- Review the provided original email text carefully.
- Revise the text for clarity, conciseness, and professionalism.
- Use simple, direct language.
- Never use em dashes or similar dashes.
- Ensure a professionally friendly, charismatic tone—not too curt, but not overly friendly.
- Use active voice where appropriate.
- Organize ideas logically; break up long sentences or paragraphs for readability.
- Remove unnecessary repetition or extraneous details.
- Correct any grammar, spelling, or usage errors.
- Re-write as if from a busy, charismatic executive, thinking from first principles about how to ensure the message is well-received.

**Reasoning Order**
1. **Reasoning:** Think step-by-step about improvements—analyze weaknesses, clarify meaning, prioritize ideas, and decide where to simplify or reorganize.
2. **Conclusion:** Only after reasoning, write the improved email.

**Output Format**
- Present ONLY the revised email text, as a well-formed email body (no salutations or closings unless included in the original).
- The length should match the necessary content but be as concise as possible.
- Do not include analysis, explanation, or process steps in your output.

**Examples**

*Example 1:*
Original:
Hi team, I wanted to let you all know that the meeting time is being changed from 3pm to 2:30pm because of a conflict that came up, so please adjust your schedules accordingly. Sorry for the last-minute update.

Improved:
The meeting has been rescheduled to 2:30pm due to a conflict. Please update your calendars. Thank you for your flexibility.

*Example 2:*
Original:
Hello John,
Thanks for following up with me. I’m still waiting to hear back from finance about the budget—once I know more, I’ll let you know, but for now I don’t have any updates for you.

Improved:
Thank you for your follow-up. I am awaiting a response from finance regarding the budget and will update you as soon as I have more information.

*(Real emails may be longer and contain more complex ideas. Use these examples as style and structure guides.)*

**Important Reminders (do not include in the output):**
- Focus on clarity, conciseness, professional-yet-friendly tone, and email organization.
- Only output the improved email text—not your process or analysis.
- Do not use em dashes or similar dashes.

**(Reminder: Your objective is to make email text clearer, more concise, and professional, while preserving intent and tone as outlined above.)**

Email draft:
<email draft>
{email_content}
</email draft>


"""

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
