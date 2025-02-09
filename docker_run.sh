##########################################################
# Define user configuration variables
USER="user"               # Username for the container
PASSWD=0                  # Password (0 is likely a placeholder, update as needed)
docker_images_name="rpi4_img:latest"  # Name and tag for the Docker image (lowercase only)
docker_container_name="rpi4_image"    # Name for the Docker container (lowercase only)
docker_workspace_path="/home/$USER/RPI4"  # Workspace path inside the container
device_path="/dev/sda"
##########################################################
# Run the Docker container
# Map the current directory to the workspace path inside the container
# Set the working directory and run the container as the specified user
# Assign the container the specified name

# Check if the device exists
if [ -e "$device_path" ]; then
    echo "[INFO] Device $device_path detected, starting Docker container..."
    docker run -itd -v "$(pwd)":$docker_workspace_path \
        --network host \
        --device $device_path:$device_path \
        -w $docker_workspace_path --user $USER \
        --name $docker_container_name $docker_images_name
else
    echo -e "\e[33m[WARNING] Device $device_path not detected, please check if the device is connected!\e[0m"
    docker run -itd -v "$(pwd)":$docker_workspace_path \
        --network host \
        -w $docker_workspace_path --user $USER \
        --name $docker_container_name $docker_images_name
fi

#

# 在容器內執行命令
docker exec -it $docker_container_name bash -c "
    cd $docker_workspace_path &&
    echo $PASSWD | sudo -S chown -R $USER:$USER $docker_workspace_path &
    sleep 2 && echo -e ' \nChanging ownership, please wait...\n' &&
    wait &&
    echo 'Setup complete!' &&
    bash
"