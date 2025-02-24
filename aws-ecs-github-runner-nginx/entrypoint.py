#!/usr/bin/env python3
import argparse
import datetime
import subprocess
from jinja2 import Environment, FileSystemLoader

def main():
    parser = argparse.ArgumentParser(description="Generate nginx.conf from a Jinja2 template and start nginx")
    parser.add_argument(
        "--resolver",
        required=True,
        help="The resolver IP (e.g. google '8.8.8.8')"
    )
    parser.add_argument(
        "--port",
        help="The port (e.g. '3128')",
        default="3128"
    )
    parser.add_argument(
        "--allowed-upstreams",
        required=True,
        help="Comma-separated list of allowed upstream IPs (e.g. '169.254.170.2,192.168.1.2')"
    )
    parser.add_argument(
        "--server-names",
        required=True,
        help="Comma-separated list of server names (e.g. 'api.github.com,github.com,*.actions.githubusercontent.com')"
    )
    parser.add_argument(
        "--template-dir",
        required=True,
        help="Directory containing the template file"
    )
    parser.add_argument(
        "--template-file",
        required=True,
        help="Name of the template file (e.g. nginx.conf.j2)"
    )
    parser.add_argument(
        "--output-file",
        required=True,
        help="Path where the generated nginx.conf will be written"
    )
    parser.add_argument(
        "--cmd",
        nargs=argparse.REMAINDER,
        help="Optional command to run instead of the default nginx startup",
        default=["nginx", "-g", "daemon off;"]
    )
    args = parser.parse_args()

    # Split the input values
    allowed_upstreams = [up.strip() for up in args.allowed_upstreams.split(",") if up.strip()]
    server_names = [name.strip() for name in args.server_names.split(",") if name.strip()]

    # Get the current startup time
    startup_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Set up the Jinja2 environment and load the template file
    env = Environment(loader=FileSystemLoader(args.template_dir), trim_blocks=True, lstrip_blocks=True)
    template = env.get_template(args.template_file)

    # Render the template with the provided variables
    conf_content = template.render(
        resolver                = args.resolver,
        port                    = args.port,
        allowed_upstreams       = allowed_upstreams,
        allowed_server_names    = server_names
    )

    print(args.resolver)
    print(allowed_upstreams)
    print(server_names)
    print(conf_content)

    # Write the final configuration file
    with open(args.output_file, "w") as f:
        f.write(conf_content)

    print(f"nginx.conf generated at {args.output_file} with startup time {startup_time}")

    # Run the provided command or default to starting nginx
    subprocess.run(args.cmd)

if __name__ == '__main__':
    main()
