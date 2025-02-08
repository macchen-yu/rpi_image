# Use Ubuntu 24.04 as the base image
FROM crops/yocto:ubuntu-20.04-base
# Set environment variables to prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 先使用 root
USER root
# 更新並升級包管理器
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get  install -y \
    nano \
    tree && \
    apt-get clean 
# Set environment variables for workspace
ARG WORKSPACE_PATH=None
# Create a new user and set the password
ARG USER=none
ARG PASSWD=none

RUN useradd -m -s /bin/bash $USER && echo "$USER:$PASSWD" | chpasswd && \
    usermod -aG sudo $USER && \
    mkdir -p $WORKSPACE_PATH 
# Switch to the newly created user
USER $USER

# Set the working directory
WORKDIR $WORKSPACE_PATH

# Define the default command to start a terminal
CMD ["/bin/bash"]
