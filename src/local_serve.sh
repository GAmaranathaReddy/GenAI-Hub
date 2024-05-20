#!/bin/bash

# Define the path to your model checkpoints on the host machine
export MODEL_CHECKPOINT_PATH="Your model checkpoint path"

# Environment variables from the Argo workflow template
export IMAGE="Docker image"
export NUM_SHARD="4"

# Additional environment variables needed for the script
export HOST="0.0.0.0"
export PORT="8000"
export TRUST_REMOTE_CODE="true"
export BATCH_SIZE="64"
export MODEL_SERVE_NAME="nomic-ai/nomic-embed-text-v1.5"
export URL_PRE_FIX="/v1"
# export CHAT_TEMPLATE="llama-2-chat"


# Docker run command
docker run -it --rm \
    -e TRUST_REMOTE_CODE="$TRUST_REMOTE_CODE" \
    -e ARG="$ARG" \
    -e BATCH_SIZE="$BATCH_SIZE" \
    -e PORT="$PORT" \
    -e HOST="$HOST" \
    -v "${MODEL_CHECKPOINT_PATH}:/mnt/models" \
    --shm-size=15g \
    -p "$PORT:$PORT" \
    "$IMAGE"

    # Add more -e flags to pass additional environment variables
