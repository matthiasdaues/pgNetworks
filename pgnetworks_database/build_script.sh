#!/bin/bash

# Define the path to your .env file and Dockerfile
ENV_FILE=".env"
DOCKERFILE_PATH="."

# Prompt the user to enter a tag for the Docker image
echo "Please enter your tag:"
read IMAGE_TAG

# Initialize build-args variable
BUILD_ARGS=""

# Check if the user entered a tag; if not, use a default one
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG="latest" # Default tag
fi

# Read each line in the .env file and append it as --build-arg
while IFS='=' read -r key value
do
  BUILD_ARGS+=" --build-arg $key=$value"
done < "$ENV_FILE"

# Run docker build with the build arguments and the user-provided tag
docker build $BUILD_ARGS -t $IMAGE_TAG .

