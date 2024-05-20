#!/bin/bash

# Check if SERVE_FILES_PATH is not set
if [ -z "${SERVE_FILES_PATH}" ]; then
	echo "Error: SERVE_FILES_PATH not set"
	exit 1
fi

# Set default Host to 0.0.0.0 if not already set
HOST="${HOST:-0.0.0.0}"
OPT+=" --host ${HOST}"

# Add port to options if PORT is set and --port is not already in ARG
if [ ! -z "${PORT}" ] && [[ ! "${ARG}" =~ --port ]]; then
	OPT+=" --port ${PORT}"
fi

if [ ! -z "${MODEL_SERVE_NAME}" ] && ! [[ "${ARG}" =~ --served-model-name ]]; then
	OPT+=" --served-model-name=${MODEL_SERVE_NAME}"
fi

if [ ! -z "${URL_PRE_FIX}" ] && ! [[ "${ARG}" =~ --url-prefix ]]; then
	OPT+=" --url-prefix=${URL_PRE_FIX}"
fi

# Add --trust-remote-code to options if TRUST_REMOTE_CODE is set and --trust-remote-code is not already in ARG
if [ ! -z "${TRUST_REMOTE_CODE}" ] && [[ ! "${ARG}" =~ --trust-remote-code ]]; then
	OPT+=" --trust-remote-code"
fi

# Fix: Correctly add --batch-size to options if BATCH_SIZE is set and --batch-size is not already in ARG
# Previous version incorrectly added --trust-remote-code again instead of --batch-size
if [ ! -z "${BATCH_SIZE}" ] && [[ ! "${ARG}" =~ --batch-size ]]; then
	OPT+=" --batch-size ${BATCH_SIZE}"
fi

# Add any additional arguments passed through ARG
if [ ! -z "${ARG}" ]; then
	OPT+=" ${ARG}"
fi

# Echo the SERVE_FILES_PATH and the options to be used
echo ${SERVE_FILES_PATH}
echo ${OPT}

# Uncommented below 3 lines of code for moving the models to the ${HF_HOME}/models directory for downloading the models from the Hugging Face Hub
# mkdir -p ${HF_HOME}/models
# cp -r /mnt/models/* ${HF_HOME}/models
# chmod -R 777 ${HF_HOME}/models

# Use set -x to print commands and their arguments as they are executed.
set -x
# Run the service with the model and the prepared options

# Uncommet below line of code for running the service from HF Home models directory , Please make sure to comment the line of code for running the service from SERVE_FILES_PATH
#infinity_emb --model-name-or-path "${HF_HOME}/models" ${OPT}

infinity_emb --model-name-or-path "${SERVE_FILES_PATH}" ${OPT}