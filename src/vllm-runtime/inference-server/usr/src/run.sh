#!/bin/bash

# vLLM v0.2.6
#usage: api_server.py [-h] [--host HOST] [--port PORT] [--allow-credentials]
#                     [--allowed-origins ALLOWED_ORIGINS]
#                     [--allowed-methods ALLOWED_METHODS]
#                     [--allowed-headers ALLOWED_HEADERS]
#                     [--served-model-name SERVED_MODEL_NAME]
#                     [--chat-template CHAT_TEMPLATE]
#                     [--response-role RESPONSE_ROLE] [--model MODEL]
#                     [--tokenizer TOKENIZER] [--revision REVISION]
#                     [--tokenizer-revision TOKENIZER_REVISION]
#                     [--tokenizer-mode {auto,slow}] [--trust-remote-code]
#                     [--download-dir DOWNLOAD_DIR]
#                     [--load-format {auto,pt,safetensors,npcache,dummy}]
#                     [--dtype {auto,half,float16,bfloat16,float,float32}]
#                     [--max-model-len MAX_MODEL_LEN] [--worker-use-ray]
#                     [--pipeline-parallel-size PIPELINE_PARALLEL_SIZE]
#                     [--tensor-parallel-size TENSOR_PARALLEL_SIZE]
#                     [--max-parallel-loading-workers MAX_PARALLEL_LOADING_WORKERS]
#                     [--block-size {8,16,32}] [--seed SEED]
#                     [--swap-space SWAP_SPACE]
#                     [--gpu-memory-utilization GPU_MEMORY_UTILIZATION]
#                     [--max-num-batched-tokens MAX_NUM_BATCHED_TOKENS]
#                     [--max-num-seqs MAX_NUM_SEQS]
#                     [--max-paddings MAX_PADDINGS] [--disable-log-stats]
#                     [--quantization {awq,gptq,squeezellm,None}]
#                     [--enforce-eager]
#                     [--max-context-len-to-capture MAX_CONTEXT_LEN_TO_CAPTURE]
#                     [--engine-use-ray] [--disable-log-requests]
#                     [--max-log-len MAX_LOG_LEN]
#
#vLLM OpenAI-Compatible RESTful API server.
#
#options:
#  -h, --help            show this help message and exit
#  --host HOST           host name
#  --port PORT           port number
#  --allow-credentials   allow credentials
#  --allowed-origins ALLOWED_ORIGINS
#                        allowed origins
#  --allowed-methods ALLOWED_METHODS
#                        allowed methods
#  --allowed-headers ALLOWED_HEADERS
#                        allowed headers
#  --served-model-name SERVED_MODEL_NAME
#                        The model name used in the API. If not specified, the
#                        model name will be the same as the huggingface name.
#  --chat-template CHAT_TEMPLATE
#                        The file path to the chat template, or the template in
#                        single-line form for the specified model
#  --response-role RESPONSE_ROLE
#                        The role name to return if
#                        `request.add_generation_prompt=true`.
#  --model MODEL         name or path of the huggingface model to use
#  --tokenizer TOKENIZER
#                        name or path of the huggingface tokenizer to use
#  --revision REVISION   the specific model version to use. It can be a branch
#                        name, a tag name, or a commit id. If unspecified, will
#                        use the default version.
#  --tokenizer-revision TOKENIZER_REVISION
#                        the specific tokenizer version to use. It can be a
#                        branch name, a tag name, or a commit id. If
#                        unspecified, will use the default version.
#  --tokenizer-mode {auto,slow}
#                        tokenizer mode. "auto" will use the fast tokenizer if
#                        available, and "slow" will always use the slow
#                        tokenizer.
#  --trust-remote-code   trust remote code from huggingface
#  --download-dir DOWNLOAD_DIR
#                        directory to download and load the weights, default to
#                        the default cache dir of huggingface
#  --load-format {auto,pt,safetensors,npcache,dummy}
#                        The format of the model weights to load. "auto" will
#                        try to load the weights in the safetensors format and
#                        fall back to the pytorch bin format if safetensors
#                        format is not available. "pt" will load the weights in
#                        the pytorch bin format. "safetensors" will load the
#                        weights in the safetensors format. "npcache" will load
#                        the weights in pytorch format and store a numpy cache
#                        to speed up the loading. "dummy" will initialize the
#                        weights with random values, which is mainly for
#                        profiling.
#  --dtype {auto,half,float16,bfloat16,float,float32}
#                        data type for model weights and activations. The
#                        "auto" option will use FP16 precision for FP32 and
#                        FP16 models, and BF16 precision for BF16 models.
#  --max-model-len MAX_MODEL_LEN
#                        model context length. If unspecified, will be
#                        automatically derived from the model.
#  --worker-use-ray      use Ray for distributed serving, will be automatically
#                        set when using more than 1 GPU
#  --pipeline-parallel-size PIPELINE_PARALLEL_SIZE, -pp PIPELINE_PARALLEL_SIZE
#                        number of pipeline stages
#  --tensor-parallel-size TENSOR_PARALLEL_SIZE, -tp TENSOR_PARALLEL_SIZE
#                        number of tensor parallel replicas
#  --max-parallel-loading-workers MAX_PARALLEL_LOADING_WORKERS
#                        load model sequentially in multiple batches, to avoid
#                        RAM OOM when using tensor parallel and large models
#  --block-size {8,16,32}
#                        token block size
#  --seed SEED           random seed
#  --swap-space SWAP_SPACE
#                        CPU swap space size (GiB) per GPU
#  --gpu-memory-utilization GPU_MEMORY_UTILIZATION
#                        the percentage of GPU memory to be used forthe model
#                        executor
#  --max-num-batched-tokens MAX_NUM_BATCHED_TOKENS
#                        maximum number of batched tokens per iteration
#  --max-num-seqs MAX_NUM_SEQS
#                        maximum number of sequences per iteration
#  --max-paddings MAX_PADDINGS
#                        maximum number of paddings in a batch
#  --disable-log-stats   disable logging statistics
#  --quantization {awq,gptq,squeezellm,None}, -q {awq,gptq,squeezellm,None}
#                        Method used to quantize the weights. If None, we first
#                        check the `quantization_config` attribute in the model
#                        config file. If that is None, we assume the model
#                        weights are not quantized and use `dtype` to determine
#                        the data type of the weights.
#  --enforce-eager       Always use eager-mode PyTorch. If False, will use
#                        eager mode and CUDA graph in hybrid for maximal
#                        performance and flexibility.
#  --max-context-len-to-capture MAX_CONTEXT_LEN_TO_CAPTURE
#                        maximum context length covered by CUDA graphs. When a
#                        sequence has context length larger than this, we fall
#                        back to eager mode.
#  --engine-use-ray      use Ray to start the LLM engine in a separate process
#                        as the server process.
#  --disable-log-requests
#                        disable logging requests
#  --max-log-len MAX_LOG_LEN
#                        max number of prompt characters or prompt ID numbers
#                        being printed in log. Default: unlimited.

if [ -z "${MODEL_ID}" ]; then
	echo "Error: MODEL_ID Not set"
	exit 1
fi

# Set default Host to 0.0.0.0
HOST="${HOST:-0.0.0.0}"
OPT+=" --host ${HOST}"

if [ ! -z "${PORT}" ] && ! [[ "${ARG}" =~ --port ]] ; then
	OPT+=" --port ${PORT}"
fi

if [ ! -z "${MODEL_SERVE_NAME}" ] && ! [[ "${ARG}" =~ --served-model-name ]]; then
	OPT+=" --served-model-name ${MODEL_SERVE_NAME}"
elif ! [[  "${ARG}" =~ --served-model-name ]]; then
	OPT+=" --served-model-name ${MODEL_ID/\//--}"
fi

if [ ! -z "${NUM_SHARD}" ] && ! [[ "${ARG}" =~ --tensor-parallel-size ]]; then
	OPT+=" --tensor-parallel-size ${NUM_SHARD}"
fi

if [ ! -z "${TRUST_REMOTE_CODE}" ] && ! [[ "${ARG}" =~ --trust-remote-code ]]; then
	OPT+=" --trust-remote-code"
fi

if [ ! -z "${TOKENIZER}" ] && ! [[ "${ARG}" =~ --tokenizer ]]; then
	OPT+=" --tokenizer ${TOKENIZER}"
fi

if [ ! -z "${DTYPE}" ] && ! [[ "${ARG}" =~ --dtype ]]; then
	OPT+=" --dtype ${DTYPE}"
fi

if [ ! -z "${REVISION}" ] && ! [[ "${ARG}" =~ --revision ]]; then
	OPT+=" --revision ${REVISION} --tokenizer-revision ${REVISION}" 
fi

if [ ! -z "${ARG}" ]; then
	OPT+=" ${ARG}"
fi

# If running as HUGGINGFACE OFFLINE. Models needs to be pre installed. 
if [ ! -z "${HF_HUB_OFFLINE}" ] && [ "${HF_HUB_OFFLINE}" -eq 1 ] && \
    [ ! -d ${HUGGINGFACE_HUB_CACHE}/models--${MODEL_ID/\//--} ]; then
    echo "Error: HF_HUB_OFFLINE is set and models is not pre-installed in \"${HUGGINGFACE_HUB_CACHE}\""
    sleep 30
    exit 1
fi

set -x
python -m vllm.entrypoints.openai.api_server --model ${MODEL_ID} ${OPT}
