import yaml
import json

# Load the matrix.yml file
with open("matrix.yml", "r") as f:
    data = yaml.safe_load(f)

# Convert YAML list to JSON format for GitHub Actions
matrix = json.dumps({"IMAGE_DIR": data["images"]})

# Print the matrix as GitHub Actions output
print(f"::set-output name=matrix::{matrix}")