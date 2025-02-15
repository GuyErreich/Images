echo "Supervisor - starting..."

RUNNER_MANAGER_SCRIPT="$RUNNER_MANAGER_DIR/runner_manager.conf" #TODO: make this static (remove $RUNNER_MANAGER_DIR)

# Make the runner_manager.sh script executable
chmod +x "$RUNNER_MANAGER_SCRIPT"

AWS_ECS_ENDPOINT="http://169.254.170.2" #TODO: move to a docker env var
CREDENTIALS=$(curl -s $AWS_ECS_ENDPOINT$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)
AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')

sudo sh -c "echo 'ECS_CONTAINER_METADATA_URI_V4=${ECS_CONTAINER_METADATA_URI_V4}' >> /etc/environment"
sudo sh -c "echo 'AWS_REGION=${AWS_REGION}' >> /etc/environment"
sudo sh -c "echo 'AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}' >> /etc/environment"
sudo sh -c "echo 'AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}' >> /etc/environment"
sudo sh -c "echo 'AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}' >> /etc/environment"

sudo cp $RUNNER_MANAGER_SCRIPT /etc/supervisor/conf.d/
sudo supervisord -c /etc/supervisor/conf.d/runner_manager.conf

if [[ $? -eq 0 ]]; then
    echo "Supervisor - started successfully"
else
    echo "Supervisor - ERROR: Supervisor failed"
fi