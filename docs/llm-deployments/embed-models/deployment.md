# Deploying Embedding Models on the AI Core with `infinity`

**The steps shown here will surely change in the future and the whole thing will get easier. This blog post is for early adopters and experts with a certain ability to suffer.**

[`infinity`](https://github.com/michaelfeil/infinity) is a fast and easy to use library for embedding model inference and serving with a permissive license. It comes with seamless integration with popular [Huggingface `transformers`](https://huggingface.co/docs/transformers/index) models.


## Checklist
 - [ ] Your model is compatible with [SentenceTransformers](https://huggingface.co/sentence-transformers)
 - [ ] Access to an AI Core instance with access to the required GPU resource plans

### Model Checkpoint

`infinity` supports a variety of generative transformer models in [Huggingface `transformers`](https://huggingface.co/docs/transformers/index).

A first simple check to see if your model checkpoint can be used with `infinity` is if it can be loaded using SentenceTransformer:

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("<your model>")
sentences = [
    "This framework generates embeddings for each input sentence",
    "Sentences are passed as a list of string.",
    "The quick brown fox jumps over the lazy dog.",
]
sentence_embeddings = model.encode(sentences)
```

### Preparing and Testing the Deployment Code

The next step is to interactively test the model checkpoint in infinity on a GPU machine.

```shell
$ pip install infinity-emb[all]
```
Going back to the example from earlier , running the mdoel would look like this:

```python
import asyncio
from infinity_emb import AsyncEmbeddingEngine, EngineArgs

sentences = ["Embed this is sentence via Infinity.", "Paris is in France."]
engine = AsyncEmbeddingEngine.from_args(EngineArgs(model_name_or_path = "<your-model>", engine="torch"))

async def main():
    async with engine: # engine starts with engine.astart()
        embeddings, usage = await engine.embed(sentences=sentences)
    # engine stops with engine.astop()
asyncio.run(main())
    print(f"Prompt: {prompt!r}, Generated text: {generated_text!r}")
```
Alternatively, we can start a server locally with the following command:
```
infinity_emb --model-name-or-path "<your-model>"
```
A test request can be sent like this:
```
curl http://localhost:8000/embeddings \
    -H "Content-Type: application/json" \
    -d '{
        "model": "<your-model>",
        "input": ["A sentence to encode."],
    }'
```
This is the type of server we will use on AI Core. The API provided by the server is compatible with the OpenAI API.

### Prepare AI Core Deployment

After validating that the model checkpoint can be used for a `infinity` server the next step is to start this server in an AI Core deployment. This requires three things:
1. A **deployment template** in a git repository onboarded to AI Core
2. A **model checkpoint** in an object store onboarded to AI Core
3. A **docker image** in a repository onboarded to AI Core

There are excellent resources on how to create an AI Core instance and how to complete the onboarding and thus we won't cover this here in this post.

#### Deployment Template

The following deployment template can be used and exposes the most important deployment options as parameters.

```yaml
apiVersion: ai.sap.com/v1alpha1
kind: ServingTemplate
metadata:
  name: nomic-embed ## This is the ServingTemplate's Name
  annotations:
    scenarios.ai.sap.com/description: "CPIT Hosted models on SAP AI Core" ## This is the scenario Name
    scenarios.ai.sap.com/name: "cpit-foundation-models"
    executables.ai.sap.com/description: "AI Core executable for CPIT Open-source LLMs"
    executables.ai.sap.com/name: "nomic-embed" ## This is the executables Name
  labels:
    scenarios.ai.sap.com/id: "ies-foundation-models"
    executables.ai.sap.com/id: "nomic-embed" # Adjust for your model
    ai.sap.com/version: "1.0.0"
    scenarios.ai.sap.com/llm: "true"
spec:
  inputs:
    parameters:
      - name: image
        type: "string"
        default: "XXX.common.repositories.cloud.sap/genai-platform-exp/ai-core-embed-model-serve:0.0.1" # This is the image used in JFrog, if you have not rebuilt this, it needs no adjustment.
      - name: resourcePlan
        type: "string"
        default: "infer2.4xl" # If the model does not require any specific hardware you can leave this see wiki page on vLLM.
      - name: tokenizer
        type: "string"
        default: ""
      - name: minReplicas
        type: "string"
        default: "1"
      - name: maxReplicas
        type: "string"
        default: "1"
      - name: portNumber
        type: "string"
        default: "9000"
      - name: gpu
        type: "string"
        default: "4"
      - name: trustRemoteCode
        type: "string"
        default: "true"
      - name: batchSize
        type: "string"
        default: "128"
      - name: urlPrefix
        type: "string"
        default: "/v1"
      - name: additionalArgument
        type: "string"
        default: ""
      - name: modelName
        type: "string"
        default: "nomic-ai/nomic-embed-text-v1.5" # This is the model name which later has to be used in the API call.
    artifacts:
    - name: nomicv15 # This is the name of your artifact, best to avoid any special characters like "-" or "_". You need to change this in the specs STORAGE_URI below.
  template:
    apiVersion: "serving.kserve.io/v1beta1"
    metadata:
      annotations: |
        autoscaling.knative.dev/metric: concurrency
        autoscaling.knative.dev/target: 1
        autoscaling.knative.dev/targetBurstCapacity: -1
        autoscaling.knative.dev/window: "10m"
        autoscaling.knative.dev/scaleToZeroPodRetentionPeriod: "10m"
      labels: |
        ai.sap.com/resourcePlan: "{{inputs.parameters.resourcePlan}}"
    spec: |
      predictor:
        imagePullSecrets:
        - name: dab-genai-platform-artifactory
        minReplicas: {{inputs.parameters.minReplicas}}
        maxReplicas: {{inputs.parameters.maxReplicas}}
        containers:
        - name: kserve-container
          image: "{{inputs.parameters.image}}"
          ports:
          - containerPort: {{inputs.parameters.portNumber}}
            protocol: TCP
          env:
          - name: STORAGE_URI
            value: "{{inputs.artifacts.nomicv15}}"
          - name: TRUST_REMOTE_CODE
            value: "{{inputs.parameters.trustRemoteCode}}"
          - name: BATCH_SIZE
            value: "{{inputs.parameters.batchSize}}"
          - name: URL_PRE_FIX
            value: "{{inputs.parameters.urlPrefix}}"
          - name: MODEL_SERVE_NAME
            value: "{{inputs.parameters.modelName}}"
          - name: ARG
            value: "{{inputs.parameters.additionalArgument}}"
          - name: HUGGINGFACE_HUB_CACHE
            value: "/mnt/models" # This is the path where the model will be stored in the container by default. Change this to '/nonexistent/models' for Huggingface Model Download
          volumeMounts:
          - name: shm
            mountPath: /dev/shm
        volumes:
        - name: shm
          emptyDir:
            medium: Memory
            sizeLimit: 10Gi
```
This workflow template is included in the repository ([`serve-emb-infinity.yaml`](../aicore-templates/serve-emb-infinity.yaml)).

#### Model weight download

download model weights. For example via:
```
mkdir nomic-embed-text-v1.5 && cd nomic-embed-text-v1.5
git lfs install
git clone https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
```

#### Model Checkpoint

Transfer your model checkpoint to an object store. For example via:
```
aws s3 cp --recursive <path-to-your-checkpoint-folder> s3://on-boarded-bucket/our-awesome-model/v1
```

Next we create an artifact for the checkpoint. Set `url` to `ai://{object-secret-name}/{path-rel-to-pathPrefix-of-the-secret}` and `scenarioId` to the value used in the deployment template:

```
{
  "labels": [],
  "name": "our-awesome-model/v1",
  "kind": "model",
  "url": "ai://s3-bucket/our-awesome-model/v1",
  "description": "Fantastic model",
  "scenarioId": "<your-scenario>"
}
```
The response to the `POST`-request contains an `artifactid` e.g. `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`.

#### Docker Image

The final missing piece is the docker image.

```Dockerfile
FROM nvcr.io/nvidia/pytorch:24.01-py3 AS runtime

WORKDIR /usr/src

RUN mkdir /nonexistent && \
    chmod 777 /nonexistent

RUN python3 -m pip install --upgrade pip==23.2.1 && \
    python3 -m pip install "infinity-emb[all]" && \
    rm -rf /root/.cache/pip

# These are environment variable from Huggingface
# https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables
ENV HUGGINGFACE_HUB_CACHE="/tmp" \
    HUGGING_FACE_HUB_TOKEN="" \
    HF_HOME="/nonexistent" \
    HF_HUB_OFFLINE="0" \
    HF_HUB_DISABLE_TELEMETRY="1" \
    SERVE_FILES_PATH="/mnt/models"

COPY run.sh /usr/src/run.sh
RUN chmod +x /usr/src/run.sh

CMD [ "/usr/src/run.sh" ]
```
This [Dockerfile](./Dockerfile) and the [`run.sh`-file](./run.sh) are part of this repo and both can be usable without modification. The `run.sh` file starts the `infinity` server using the template parameters. Once the docker image is built push it to the docker repository registered in AI Core under the name used as the replacement for `<your-docker-repo-secret>` in the workflow template. In the next step we will assume the image was push as `XXX.common.repositories.cloud.sap/ai-core-infinity-model-serve:0.0.1`.

### Start Deployment

To start the deployment we have to send a `POST`-request to `{apiurl}/v2/lm/configurations` to create a configuration:

```json
        {
            "executableId": "infinity-emb-model-serve",
            "inputArtifactBindings": [
                {
                    "artifactId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    "key": "embmodel"
                }
            ],
            "name": "nomic-embed-text-v1.5",
            "parameterBindings": [
                {
                    "key": "image",
                    "value": "XXX.common.repositories.cloud.sap/genai-platform-exp/ai-core-embed-model-serve:0.0.1"
                },
                {
                    "key": "batchSize",
                    "value": "256"
                },
                {
                    "key": "trustRemoteCode",
                    "value": "False"
                },
                {
                    "key": "portNumber",
                    "value": "9000"
                },
                {
                    "key": "resourcePlan",
                    "value": "infer2.l"
                },
                {
                    "key": "modelName",
                    "value": "nomic-ai/nomic-embed-text-v1.5"
                }
            ],
            "scenarioId": "llm-fine-tuning"
        }
```
The response to the request will contain a `configurationid`, e.g. `cccccccc-cccc-cccc-cccc-cccccccccccc`.

With this ID we can start the deployment by sending a `POST` request to `{apiurl}/v2/lm/configurations/cccccccc-cccc-cccc-cccc-cccccccccccc/deployments`.


### Use Deployment via `gen-ai-hub-sdk`

The deployment we created can be used in Python via [`generative-ai-hub-sdk`](https://github.wdf.sap.corp/AI/generative-ai-hub-sdk). Make sure that `generative-ai-hub-sdk` is [configured to use AI Core proxies](https://github.wdf.sap.corp/AI/generative-ai-hub-sdk/tree/main/docs/proxy).

The previous steps deploy an OpenAI-style server, so the deployment can be used via the OpenAI classes from the package. The only additional step is to tell the package which scenario and which configurations are embedding model deployments.

```python
from gen_ai_hub.proxy.native.openai import OpenAI
from gen_ai_hub.proxy.gen_ai_hub_proxy import GenAIHubProxyClient

GenAIHubProxyClient.add_foundation_model_scenario(
    scenario_id='<your-scenario>',
    config_names=["nomic-embed-text-*"],
    prediction_url_suffix='v1/embeddings'
)
```
This function instructs the client to treat all `RUNNING` deployments in the `<your-scenario>` scenario with a configuration name matching `nomic-embed-text-*` as a foundational model deployments and that the prediction url is the deployment url with `/v1/embeddings` as a suffix.

After running this function the models can be used in the same way as a centrally hosted model:

```python

proxy_client = GenAIHubProxyClient()
openai = OpenAI(proxy_client=proxy_client)

def get_detailed_instruct(task_description, query):
    return f'Instruct: {task_description}\nQuery: {query}'

# For "nomic-ai/nomic-embed-text-v1.5" each query must come with a one-sentence instruction that describes the task
task = 'Given a web search query, retrieve relevant passages that answer the query'
queries = [
    get_detailed_instruct(task, 'how much protein should a female eat'),
]
emb = openai.embeddings.create(model='nomic-ai/nomic-embed-text-v1.5', input=queries)
```

---

This post is designed to give you a head start on setting up your own embedding models on AI Core. When deploying models, there are many technical details that play a role and must be taken into account. Expect that the best way to deploy an embedding will change on a regular basis. Also, don't forget about the costs. You'll need to keep those models under high utilization if you want to keep your spending anywhere near what the big commercial companies charge.

