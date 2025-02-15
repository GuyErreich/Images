#!/bin/bash

set -e  # Exit immediately on errors
set -x
set -o pipefail  # Ensure pipelines return errors if any command fails

usage() {
    echo "Usage: $0 --repo <repository> --token <token> [-h]"
    echo "  --repo                      The url to the repo to register the runner too"
    echo "  --token                     The generated token for the runner"
    echo "  --runner-name               The name of the generated runner"
    echo "  --labels                    The labels of the generated runner"
    echo "  --ecs-task                  Is this runner is an ecs task"
    echo "  -h, --help                  Display this help message"
    exit 1
}

declare -A ARGS=( ["repo"]="REPO" ["token"]="TOKEN" ["runner-name"]="RUNNER_NAME" ["labels"]="LABELS")
declare -A FLAGS=( ["ecs-task"]=false )

REPO="" TOKEN="" RUNNER_NAME="" LABELS=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --*) 
            key=${1#--}  # Remove '--' prefix
            if [[ -n ${ARGS[$key]} ]]; then
                declare ${ARGS[$key]}="$2"
                shift 2
            elif [[ -n ${FLAGS[$key]} ]]; then
                FLAGS[$key]=true  # Set flag to true
                shift
            else
                echo "Unknown option: $1"
                usage
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

for arg in "REPO" "TOKEN" "RUNNER_NAME"; do
    if [[ -z "${!arg}" ]]; then
        echo "Error: --${arg,,} is required."  # Convert to lowercase
        usage
    fi
done

# Proxy Configuration Debugging
echo "Checking Proxy Settings..."
if [[ -n "$HTTPS_PROXY" ]]; then
    echo "Using HTTPS_PROXY: $HTTPS_PROXY"
else
    echo "WARNING: No HTTPS_PROXY is set. Ensure your container has access to the internet."
fi

echo "Checking Network Connectivity..."
if ! curl -s --proxy "$HTTPS_PROXY" https://api.github.com; then
    echo "Error: Unable to connect to GitHub via proxy!"
    exit 1
else
    echo "GitHub API is reachable!"
fi

if [[ "${FLAGS[ecs-task]}" == "true" ]]; then
    if [[ -z "${ECS_CONTAINER_METADATA_URI_V4}" ]]; then
        echo "Error: ECS_CONTAINER_METADATA_URI_V4 is not set."
        exit 1
    fi
    TASK_METADATA=$(curl -s --proxy "$HTTPS_PROXY" "$ECS_CONTAINER_METADATA_URI_V4/task")
    TASK_ID=$(echo "$TASK_METADATA" | jq -r '.TaskARN' | awk -F'/' '{print $3}')

    echo "TASK_METADATA: $TASK_METADATA"
    echo "TASK_ID: $TASK_ID"

    if [[ -n "$TASK_ID" ]]; then
        RUNNER_NAME+="-$TASK_ID"
        LABELS+=",$TASK_ID"
    else
        echo "Error: Unable to fetch ECS task ID."
        exit 1
    fi
fi

echo "Configuring GitHub Actions Runner..."
echo "Repo: $REPO"
echo "Runner Name: $RUNNER_NAME"
echo "Labels: $LABELS"

echo "Requesting GitHub Runner Token..."
RUNNER_TOKEN=$(curl -s --proxy "$HTTPS_PROXY" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$REPO/actions/runners/registration-token" | jq -r '.token')

if [[ -z "$RUNNER_TOKEN" ]]; then
    echo "Error: Failed to fetch runner token."
    exit 1
fi
echo "GitHub Runner Token Retrieved."

if [[ -z "$RUNNER_MANAGER_DIR" ]]; then
    RUNNER_MANAGER_DIR="$PWD"
fi
echo "RUNNER_MANAGER_DIR: $RUNNER_MANAGER_DIR"

sudo sh -c "echo 'REPO=${REPO}' >> /etc/environment"
sudo sh -c "echo 'TOKEN=${TOKEN}' >> /etc/environment"
sudo sh -c "echo 'RUNNER_NAME=${RUNNER_NAME}' >> /etc/environment"
sudo sh -c "echo 'RUNNER_TOKEN=${RUNNER_TOKEN}' >> /etc/environment"
sudo sh -c "echo 'RUNNER_MANAGER_DIR=${RUNNER_MANAGER_DIR}' >> /etc/environment"

echo "Starting Supervisor..."
source $RUNNER_MANAGER_DIR/start_supervisor.sh

if [[ -d "actions-runner" ]]; then
    echo "Configuring GitHub Actions Runner..."
    cd actions-runner
    github-runner-config --unattended --replace --url "https://github.com/$REPO" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" ${LABELS:+--labels "$LABELS"}
    
    echo "Starting GitHub Actions Runner..."
    github-runner-run
else
    echo "Error: Directory 'actions-runner' not found."
    exit 1
fi

