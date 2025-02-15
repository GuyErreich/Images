FROM ubuntu:22.04

ARG RUNNER_VERSION=2.320.0

RUN apt-get update && \
    apt-get install -y \
        curl \
        ca-certificates \
        wget \
        unzip \
        git \
        cron \
        supervisor \
        jq \
        sudo \
        libicu-dev \
    && rm -rf /var/lib/apt/lists/*
    # && git lfs install
        
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME=/home/runner

WORKDIR ${HOME}

USER runner

RUN mkdir actions-runner && cd actions-runner && \
    # Download the latest runner package
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    # Optional: Validate the hash
    echo "93ac1b7ce743ee85b5d386f5c1787385ef07b3d7c728ff66ce0d3813d5f46900  actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" | shasum -a 256 -c && \
    # Extract the installer
    tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

USER root

RUN ln -s ${PWD}/actions-runner/config.sh /bin/github-runner-config && \
    ln -s ${PWD}/actions-runner/run.sh /bin/github-runner-run

USER runner

ENV RUNNER_MANAGER_DIR=${HOME}/Runner_Manager_Scripts

COPY --chown=runner:runner Runner_Manager_Scripts ${RUNNER_MANAGER_DIR}

ENTRYPOINT [ "Runner_Manager_Scripts/entrypoint.sh" ]