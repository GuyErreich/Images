#!/bin/bash

TIMESTAMP_FILE="/tmp/last_active_timestamp"
CHECK_INTERVAL=60  # Check every 60 seconds
GRACE_PERIOD=5
GITHUB_RUNNER_ID=""

printenv

# Function to fetch runner ID
get_runner_id() {
    echo "DEBUG: Entering get_runner_id function" >&2
    echo "DEBUG: RUNNER_ID: $RUNNER_ID" >&2

    if [[ -n "$RUNNER_ID" ]]; then
        echo "DEBUG: RUNNER_ID already set to $RUNNER_ID" >&2
        echo $RUNNER_ID
        return 0
    fi

    echo "DEBUG: RUNNER_ID is empty, starting to fetch" >&2

    local runner_id
    local page=1

    while true; do
        echo "DEBUG: Fetching page $page" >&2
        echo "DEBUG: Making API call..." >&2

        local response
        response=$(curl -s \
            --proxy "$HTTPS_PROXY" \
            -H "Authorization: Bearer $TOKEN" \
            "https://api.github.com/repos/$REPO/actions/runners?per_page=100&page=$page")
        
        echo "DEBUG: Response fetched" >&2

        runner_id=$(echo "$response" | jq -r ".runners[] | select(.name == \"$RUNNER_NAME\") | .id")
        
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to fetch runner id {$runner_id}" >&2
            break
        fi

        if [[ -n "$runner_id" ]]; then
            echo "DEBUG: Found runner_id: $runner_id" >&2
            RUNNER_ID="$runner_id"
            echo $RUNNER_ID
            return 0
        fi

        local runners=$(echo "$response" | jq -r ".runners[]")

        if [[ $? -ne 0 ]]; then
            echo "ERROR: $response" >&2
            break
        fi

        if [[ -z "$runners" || "$runners" == "[]" ]]; then
            echo "DEBUG: No more runners found, ending loop" >&2
            break
        fi

        page=$((page + 1))
    done

    echo "ERROR: Unable to fetch runner ID for $RUNNER_NAME" >&2
    exit 1
}


# Function to fetch active jobs for the runner
fetch_runner_status() {
    local runner_id=$(get_runner_id)

    local runner_status=$(curl -s \
        --proxy "$HTTPS_PROXY" \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.github.com/repos/$REPO/actions/runners/$runner_id" | jq '.busy')

    echo "$runner_status"
}

# Function to cleanup the runner
cleanup_runner() {
    echo "DEBUG: Entering cleanup_runner function" >&2
    echo "Checking if the runner can be deregistered..."

    local runner_status=$(fetch_runner_status)
    if [[ "$runner_status" == "false" ]]; then
        echo "No active jobs. Deregistering the runner..."

        local runner_id=$(get_runner_id)
        if [[ -n "$runner_id" ]]; then
            github-runner-config remove --token $RUNNER_TOKEN

            if [[ $? -eq 0 ]]; then
                echo "Runner $RUNNER_NAME deregistered successfully"
            else
                echo "ERROR: Failed to deregister the runner"
                echo "ERROR: Failed to deregister the runner" >&2
            fi

            if [[ -n "$ECS_CONTAINER_METADATA_URI_V4" ]]; then
                echo "DEBUG: ECS_CONTAINER_METADATA_URI_V4 exists" >&2
                local task_metadata=$(curl -s --proxy "$HTTPS_PROXY" "$ECS_CONTAINER_METADATA_URI_V4/task")
                local cluster_name=$(echo "$task_metadata" | jq -r '.Cluster' | awk -F'/' '{print $2}')
                local task_id=$(echo "$task_metadata" | jq -r '.TaskARN' | awk -F'/' '{print $3}')
                local service=$(echo $task_metadata | jq -r ".Family")

                local desired_count=$(
                    aws ecs describe-services \
                        --region $AWS_REGION \
                        --cluster $cluster_name \
                        --services $service \
                        | jq ".services[].desiredCount"
                )

                if [[ $? -eq 0 ]]; then
                    echo "Current ECS tasks desired count: $desired_count"
                else
                    echo "ERROR: Failed to fetch ECS tasks desired count"
                    echo "ERROR: Failed to fetch ECS tasks desired count" >&2
                fi

                desired_count=$((desired_count - 1))

                echo "Decreasing ECS tasks desired count to: $desired_count"

                local output=$(
                    aws ecs update-service \
                        --region $AWS_REGION \
                        --cluster $cluster_name \
                        --service $service \
                        --desired-count $desired_count
                )

                if [[ $? -eq 0 ]]; then
                    echo "Decreased ECS tasks count successfully"
                else
                    echo "ERROR: Failed to decrease ECS tasks count: $output"
                    echo "ERROR: Failed to decrease ECS tasks count: $output" >&2
                fi

                echo "Stopping ECS task"

                output=$(
                    aws ecs stop-task \
                        --region $AWS_REGION \
                        --cluster $cluster_name \
                        --task $task_id \
                        --reason "Stopped task due to inactivity"
                )

                if [[ $? -eq 0 ]]; then
                    echo "Stopped ECS task successfully"
                else
                    echo "ERROR: Failed to stop ECS task: $output"
                    echo "ERROR: Failed to stop ECS task: $output" >&2
                fi
            else
                echo "DEBUG: ECS_CONTAINER_METADATA_URI_V4 doesn't exists" >&2
            fi
            
        else
            echo "Warning: Could not find runner ID for $RUNNER_NAME. Skipping deregistration."
        fi
    else
        echo "Active jobs still running ($runner_status). Skipping deregistration."
    fi
}

update_last_active_timestamp() {
    echo "$(date +%s)" > "$TIMESTAMP_FILE"
}

get_last_active_timestamp() {
    if [[ -f "$TIMESTAMP_FILE" ]]; then
        cat "$TIMESTAMP_FILE"
    else
        echo "0"  # Default to epoch if no timestamp exists
    fi
}

run_manager() {
    while true; do
        echo "Checking runner status..."

        local runner_status=$(fetch_runner_status)

        if [[ "$runner_status" == "true" ]]; then
            echo "Jobs still active status - busy: ($runner_status). Updating last active timestamp."
            update_last_active_timestamp
        else
            echo "Jobs still active status - busy: ($runner_status)."
            local current_time=$(date +%s)
            local last_active=$(get_last_active_timestamp)
            local idle_time=$((current_time - last_active))
            local idle_time_in_minutes="$((idle_time / 60)).$((idle_time % 60))"

            echo "Runner idle for $idle_time_in_minutes minutes (grace period: $GRACE_PERIOD minutes)."

            if (( idle_time >= GRACE_PERIOD * 60 )); then
                echo "Grace period exceeded. Initiating cleanup..."
                cleanup_runner
                echo "Exiting the script after cleanup."
                exit 0
            else
                echo "Runner is within the grace period. Skipping cleanup."
            fi
        fi

        echo "Sleeping for $CHECK_INTERVAL seconds..."
        sleep "$CHECK_INTERVAL"
    done
}

trap cleanup_runner SIGTERM

update_last_active_timestamp

run_manager
