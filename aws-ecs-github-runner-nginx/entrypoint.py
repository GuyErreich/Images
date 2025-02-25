#!/usr/bin/env python3
import argparse
import datetime
import subprocess
import os
from jinja2 import Environment, FileSystemLoader

def main():
    parser = argparse.ArgumentParser(description="Generate nginx.conf from a Jinja2 template and start nginx")
    parser.add_argument("--resolver", required=True, help="The resolver IP (e.g. google '8.8.8.8')")
    parser.add_argument("--port", help="The port (e.g. '3128')", default="3128")
    parser.add_argument("--allowed-upstreams", required=True, help="Comma-separated list of allowed upstream IPs")
    parser.add_argument("--server-names", required=True, help="Comma-separated list of server names")
    parser.add_argument("--template-dir", required=True, help="Directory containing the template file")
    parser.add_argument("--template-file", required=True, help="Name of the template file (e.g. nginx.conf.j2)")
    parser.add_argument("--output-file", required=True, help="Path where the generated nginx.conf will be written")
    parser.add_argument("--cmd", nargs=argparse.REMAINDER, help="Optional command to run instead of nginx", default=["nginx", "-g", "daemon off;"])
    
    args = parser.parse_args()

    if not os.path.isdir(args.template_dir):
        raise Exception(f"ERROR: Template directory '{args.template_dir}' does not exist.")

    template_path = os.path.join(args.template_dir, args.template_file)
    if not os.path.isfile(template_path):
        raise Exception(f"ERROR: Template file '{template_path}' does not exist.")

    # Split the input values
    allowed_upstreams = [up.strip() for up in args.allowed_upstreams.split(",") if up.strip()]
    server_names = [name.strip() for name in args.server_names.split(",") if name.strip()]

    # Get the current startup time
    startup_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Set up the Jinja2 environment and load the template file
    env = Environment(loader=FileSystemLoader(args.template_dir), trim_blocks=True, lstrip_blocks=True)
    try:
        template = env.get_template(args.template_file)
    except Exception as e:
        raise Exception(f"ERROR: Failed to load Jinja2 template - {e}")

    try:
        # Render the template with the provided variables
        conf_content = template.render(
            resolver                = args.resolver,
            port                    = args.port,
            allowed_upstreams       = allowed_upstreams,
            allowed_server_names    = server_names
        )
    except Exception as e:
        raise Exception(f"ERROR: Failed to render template - {e}")

    # Ensure output directory exists
    output_dir = os.path.dirname(args.output_file)
    os.makedirs(output_dir, exist_ok=True)

    # Write to output file
    try:
        with open(args.output_file, "w") as f:
            f.write(conf_content)
        print(f"SUCCESS: nginx.conf generated at {args.output_file} at {startup_time}")
    except Exception as e:
        raise Exception(f"ERROR: Failed to write nginx.conf - {e}")

    # Verify the file exists after writing
    if not os.path.isfile(args.output_file):
        raise Exception(f"ERROR: nginx.conf file was not created!")

    # Log the generated file
    print("Generated nginx.conf content:")
    print("=" * 40)
    print(conf_content)
    print("=" * 40)

    try:
        subprocess.run(args.cmd, check=True)
    except subprocess.CalledProcessError as e:
        raise Exception(f"ERROR: Failed to start Nginx - {e}")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(str(e))
        exit(1) 
