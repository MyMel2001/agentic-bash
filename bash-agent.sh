#!/bin/bash

# --- Configuration Section ---

# Define paths
CONFIG_DIR="$HOME/.config/nodemixaholic-software/agentic-bash"
CONFIG_FILE="$CONFIG_DIR/config.sh"

# Define default settings (these are informational now, but loaded)
DEFAULT_MODEL="deepseek-r1:7b" 
DEFAULT_HOST="http://localhost:11434"

# --- Function Definitions ---

# Function to ensure the config file exists with default values (Silenced)
ensure_config() {
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "INFO: Creating default configuration file: $CONFIG_FILE" >&2
        cat <<EOF > "$CONFIG_FILE"
# Agentic Bash Helper Configuration
# This script uses the model's default parameters.
MODEL="$DEFAULT_MODEL"
HOST="$DEFAULT_HOST"
EOF
    fi
}
ensure_config > /dev/null

# Load Configuration
. "$CONFIG_FILE"
MODEL_RUN="$MODEL"
HOST_RUN="$HOST"
PROMPT_REQUEST=""

# --- Argument Parsing Function ---
# Simplified to only allow overriding model and host for a single run
parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --model)
                MODEL_RUN="$2"
                shift 2
                ;;
            --host)
                HOST_RUN="$2"
                shift 2
                ;;
            *)
                # Treat the remaining argument as the command prompt
                if [ -z "$PROMPT_REQUEST" ]; then
                    PROMPT_REQUEST="$1"
                fi
                shift
                ;;
        esac
    done
}

# --- Main Script Execution ---

# 0. Parse arguments
parse_arguments "$@"

# 1. Check arguments
if [ -z "$PROMPT_REQUEST" ]; then
    echo "ERROR: Missing prompt. Usage: $0 [options] \"<your request>\"" >&2
    echo "Options: --model <name> --host <url>" >&2
    exit 1
fi

# 2. Check for Ollama CLI
if ! command -v ollama &> /dev/null; then
    echo "FATAL ERROR: Ollama CLI is not installed or not in PATH." >&2
    echo "Please install Ollama: https://ollama.com" >&2
    exit 1
fi

# 3. Get OS details
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_INFO="You are on a system running the OS \"$PRETTY_NAME\"."
else
    OS_INFO="You are on a generic Linux system."
fi

# 4. Construct the Ollama Prompt
PROMPT_CONTENT="$OS_INFO Please output a command to do this: \"$PROMPT_REQUEST\". Do not output anything else, and do not format it with markdown - such as with a codeblock. Only output the command, please."

# 5. Execute Ollama (via CLI)
echo "⚙️  Querying Agent (Model: $MODEL_RUN, Host: $HOST_RUN)..." >&2

# Execute ollama run and strip any trailing newlines/carriage returns
CMD_TO_RUN=$(OLLAMA_HOST="$HOST_RUN" ollama run "$MODEL_RUN" --hidethinking "$PROMPT_CONTENT" 2>/dev/null | tr -d '\n\r')

# 6. Check for successful command generation
if [ -z "$CMD_TO_RUN" ]; then
    echo "ERROR: Ollama did not return a command or encountered an error." >&2
    echo "Check if Ollama is running at $HOST_RUN and if the model '$MODEL_RUN' is installed." >&2
    exit 2
fi

# 7. Confirmation Step
echo "---"
echo "🤖 Agent Proposed Command:"
echo "**$CMD_TO_RUN**"
echo "---"
read -r -p "Do you want to execute this command? (Y/n): " confirmation

case "$confirmation" in
    [Yy]* ) 
        echo "🚀 Executing command..."
        eval "$CMD_TO_RUN"
        ;;
    * ) 
        echo "❌ Execution cancelled by user."
        exit 0
        ;;
esac
