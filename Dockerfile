FROM summerwind/actions-runner:latest

RUN sudo apt update -y && sudo apt upgrade -y

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

#INSTALL WGET
RUN sudo apt install zip unzip

#Add MS Repo
RUN \
  sudo wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
  sudo dpkg -i packages-microsoft-prod.deb && \
  sudo rm packages-microsoft-prod.deb

#Install .NET SDK
RUN \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-8.0

RUN \
  sudo dotnet workload install wasm-tools && \
  #Add coverlet
  sudo dotnet tool install --global coverlet.console && \
  #Hack - Update and repair workloads
  sudo dotnet workload update && sudo dotnet workload repair