##########################################################
# Define user configuration variables
USER="user"               # Username for the container
PASSWD=0                  # Password (0 is likely a placeholder, update as needed)
docker_images_name="rpi4_img:latest"  # Name and tag for the Docker image (lowercase only)
docker_container_name="rpi4_image"    # Name for the Docker container (lowercase only)
docker_workspace_path="/home/$USER/RPI4"  # Workspace path inside the container
##########################################################


# Extract the SDK tarball
# sudo tar xvf en.SDK-x86_64-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz
# # Extract the sources tarball
# sudo tar xvf en.SOURCES-stm32mp1-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06.tar.gz  

# Build the Docker image
# Pass the user, password, and workspace path as build arguments
# Use the specified image name and tag

docker build --build-arg USER=$USER  --build-arg PASSWD=$PASSWD \
--build-arg WORKSPACE_PATH=$docker_workspace_path --no-cache  -t $docker_images_name .

# Run the Docker container
# Map the current directory to the workspace path inside the container
# Set the working directory and run the container as the specified user
# Assign the container the specified name

docker run -itd -v `pwd`:$docker_workspace_path \
-w $docker_workspace_path --user $USER \
--name $docker_container_name $docker_images_name

# Execute commands inside the container
# Install the SDK and set up the environment

docker exec -it $docker_container_name bash -c "
    cd $docker_workspace_path &&
    echo $PASSWD | sudo -S chown -R $USER:$USER $docker_workspace_path &&
    git clone https://github.com/yoctoproject/poky.git -b scarthgap
    bash
"
