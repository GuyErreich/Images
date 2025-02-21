import yaml
import json
import sys

try:
    # Load matrix.yml file
    with open("matrix.yml", "r") as f:
        data = yaml.safe_load(f)

    # Extract images list safely
    images = data.get("images", [])

    # Ensure a valid JSON string (avoid empty output)
    matrix = json.dumps({"IMAGE_DIR": images}) if images else '{"IMAGE_DIR": ["placeholder-image"]}'

    # Output to GitHub Actions
    print(f"::set-output name=matrix::{matrix}")

except Exception as e:
    print(f"::error ::Failed to read matrix.yml: {str(e)}", file=sys.stderr)
    sys.exit(1)  # Fail the job if matrix parsing fails
