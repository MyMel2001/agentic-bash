#!/bin/bash

# --- Configuration Section ---
CONFIG_DIR="$HOME/.config/nodemixaholic-software/agentic-bash"
CONFIG_FILE="$CONFIG_DIR/config.sh"
ACTOR_EXTRA_DEETS="$CONFIG_DIR/actor.md"


mkdir -p "$CONFIG_DIR" > /dev/null 2>&1
touch "$CONFIG_FILE"
touch "$ACTOR_EXTRA_DEETS"

# Sammy's Model Pairing
PLANNER_MODEL="gemma4:12b" 
ACTOR_MODEL="deepseek-v4-flash:cloud"
HOST="100.118.11.83:11434"

# --- System Prompts ---

# This prompt forces DeepSeek to focus on the 'Why' and the 'How' without writing the 'What'
PLANNER_SYSTEM="You are a Unix-like Systems Architect. Your ONLY 
job is to create a logical plan for a task. NEVER OUTPUT ANY 
FULL BASH COMMANDS, however outputting programs and arguments 
sperately is fine as long as they are not giving away the answer
that is the command. ONLY output a detailed plan.

Rules:
1. Analyze the user request for safety and OS compatibility. 
2. List the necessary steps and utilities required (e.g., find, sed, grep).
3. Warn about any destructive side effects.
4. Remember: DO NOT output any full bash commands. ONLY output a detailed plan
that does NOT give any commands to the user. The user does not want to be 
handheld that much. However, the user is an AI - so make sure that you make the
plan detailed."

# This prompt tells Ministral to be the precise translator
ACTOR_SYSTEM="You are a Senior DevOps Engineer. You will receive a technical plan. 
Your job is to translate that plan into a single, high-performance, one-line bash command. 
Rules: No markdown, no explanations, no backticks. Only the executable string.
Remember to keep it simple, simplicity is the best form of complexity - especially 
in UNIX-like shell. In other words, do not over complicate commands!

Extra details:

$(cat $ACTOR_EXTRA_DEETS)"

# --- Logic Execution ---

PROMPT_REQUEST="$1"
if [ -z "$PROMPT_REQUEST" ]; then
    echo "Usage: $0 \"<request>\"" >&2
    exit 1
fi

[ -f /etc/os-release ] && . /etc/os-release || PRETTY_NAME="Unix-like"

# 1. THE PLANNING PHASE
echo "🧠 Planner Thinking ($PLANNER_MODEL)..." >&2

# We send a clean JSON payload to the remote Ollama server
PLAN_OUTPUT=$(curl -s "http://$HOST/api/generate" -d "{
  \"model\": \"$PLANNER_MODEL\",
  \"prompt\": \"System: $PLANNER_SYSTEM\nContext: $PRETTY_NAME | User: $USER | PWD: $(pwd)\nRequest: $PROMPT_REQUEST\",
  \"stream\": false
}" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"$//' | sed 's/\\n/\n/g' | sed 's/\\"/"/g')

# 2. THE ACTING PHASE 
echo "🛠️  Actor Executing ($ACTOR_MODEL)..." >&2

FINAL_CMD=$(curl -s "http://$HOST/api/generate" -d "{
  \"model\": \"$ACTOR_MODEL\",
  \"prompt\": \"System: $ACTOR_SYSTEM\nPlan to convert: $PLAN_OUTPUT\",
  \"stream\": false
}" | grep -o '"response":"[^"]*"' | sed 's/"response":"//;s/"$//' | tr -d '\n\r')

# --- UI & Execution ---

echo -e "\n\033[1;34m[STRATEGY]\033[0m"
echo "$PLAN_OUTPUT"
echo -e "--------------------------------------"

echo -e "\033[1;32m[PROPOSED COMMAND]\033[0m"
echo "$FINAL_CMD"
echo -e "--------------------------------------"

read -r -p "Run this command? (y/N): " confirmation
if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    eval "$FINAL_CMD"
else
    echo "❌ Aborted."
fi
