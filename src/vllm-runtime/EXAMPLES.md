## Deployment of Llama-2-7b-chat-hf

Download Model from vllm

ResourcePlan needed: `infer2.l`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=meta-llama/Llama-2-7b-chat-hf \
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=1 \
   -e REVISION=08751db2aca9bf2f7f80d2e516117a53d7450235 \
   -e ARG="" \
   inference-server:0.1
```

## Deployment of Llama-2-13b-chat-hf

ResourcePlan needed: `infer2.4xl`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=meta-llama/Llama-2-13b-chat-hf \
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=4 \
   -e REVISION=0ba94ac9b9e1d5a0037780667e8b219adde1908c \
   -e ARG="" \
   inference-server:0.1
```

## Deployment of Llama-2-70b-chat-hf

ResourcePlan needed: `train2.8xl`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=meta-llama/Llama-2-70b-chat-hf \
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=8 \
   -e REVISION=36d9a7388cc80e5f4b3e9701ca2f250d21a96c30 \
   -e ARG="" \
   inference-server:0.1
```

## Deployment of Falcon-7b

ResourcePlan needed: `infer2.l`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=tiiuae/falcon-7b
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=1 \
   -e TRUST_REMOTE_CODE=true \
   -e REVISION=2f5c3cd4eace6be6c0f12981f377fb35e5bf6ee5 \
   -e ARG="" \
   inference-server:0.1
```

## Deployment of Falcon-7b-instruct

ResourcePlan needed: `infer2.l`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=tiiuae/falcon-7b-instruct
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=1 \
   -e TRUST_REMOTE_CODE=true \
   -e REVISION=c7f670a03d987254220f343c6b026ea0c5147185 \
   -e ARG="" \
   inference-server:0.1
```

## Deployment of Falcon-40b-instruct

ResourcePlan needed: `infer2.4xl`

```shell
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model
   -e MODELID=tiiuae/falcon-40b-instruct
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=4 \
   -e TRUST_REMOTE_CODE=true \
   -e REVISION=1e7fdcc9f45d13704f3826e99937917e007cd975 \
   -e ARG="--gpu-memory-utilization=0.93" \
   inference-server:0.1
```
