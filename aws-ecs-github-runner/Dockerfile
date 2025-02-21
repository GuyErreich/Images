FROM ubuntu:22.04

ARG RUNNER_VERSION=2.322.0

# Prevent silent failures in pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"] 

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        wget \
        unzip \
        git \
        supervisor \
        jq \
        sudo \
    && rm -rf /var/lib/apt/lists/*
        
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME=/home/runner

WORKDIR ${HOME}

USER runner

WORKDIR ${HOME}/actions-runner
# mkdir actions-runner && cd actions-runner && \
# Download the latest runner package
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    echo "b13b784808359f31bc79b08a191f5f83757852957dd8fe3dbfcc38202ccf5768  actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c && \
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

USER root

RUN ln -s "${PWD}/actions-runner/config.sh" "/bin/github-runner-config" && \
    ln -s "${PWD}/actions-runner/run.sh" "/bin/github-runner-run"

USER runner

ENV RUNNER_MANAGER_DIR=${HOME}/Runner_Manager_Scripts

COPY --chown=runner:runner Runner_Manager_Scripts ${RUNNER_MANAGER_DIR}

ENTRYPOINT [ "Runner_Manager_Scripts/entrypoint.sh" ]