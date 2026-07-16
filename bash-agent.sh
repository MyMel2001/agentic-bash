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

# --- Dependency Check ---
if ! command -v jq &> /dev/null; then
    echo "❌ Error: 'jq' is required to parse JSON safely. Please install it." >&2
    exit 1
fi

# --- System Prompts ---

PLANNER_SYSTEM="You are a Unix-like Systems Architect. Your ONLY 
job is to create a logical plan for a task. NEVER OUTPUT ANY 
FULL BASH COMMANDS, however outputting programs and arguments 
separately is fine as long as they are not giving away the answer
that is the command. ONLY output a detailed plan.

Rules:
1. Analyze the user request for safety and OS compatibility. 
2. List the necessary steps and utilities required (e.g., find, sed, grep).
3. Warn about any destructive side effects.
4. Remember: DO NOT output any full bash commands. ONLY output a detailed plan
that does NOT give any commands to the user. The user does not want to be 
handheld that much. However, the user is an AI - so make sure that you make the
plan detailed."

ACTOR_SYSTEM="You are a Senior DevOps Engineer. You will receive a technical plan. 
Your job is to translate that plan into a single, high-performance, one-line bash command. 
Rules: No markdown, no explanations, no backticks. Only the executable string.
Remember to keep it simple, simplicity is the best form of complexity - especially 
in UNIX-like shell. In other words, do not over complicate commands!

Extra details:

$(cat "$ACTOR_EXTRA_DEETS" 2>/dev/null)"

# --- Logic Execution ---

PROMPT_REQUEST="$1"
if [ -z "$PROMPT_REQUEST" ]; then
    echo "Usage: $0 \"<request>\"" >&2
    exit 1
fi

[ -f /etc/os-release ] && . /etc/os-release || PRETTY_NAME="Unix-like"

# 1. THE PLANNING PHASE
echo "🧠 Planner Thinking ($PLANNER_MODEL)..." >&2

# Safely construct the JSON payload with jq to prevent syntax breakages
PLANNER_PROMPT="System: $PLANNER_SYSTEM"$'\n'"Context: $PRETTY_NAME | User: $USER | PWD: $(pwd)"$'\n'"Request: $PROMPT_REQUEST"
PLAN_PAYLOAD=$(jq -n --arg m "$PLANNER_MODEL" --arg p "$PLANNER_PROMPT" '{model: $m, prompt: $p, stream: false}')

PLAN_RESPONSE=$(curl -s -X POST "http://$HOST/api/generate" \
  -H "Content-Type: application/json" \
  -d "$PLAN_PAYLOAD")

PLAN_OUTPUT=$(echo "$PLAN_RESPONSE" | jq -r '.response')

if [ -z "$PLAN_OUTPUT" ] || [ "$PLAN_OUTPUT" = "null" ]; then
    echo "❌ Error: Failed to retrieve plan from Planner Model." >&2
    exit 1
fi

# 2. THE ACTING PHASE 
echo "🛠️  Actor Formulating Command ($ACTOR_MODEL)..." >&2

ACTOR_PROMPT="System: $ACTOR_SYSTEM"$'\n'"Plan to convert: $PLAN_OUTPUT"
ACTOR_PAYLOAD=$(jq -n --arg m "$ACTOR_MODEL" --arg p "$ACTOR_PROMPT" '{model: $m, prompt: $p, stream: false}')

ACTOR_RESPONSE=$(curl -s -X POST "http://$HOST/api/generate" \
  -H "Content-Type: application/json" \
  -d "$ACTOR_PAYLOAD")

# We use 'tr -d "\n\r"' because the Actor should output a single line command
FINAL_CMD=$(echo "$ACTOR_RESPONSE" | jq -r '.response' | tr -d '\n\r')

if [ -z "$FINAL_CMD" ] || [ "$FINAL_CMD" = "null" ]; then
    echo "❌ Error: Failed to retrieve command from Actor Model." >&2
    exit 1
fi

# --- UI & Execution ---

echo -e "\n\033[1;34m[STRATEGY]\033[0m"
echo "$PLAN_OUTPUT"
echo -e "--------------------------------------"

echo -e "\033[1;32m[PROPOSED COMMAND]\033[0m"
echo "$FINAL_CMD"
echo -e "--------------------------------------"

read -r -p "Run this command? (y/N): " confirmation
if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    echo -e "🚀 Executing...\n"
    eval "$FINAL_CMD"
else
    echo "❌ Aborted."
fi
