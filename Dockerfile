FROM summerwind/actions-runner:latest

RUN apt update -y && apt upgrade -y

RUN sudo apt update -y \
  && umask 0002 \
  && sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Install MS Key
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add MS Apt repo
RUN umask 0002 && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ focal main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

# Install Azure CLI
RUN sudo apt update -y \
  && umask 0002 \
  && sudo apt install -y azure-cli 

RUN sudo rm -rf /var/lib/apt/lists/*

# Download and install kubectl 
RUN sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN sudo  chmod +x ./kubectl
RUN sudo mv ./kubectl /usr/local/bin/kubectl

#Coverlet path
ENV PATH="$PATH:/root/.dotnet/tools"


RUN \ 
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
  apt update && \
  apt install -y dotnet-sdk-8.0 && \
  dotnet workload install wasm-tools && \
  #Add coverlet
  dotnet tool install --global coverlet.console && \
  #Hack - Update and repair workloads
  dotnet workload update && dotnet workload repair