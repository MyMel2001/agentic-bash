#!/bin/bash

# --- Configuration Section ---

CONFIG_DIR="$HOME/.config/nodemixaholic-software/agentic-bash"
CONFIG_FILE="$CONFIG_DIR/config.sh"

# Sammy's Thinker-Doer Setup
DEFAULT_PLANNER="deepseek-r1:14b" 
DEFAULT_ACTOR="ministral-3:8b"
DEFAULT_HOST="http://localhost:11434"

# --- Function Definitions ---

ensure_config() {
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_FILE" ]; then
        cat <<EOF > "$CONFIG_FILE"
PLANNER_MODEL="$DEFAULT_PLANNER"
ACTOR_MODEL="$DEFAULT_ACTOR"
HOST="$DEFAULT_HOST"
EOF
    fi
}
ensure_config > /dev/null

. "$CONFIG_FILE"
PLANNER_RUN="$PLANNER_MODEL"
ACTOR_RUN="$ACTOR_MODEL"
HOST_RUN="$HOST"
PROMPT_REQUEST=""

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --planner) PLANNER_RUN="$2"; shift 2 ;;
            --actor) ACTOR_RUN="$2"; shift 2 ;;
            *) [ -z "$PROMPT_REQUEST" ] && PROMPT_REQUEST="$1"; shift ;;
        esac
    done
}

# --- Execution ---

parse_arguments "$@"

if [ -z "$PROMPT_REQUEST" ]; then
    echo "Usage: $0 \"<request>\" [--planner <model>] [--actor <model>]" >&2
    exit 1
fi

# Get OS details for the Planner
[ -f /etc/os-release ] && . /etc/os-release || PRETTY_NAME="Linux"

# 1. THE PLANNING PHASE (DeepSeek-R1)
echo "🧠 Thinker ($PLANNER_RUN): Evaluating request..." >&2

# We allow the planner to show its thinking so you can see the logic
PLAN_OUTPUT=$(OLLAMA_HOST="$HOST_RUN" ollama run "$PLANNER_RUN" \
"System: You are a Linux Expert.
User Context: $PRETTY_NAME. Current Directory: $(pwd).
Task: Create a plan to: $PROMPT_REQUEST.
Instructions: Explain your logic briefly, then provide the best command.")

# 2. THE ACTING PHASE (Ministral-3)
echo "🛠️  Doer ($ACTOR_RUN): Generating final command..." >&2

# We pass the Planner's output to the Actor to get a clean, single-line command
FINAL_CMD=$(OLLAMA_HOST="$HOST_RUN" ollama run "$ACTOR_RUN" \
"Extract only the executable bash command from this plan. 
Rules: 
1. Output ONLY the command. 
2. No markdown, no backticks, no explanations.
3. If multiple steps are needed, use '&&'.
Plan: $PLAN_OUTPUT" | tr -d '\n\r')

# 3. OUTPUT & EXECUTION
echo -e "\n--- 🧠 THINKER'S REASONING ---"
echo "$PLAN_OUTPUT"
echo -e "-----------------------------\n"

echo "🤖 PROPOSED COMMAND:"
echo -e "\033[1;32m$FINAL_CMD\033[0m"
echo "---"

read -r -p "Execute? (y/N): " confirmation
if [[ "$confirmation" =~ ^[Yy]$ ]]; then
    echo "🚀 Executing..."
    eval "$FINAL_CMD"
else
    echo "❌ Cancelled."
fi
