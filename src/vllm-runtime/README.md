# LLM (Large Language Model) deployment on SAP AI Core

This guide provides steps to deploy a Large Language Model on [SAP AI Core](https://help.sap.com/docs/sap-ai-core/sap-ai-core-service-guide/what-is-sap-ai-core?locale=en-US).

## Prerequisites

This guide assumes:
1. You're already onboarded to SAP AI Core. See [Setting up AI Core](https://help.sap.com/docs/sap-ai-core/sap-ai-core-service-guide/initial-setup?locale=en-US)
2. You're familiar with deploying a model on AI Core. See [Deploy ML Model](https://help.sap.com/docs/sap-ai-core/sap-ai-core-service-guide/use-your-model?locale=en-US)
   - To help with the creation, the Postman Requests are in [Postman](postman) directory.

### What you need to deploy LLM on AI Core

1. [Find out the resource needed for the model](#find-out-the-resource-needed-for-the-model)
2. [vLLM inference server docker image](#build-vllm-inference-server-image)
3. [LLM ServingTemplate for deploying on AI Core](#llm-servingtemplate-for-ai-core)
4. [AI Core Deployment Configuration Request](#ai-core-deployment-configuration-request)
5. (Optional) [LLM Model Artifact (Tarball)](#llm-model-artifact)
6. (Optional) [LLM Deployment Artifact and Object Store](#llm-deployment-artifact-and-object-store)
7. [Inference Request example](#inference-request-example)

**Note**: Please refer to the [LLM Deployment Artifact and Object Store](#llm-deployment-artifact-and-object-store) for an explanation of the term "Optional."

For advanced or expert users who are eager to dive deep into the subject matter, we recommend referring to the detailed explanation on the vLLM inference server.

* [vLLM inference server usage](#vllm-inference-server-usage)
* [Brief introduction of vLLM parameters](#brief-introduction-of-vllm-parameters)

---

## Find out the resource needed for the model

Before we proceed with using the vLLM inference server, it is important to determine the resource plans currently available on the AI Core, as well as the resources required for the model.

Below is a list of the available resources:

* [Model Resources](#model-resources)
* [AI Core Resource Plans](#ai-core-resource-plans)

### Model Resources

 | Model | Reference | ResourcePlan | Remarks |
 | ---- | ---- | ---- | --- |
 | Falcon-40b-instruct | https://huggingface.co/tiiuae/falcon-40b-instruct     | `infer2.4xl` | In version 0.2.6 of the vLLM model, this specific model requires more resources than currently allocated. Resource creation has not yet been initiated.<br/>However, currently, only vLLM v0.1.7 supports the Falcon 40b-instructions on this resource plan. |
 | Llama-2-13b-chat-hf | https://huggingface.co/meta-llama/Llama-2-13b-chat-hf | `infer2.4xl` | - |

Note: You might need permission to access `meta-llama2` models on Hugging Face.

![Alt text](images/access_llama2_on_hf.png)

### AI Core Resource Plans
Below AI Core Resource Plans are available for tenants with service-plan: `sap-internal`. See [ResourcePlans](https://help.sap.com/docs/sap-ai-core/sap-ai-core-service-guide/choose-resource-plan-c58d4e584a5b40a2992265beb9b6be3c?locale=en-US)

 | ResourcePlan ID | GPUs | Label |
 | ---- | ---- | ---- |
 | infer2.l    | 1 A10G | `ai.sap.com/resourcePlan: infer2.l`    |
 | infer2.4xl  | 4 A10G | `ai.sap.com/resourcePlan: infer2.4xl`  |
 | train2.8xl  | 8 A100 | `ai.sap.com/resourcePlan: train2.8xl`  |
 | train2.8xxl | 8 A100 | `ai.sap.com/resourcePlan: train2.8xxl` |

This tutorial aims to enable `Falcon-40b-instruct` on [vLLM](https://github.com/vllm-project/vllm) tag v0.2.6

---

## Build vLLM inference server image

1. Checkout `AICore-LLM` repository
2. Prepare container image for LLM inference-server:

```sh
# From dir where you want to clone the repository:
git clone https://github.tools.sap/I564554/AICore-LLM.git

# From the AICore-LLM directory
cd inference-server

# Build docker image
docker build -t <dockerRepository>/inference-server:0.2.6 .

# Push docker image to the registered repository
docker push <dockerRepository>/inference-server:0.2.6
```

## LLM ServingTemplate for AI Core

The LLM ServingTemplate is available [here.](workflow/infer_workflow.yaml)

**This is a shortened version of the ServingTemplate highlights what is important to change.**

```yaml
apiVersion: ai.sap.com/v1alpha1
kind: ServingTemplate
metadata:
  name: your-vllm-huggingface                        ## This is the ServingTemplate's Name
  annotations:
    ...
  labels:
    scenarios.ai.sap.com/id: "your-vllm-huggingface" ## This is the ScenarioId for the ServingTemplate
    ...
spec:
  inputs:
    parameters:
    - name: image                                    ## vllm Docker Image
      type: "string"
      default: "mlf.common.cdn.repositories.cloud.sap/i564554/modelserver:vllm-test"
    - name: resourcePlan                             ## Resource Plan
      type: "string"
      default: "infer2.4xl"
    - name: minReplicas                              ## Min Replicas needed for the deployment
      type: "string"
      default: "1"
    - name: maxReplicas                              ## Max Replicas when inference request peak
      type: "string"
      default: "1"
    - name: portNumber                               ## Do not touch this
      type: "string"
      default: "9000"
    - name: modelId                                  ## This is the Huggingface's Model ID
      type: "string"                                 ## This is mapped to MODEL_ID in the ENV variable
      default: "codellama/CodeLlama-34b-Instruct-hf"
    - name: gpu                                      ## This is the Number of GPUs available on the Resource Plan
      type: "string"                                 ## This is mapped to NUM_SHARD in the ENV variable
      default: "4"
    - name: trustRemoteCode                          ## Refer to Huggingface's Model description.
      type: "string"                                 ## For Example, tiiuae/Falcon models require this.
      default: "true"                                ## This is mapped to TRUST_REMOTE_CODE in the ENV variable

    - name: disableKernel                            ## Do not touch this
      type: "string"
      default: "False"
    - name: huggingFaceOffline                       ## Download Model from Huggingface set '0'
      type: "string"                                 ## Download Model from Object Store set '1'
      default: "1"                                   ## This is mapped to HF_HUB_OFFLINE in the ENV variable

    - name: disableTelemetry                         ## Do not touch this
      type: "string"                                 ## This is mapped to HF_HUB_DISABLE_TELEMETRY in the ENV variable
      default: "1"
    - name: revision                                 ## Refer to Huggingface's Model commit, branch, or tag
      type: "string"                                 ## This is mapped to REVISION in the ENV variable
      default: "1"
    - name: additionalArgument                       ## Refer to vLLM's version OpenAI application parameters
      type: "string"                                 ## This is mapped to ARG in the ENV variable
      default: ""
    - name: modelName                                ## Refer to vLLM's openai application model name
      type: "string"                                 ## Refer to inference name
      default: ""                                    ## This is mapped to MODEL_SERVE_NAME in the ENV variable
    artifacts:
    - name: textmodel                                ## Artifact for Object Store
  template:
    apiVersion: "serving.kserve.io/v1beta1"
    metadata:
      annotations: |
        ...
      labels: |
        ai.sap.com/resourcePlan: "{{inputs.parameters.resourcePlan}}"
    spec: |
      predictor:
        imagePullSecrets:
        - name: your-docker-registry-secret
          env:
          ...
          - name: HUGGINGFACE_HUB_CACHE
            value: "/mnt/models"                     ## Change this to '/nonexistent/models' for Huggingface Model Download
          - name: HUGGING_FACE_HUB_TOKEN             ## Create Huggingface's Account API Token and add it as a generic secret
            valueFrom:
              secretKeyRef:
                name: your-huggingface-secret
                key: credential
          ...
```

## AI Core Deployment Configuration Request

This is a sample request for creating an AI Core Deployment Configuration, which requires prior artifact creation.

```json
{
    "name": "aicore-falcon-40b-instruct"
    "executableId": "your-vllm-huggingface",
    "scenarioId": "your-vllm-huggingface",
    "versionId": "0.0.1",
    "parameterBindings": [
        {
            "key": "resourcePlan",
            "value": "infer2.4xl"
        },
        {
            "key": "image",
            "value": "<your-repository>/inference-server:0.1.7"
        },
        {
            "key": "modelId",
            "value": "tiiuae/falcon-40b-instruct"
        },
        {
            "key": "minReplicas",
            "value": "1"
        },
        {
            "key": "maxReplicas",
            "value": "1"
        },
        {
            "key": "portNumber",
            "value": "9000"
        },
        {
            "key": "disablekernel",
            "value": "false"
        },
        {
            "key": "trustRemoteCode",
            "value": "true"
        },
        {
            "key": "revision",
            "value": "1e7fdcc9f45d13704f3826e99937917e007cd975"
        },
        {
            "key": "gpu",
            "value": "4"
        },
        {
            "key": "huggingFaceOffline",
            "value": "1"
        },
        {
            "key": "disableTelemetry",
            "value": "1"
        },
        {
            "key": "additionalArgument",
            "value": "--gpu-memory-utilization=0.93"
        },
        {
            "key": "modelName",
            "value": ""
        }
    ],
    "inputArtifactBindings": [
        {
            "artifactId": "<Your Artifact ID>",
            "key": "textmodel"
        }
    ]
}
```

## LLM Model Artifact

To download the Huggingface Model using the vLLM inference server, you will need a node with compatible GPUs to run the Model. The vLLM inference server will download the model from Huggingface and save it in the `HUGGINGFACE_HUB_CACHE`.

By default, the vLLM build version of this tutorial disables the Huggingface download. If you want to enable Huggingface download, you will need to make the following changes:

Docker runtime:
* In the docker run command, set `HF_HUB_OFFLINE=0`.

AI Core Deployment:
* Change the default value of `huggingFaceOffline` to **0** in the ServingTemplate.

**Package the Huggingface Model**

After downloading the model from the vLLM inference server, please ensure that the `HUGGINGFACE_HUB_CACHE` directory appears as shown below.

```shell
/mnt/models
├── models--tiiuae--falcon-40b-instruct
│   ├── blobs
│   │   ├── 06d223b121ea9febf7f9c5d13711f83a0a7614793dad11c768721bb12b415644
│   │   ├── 24f23b22feaf9d4d7708bd21f187241299e94f7a95e7cc8ebaf1b021d167c09b
│   │   ├── 24f2d2e20d26ae4f0729da0d008e0ee6d81fc560
│   │   ├── 24f43d813328da380b3d684c019f9c6d84df6b50
│   │   ├── 29cf77391c4e6c3f001c311a3b1ee04b08ddd06debd3185c6aee4bde6e1e0680
│   │   ├── 4aa644a0eca5b539ec8703d62d4b957c74a54963
│   │   ├── 56e9d70bfb7366cfb5703703371c12099faf7353f2b1bfc110d7580e55a998b3
│   │   ├── 5badcec25d8b0c102d0e246c98ad0aef17cde1654e9d0c622ae1370d35affe00
│   │   ├── 75c30d495411f16a7b3f1932a3514f59a49005fb332fc18ed9bf1fb568114783
│   │   ├── 7ec3f984df392b0e8cb73539bea9b02ff1f0d3570b0714685a222c88dce97750
│   │   ├── 835ea8767cbba256ca1e587b416372c67ab8805c7f21f03e8719f27fc089eb12
│   │   ├── 85edccd8edcb6408950a8ca586202c53305645df
│   │   ├── a349edf5c43e8f12710a760c123854ef8764b0f1542649aff9912a400908dc5e
│   │   ├── c785de797dbc36caf0484854ed5b36f52000037a
│   │   └── e55e2f6ecfd091b01cfd08dd622479016b31843d
│   ├── refs
│   │   └── main
│   └── snapshots
│       ├── 1e7fdcc9f45d13704f3826e99937917e007cd975
│       │   ├── config.json -> ../../blobs/e55e2f6ecfd091b01cfd08dd622479016b31843d
│       │   ├── configuration_RW.py -> ../../blobs/85edccd8edcb6408950a8ca586202c53305645df
│       │   ├── pytorch_model-00001-of-00009.bin -> ../../blobs/75c30d495411f16a7b3f1932a3514f59a49005fb332fc18ed9bf1fb568114783
│       │   ├── pytorch_model-00002-of-00009.bin -> ../../blobs/5badcec25d8b0c102d0e246c98ad0aef17cde1654e9d0c622ae1370d35affe00
│       │   ├── pytorch_model-00003-of-00009.bin -> ../../blobs/06d223b121ea9febf7f9c5d13711f83a0a7614793dad11c768721bb12b415644
│       │   ├── pytorch_model-00004-of-00009.bin -> ../../blobs/56e9d70bfb7366cfb5703703371c12099faf7353f2b1bfc110d7580e55a998b3
│       │   ├── pytorch_model-00005-of-00009.bin -> ../../blobs/29cf77391c4e6c3f001c311a3b1ee04b08ddd06debd3185c6aee4bde6e1e0680
│       │   ├── pytorch_model-00006-of-00009.bin -> ../../blobs/24f23b22feaf9d4d7708bd21f187241299e94f7a95e7cc8ebaf1b021d167c09b
│       │   ├── pytorch_model-00007-of-00009.bin -> ../../blobs/a349edf5c43e8f12710a760c123854ef8764b0f1542649aff9912a400908dc5e
│       │   ├── pytorch_model-00008-of-00009.bin -> ../../blobs/835ea8767cbba256ca1e587b416372c67ab8805c7f21f03e8719f27fc089eb12
│       │   ├── pytorch_model-00009-of-00009.bin -> ../../blobs/7ec3f984df392b0e8cb73539bea9b02ff1f0d3570b0714685a222c88dce97750
│       │   ├── special_tokens_map.json -> ../../blobs/24f43d813328da380b3d684c019f9c6d84df6b50
│       │   ├── tokenizer.json -> ../../blobs/24f2d2e20d26ae4f0729da0d008e0ee6d81fc560
│       │   └── tokenizer_config.json -> ../../blobs/c785de797dbc36caf0484854ed5b36f52000037a
│       └── ecb78d97ac356d098e79f0db222c9ce7c5d9ee5f
│           ├── special_tokens_map.json -> ../../blobs/24f43d813328da380b3d684c019f9c6d84df6b50
│           ├── tokenizer.json -> ../../blobs/24f2d2e20d26ae4f0729da0d008e0ee6d81fc560
│           └── tokenizer_config.json -> ../../blobs/4aa644a0eca5b539ec8703d62d4b957c74a54963
└── version.txt
```

To use the model in AI Core deployment, please use the provided script to tarball the model before upload to object store.

```shell
#!/bin/bash

cd ${HUGGINGFACE_HUB_CACHE}

[ -z "$MODEL_ID" ] && echo "ERR: MODEL_ID env not set" && exit 1

tar -cf ${MODEL_ID#*\/}.tar models--${MODEL_ID/\//--} version.txt

# Example: 
# MODEL_ID=tiiuae/falcon-40b-instruct
# tar -cf falcon-40b-instruct.tar models--tiiuae--falcon-40b-instruct version.txt
```

For packaging of **finetuned/custom** models. Tarball the model in similar way.

## LLM Deployment Artifact and Object Store

If the intention is for the vLLM inference server to download the model from Huggingface and save it in the `HUGGINGFACE_HUB_CACHE`, then there is no need for an Object Store. The vLLM inference server will always retrieve the main branch of the Huggingface Model.

**CAUTION**: The Huggingface community updates the `config.json` without providing warnings, which can cause the vLLM inference server runtime to break after downloading models.

The most effective approach for ensuring stability is to utilize the `REVISION` environment variable. This involves fixing the model's revision commit and using it consistently for deployment purposes.

To minimize the dependency on Huggingface, we can utilize the Object Store feature. This involves including the [package tarball](#llm-model-artifact) in the S3 object store.

```shell
aws --profile default cp falcon-40b-instruct.tar s3://on-boarded-bucket/model/falcon-40b-instruct/
```

## Inference Request example

This is an example curl request for vLLM inference server.

```shell
MODEL_ID=tiiuae/falcon-40b-instruct
curl -X POST https://<Deployment URL>/v1/chat/completions \
         -H "Content-Type: application/json" \
         -d "{
             \"model\": \"${MODEL_ID/\//--}\",
                 \"messages\": [ 
                 { 
                     \"role\": \"system\",
                     \"content\": \"You are a helpful assistant.\"
                 },
                 { 
                     \"role\": \"user\",
                     \"content\": \"San Francisco is a\"
                 }
             ]
         }"

```

---

## vLLM Inference Server Usage

vLLM offers support for a wide range of generative transformer models in Huggingface transformers. You can find a comprehensive list of the supported models in the vLLM's documentation, [here](https://vllm.readthedocs.io/en/latest/models/supported_models.html). 

To determine whether finetuning or using custom models is supported on the vLLM inference server, you have two options. You can either refer to the vLLM's [quickstart documentation](https://vllm.readthedocs.io/en/latest/getting_started/quickstart.html) or visit the ["Supported Model" page](https://vllm.readthedocs.io/en/latest/models/supported_models.html) to find the appropriate model class for your checkpoint.

The vLLM inference server image in this example is designed to support the OpenAI schema for generation requests. The entrypoint of the docker image is set to [run.sh](inference-server/usr/src/run.sh).

The runtime of the image can be configured using ENV variables.

**For Example: tiiuae/falcon-40b-instruct**

```shell
# This runtime option will download the Falcon-40b-instruct Model in the ${MODEL_DIR} location
export MODEL_DIR=<your preferred model directory>
docker run -d \
   -v ${MODEL_DIR}:/mnt/model \
   -e MODEL_ID=tiiuae/falcon-40b-instruct \
   -e HUGGING_FACE_HUB_TOKEN=xxxxabcdxxxx \
   -e HUGGINGFACE_HUB_CACHE=/mnt/model \
   -e HF_HUB_OFFLINE=0 \
   -e NUM_SHARD=4 \
   -e TRUST_REMOTE_CODE=true \
   -e REVISION=1e7fdcc9f45d13704f3826e99937917e007cd975 \
   -e ARG="--gpu-memory-utilization=0.93" \
   <dockerRepository>/inference-server:0.1
```

More examples of model parameter runtime is [here](EXAMPLE.md).

**vLLM Environment Variable Explanation**

```shell

MODEL_ID    - (String) Model Identifier from Huggingface
NUM_SHARD   - (Integer) Number of GPU for the model
REVISION    - (Hash) It can be a branch name, a tag name, or a commit ID from the Model in Huggingface.
               **This is optional for local or custom models**
HOST        - (Default: 0.0.0.0) Setting the vLLM inference Host IP
PORT        - (Default: 8000) Default Port from vLLM inference

TRUST_REMOTE_CODE - Optional (true/false) This is set for custom code that is
                    not directly supported by huggingface transformers

MODEL_SERVE_NAME  - Optional (string) Model name replacement for MODEL_ID
                    Note: If this environment is not specified, MODEL_ID name is used with some changes.
                    Example: MODEL_ID=meta-llama/Llama-2-7b-chat-hf
                    The following will be set MODEL_SERVE_NAME=meta-llama--llama-2-7b-chat-hf
                    **This is also used for local or custom models**

ARG         - Optional (vLLM Argument) This variable is to add a custom argument for vLLM inference that is available below.
              https://github.com/vllm-project/vllm/blob/main/vllm/config.py
```

**Important Environment Variable from Huggingface Transformer library**

```shell
# These are environment variables from Huggingface set in Dockerfile
# https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables

HUGGINGFACE_HUB_CACHE="/mnt/models"  ## This sets the vLLM Model download/load location
HUGGING_FACE_HUB_TOKEN=""            ## This sets the Huggingface API Token
HF_HOME="/nonexistent"               ## This set the default location if HUGGINGFACE_HUB_CACHE is unavailable
HF_HUB_OFFLINE="1"                   ## Set '1' prevents vLLM download Model from Huggingface site
HF_HUB_DISABLE_TELEMETRY="1"         ## AI Core does not allow Telemetry from the inference server
```

---

## Brief introduction of vLLM parameters

The following are the parameters from vLLM API Server using OpenAI Schema. 
Do check on the vLLM Documentation for more detail on this parameters.

**Note**: The list below is extracted from vLLM v0.2.6.

```shell
usage: api_server.py [-h] [--host HOST] [--port PORT] [--allow-credentials]
                     [--allowed-origins ALLOWED_ORIGINS]
                     [--allowed-methods ALLOWED_METHODS]
                     [--allowed-headers ALLOWED_HEADERS]
                     [--served-model-name SERVED_MODEL_NAME]
                     [--chat-template CHAT_TEMPLATE]
                     [--response-role RESPONSE_ROLE] [--model MODEL]
                     [--tokenizer TOKENIZER] [--revision REVISION]
                     [--tokenizer-revision TOKENIZER_REVISION]
                     [--tokenizer-mode {auto,slow}] [--trust-remote-code]
                     [--download-dir DOWNLOAD_DIR]
                     [--load-format {auto,pt,safetensors,npcache,dummy}]
                     [--dtype {auto,half,float16,bfloat16,float,float32}]
                     [--max-model-len MAX_MODEL_LEN] [--worker-use-ray]
                     [--pipeline-parallel-size PIPELINE_PARALLEL_SIZE]
                     [--tensor-parallel-size TENSOR_PARALLEL_SIZE]
                     [--max-parallel-loading-workers MAX_PARALLEL_LOADING_WORKERS]
                     [--block-size {8,16,32}] [--seed SEED]
                     [--swap-space SWAP_SPACE]
                     [--gpu-memory-utilization GPU_MEMORY_UTILIZATION]
                     [--max-num-batched-tokens MAX_NUM_BATCHED_TOKENS]
                     [--max-num-seqs MAX_NUM_SEQS]
                     [--max-paddings MAX_PADDINGS] [--disable-log-stats]
                     [--quantization {awq,gptq,squeezellm,None}]
                     [--enforce-eager]
                     [--max-context-len-to-capture MAX_CONTEXT_LEN_TO_CAPTURE]
                     [--engine-use-ray] [--disable-log-requests]
                     [--max-log-len MAX_LOG_LEN]

vLLM OpenAI-Compatible RESTful API server.

options:
  -h, --help            show this help message and exit
  --host HOST           host name
  --port PORT           port number
  --allow-credentials   allow credentials
  --allowed-origins ALLOWED_ORIGINS
                        allowed origins
  --allowed-methods ALLOWED_METHODS
                        allowed methods
  --allowed-headers ALLOWED_HEADERS
                        allowed headers
  --served-model-name SERVED_MODEL_NAME
                        The model name used in the API. If not specified, the
                        model name will be the same as the huggingface name.
  --chat-template CHAT_TEMPLATE
                        The file path to the chat template, or the template in
                        single-line form for the specified model
  --response-role RESPONSE_ROLE
                        The role name to return if
                        `request.add_generation_prompt=true`.
  --model MODEL         name or path of the huggingface model to use
  --tokenizer TOKENIZER
                        name or path of the huggingface tokenizer to use
  --revision REVISION   the specific model version to use. It can be a branch
                        name, a tag name, or a commit id. If unspecified, will
                        use the default version.
  --tokenizer-revision TOKENIZER_REVISION
                        the specific tokenizer version to use. It can be a
                        branch name, a tag name, or a commit id. If
                        unspecified, will use the default version.
  --tokenizer-mode {auto,slow}
                        tokenizer mode. "auto" will use the fast tokenizer if
                        available, and "slow" will always use the slow
                        tokenizer.
  --trust-remote-code   trust remote code from huggingface
  --download-dir DOWNLOAD_DIR
                        directory to download and load the weights, default to
                        the default cache dir of huggingface
  --load-format {auto,pt,safetensors,npcache,dummy}
                        The format of the model weights to load. "auto" will
                        try to load the weights in the safetensors format and
                        fall back to the pytorch bin format if safetensors
                        format is not available. "pt" will load the weights in
                        the pytorch bin format. "safetensors" will load the
                        weights in the safetensors format. "npcache" will load
                        the weights in pytorch format and store a numpy cache
                        to speed up the loading. "dummy" will initialize the
                        weights with random values, which is mainly for
                        profiling.
  --dtype {auto,half,float16,bfloat16,float,float32}
                        data type for model weights and activations. The
                        "auto" option will use FP16 precision for FP32 and
                        FP16 models, and BF16 precision for BF16 models.
  --max-model-len MAX_MODEL_LEN
                        model context length. If unspecified, will be
                        automatically derived from the model.
  --worker-use-ray      use Ray for distributed serving, will be automatically
                        set when using more than 1 GPU
  --pipeline-parallel-size PIPELINE_PARALLEL_SIZE, -pp PIPELINE_PARALLEL_SIZE
                        number of pipeline stages
  --tensor-parallel-size TENSOR_PARALLEL_SIZE, -tp TENSOR_PARALLEL_SIZE
                        number of tensor parallel replicas
  --max-parallel-loading-workers MAX_PARALLEL_LOADING_WORKERS
                        load model sequentially in multiple batches, to avoid
                        RAM OOM when using tensor parallel and large models
  --block-size {8,16,32}
                        token block size
  --seed SEED           random seed
  --swap-space SWAP_SPACE
                        CPU swap space size (GiB) per GPU
  --gpu-memory-utilization GPU_MEMORY_UTILIZATION
                        the percentage of GPU memory to be used forthe model
                        executor
  --max-num-batched-tokens MAX_NUM_BATCHED_TOKENS
                        maximum number of batched tokens per iteration
  --max-num-seqs MAX_NUM_SEQS
                        maximum number of sequences per iteration
  --max-paddings MAX_PADDINGS
                        maximum number of paddings in a batch
  --disable-log-stats   disable logging statistics
  --quantization {awq,gptq,squeezellm,None}, -q {awq,gptq,squeezellm,None}
                        Method used to quantize the weights. If None, we first
                        check the `quantization_config` attribute in the model
                        config file. If that is None, we assume the model
                        weights are not quantized and use `dtype` to determine
                        the data type of the weights.
  --enforce-eager       Always use eager-mode PyTorch. If False, will use
                        eager mode and CUDA graph in hybrid for maximal
                        performance and flexibility.
  --max-context-len-to-capture MAX_CONTEXT_LEN_TO_CAPTURE
                        maximum context length covered by CUDA graphs. When a
                        sequence has context length larger than this, we fall
                        back to eager mode.
  --engine-use-ray      use Ray to start the LLM engine in a separate process
                        as the server process.
  --disable-log-requests
                        disable logging requests
  --max-log-len MAX_LOG_LEN
                        max number of prompt characters or prompt ID numbers
                        being printed in log. Default: unlimited.
```

## References
* [Model Serving on AI Core](https://help.sap.com/docs/sap-ai-core/sap-ai-core-service-guide/use-your-model?locale=en-US)
The input parameters for *generate* can be referenced from:
* https://github.com/huggingface/transformers-bloom-inference/blob/main/inference_server/utils/requests.py#L12-L34
* https://vllm.readthedocs.io/en/latest/models/supported_models.html
* https://github.com/vllm-project/vllm

