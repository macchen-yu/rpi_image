##########################################################
# Define user configuration variables
USER="mac"               # Username for the container
PASSWD=0221                  # Password (0 is likely a placeholder, update as needed)
docker_images_name="rpi4_img:latest"  # Name and tag for the Docker image (lowercase only)
docker_container_name="rpi4_image"    # Name for the Docker container (lowercase only)
docker_workspace_path="/home/$USER/RPI4"  # Workspace path inside the container
##########################################################
# Run the Docker container
# Map the current directory to the workspace path inside the container
# Set the working directory and run the container as the specified user
# Assign the container the specified name

docker run -id -v `pwd`:$docker_workspace_path \
-w $docker_workspace_path --user $USER \
--name $docker_container_name $docker_images_name
