ARG GITHUB_RUNNER_IMAGE=github_runner:latest

FROM ghcr.io/epicgames/unreal-engine:dev-slim-5.4.4 AS unreal

# Use a base image with the necessary libraries for Unreal Engine
FROM ${GITHUB_RUNNER_IMAGE}

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN curl -sSL https://github.com/go-task/task/releases/download/v3.8.0/task_linux_amd64.tar.gz -o task.tar.gz \
    && tar -xzvf task.tar.gz \
    && rm -rf task.tar.gz \
    && mv task /usr/local/bin/

# Set the working directory
WORKDIR $HOME

USER runner

COPY --from=unreal --chown=runner:runner /home/ue4/UnrealEngine ./UnrealEngine

COPY ["Automation tools/", "./"] 

ENV UE_TOOLS=$HOME/UnrealEngine/Engine/Build/BatchFiles


ENTRYPOINT [ "Runner_Manager_Scripts/entrypoint.sh" ]



