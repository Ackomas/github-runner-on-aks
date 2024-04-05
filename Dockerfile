FROM summerwind/actions-runner:latest

FROM cruizba/ubuntu-dind as ubuntu-dind

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y --no-install-recommends wget

FROM ubuntu-dind as github-runner
ARG REFRESH="5"

# allow installing when the main user is root
ENV npm_config_unsafe_perm=true

ENV DBUS_SESSION_BUS_ADDRESS=/dev/null
ENV TERM xterm
# avoid million NPM install messages
ENV npm_config_loglevel warn
# allow installing when the main user is root
ENV npm_config_unsafe_perm true
ENV QT_X11_NO_MITSHM=1 \
  _X11_NO_MITSHM=1 \
  _MITSHM=0

#Coverlet path
ENV PATH="$PATH:/root/.dotnet/tools"

#Allow run of agent runner as 
ENV RUNNER_ALLOW_RUNASROOT="1"

# set the github runner version
ARG RUNNER_VERSION="2.313.0"

RUN apt-get update -y && apt-get upgrade -y

# update the base packages and add a non- user
RUN useradd -m docker && apt-get install -y --no-install-recommends \
  # install curl, python and additional packages
  curl gnupg jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip ca-certificates \
  #Add ZIP/UNZIP Tools
  zip unzip \
  #Git
  git \
  #Cypress dependencies
  libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb dbus-x11

# Install tools
RUN \
  # Azure CLI
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
  # Helm
  curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
  apt-get install -y --no-install-recommends apt-transport-https && \
  echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
  apt-get update -y && \
  apt-get install --no-install-recommends helm && \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  # PowerShell
  # Download the Microsoft repository keys
  wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell_7.4.1-1.deb_amd64.deb && \
  dpkg -i powershell_7.4.1-1.deb_amd64.deb && \
  apt-get install -f && \
  # Delete the downloaded package file
  rm powershell_7.4.1-1.deb_amd64.deb && \
  # Install GitHub CLI
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt update -y \
  && apt install gh -y \
  && apt install maven -y

RUN \
  #add MS repo
  wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
  # Download Microsoft signing key and repository
  wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
  # Install Microsoft signing key and repository
  dpkg -i packages-microsoft-prod.deb && \
  # Clean up
  rm packages-microsoft-prod.deb && \
  # Update packages
  apt update && \
  # dotnet install
  apt-get update && \
  apt-get install -y dotnet-sdk-8.0 && \
  dotnet workload install wasm-tools && \
  #Add coverlet
  dotnet tool install --global coverlet.console && \
  #Hack - Update and repair workloads
  dotnet workload update && dotnet workload repair

#install node.js & npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION v20.9.0
RUN mkdir -p /usr/local/nvm && apt-get update && echo "y" | apt-get install curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
  && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
  && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
  # install some additional dependencies
  chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh && \
  #add user to group docker
  usermod -aG docker docker

