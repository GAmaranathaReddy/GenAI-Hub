---
tags:
  - proxy-deployment
  - LiteLLm
---

# Proxy deployments: LiteLLM framework
## Introduction
### Remote Hosted Models:

In this approach, the LLM model is hosted on external servers or cloud infrastructure, allowing users to access and interact with the model through APIs over the internet. This is often used for applications where scalability and accessibility are essential.

### LiteLLM:

LiteLLM gives us the ability to handle requests for multiple LLM models that are hosted remotely through a single interface. To use LiteLLM for remote hosted models, you can implement proxy server that supports LiteLLM. More information on LiteLLM, benefits of using LiteLLM and our deployment strategy of the LiteLLM proxy on AI Core are listed in the next sections.

#### What is LiteLLM ?

LiteLLM simplifies calling LLM providers by providing a consistent input/output format for calling all models using the OpenAI format. It’s a middleware that acts as an intermediary between the client application and the language model API services such as Azure, Anthropic, OpenAI, and others. The primary purpose of LiteLLM Proxy is to streamline and simplify the process of making API calls to these services by providing a unified interface. Making it easy for you to add new models to your system in minutes (using the same exception-handling, token logic, etc. you already wrote for OpenAI).


#### Why LiteLLM ?

Calling multiple LLM providers involves messy code - each provider has it’s own package and different input/output. Langchain is too bloated and doesn’t provide consistent I/O across all LLM APIs. When we added support for multiple llms on our application. APIs can fail (e.g. Azure readtimeout errors), so we wrote a fallback strategy to iterate through a list of models in case one failed (e.g. if Azure fails, try Cohere first, OpenAI second etc.). Provider-specific implementations meant our for-loops became increasingly large (think: multiple ~100 line if/else statements), and since made LLM API calls in multiple places in our code, our debugging problems exploded. Because now we had multiple for-loop chunks across our codebase.

#### Who can benefit LiteLLM ?

Abstraction. That’s when LiteLLm decided to abstract our api calls behind a single class. We needed I/O that just worked, so we could spend time improving other parts of our system (error-handling/model-fallback logic, etc.). This class needed to do 3 things really well:

Consistent I/O Format: LiteLLM Proxy uses the OpenAI format for all models. This means that regardless of the LLM model you are interacting with, the format for sending requests and receiving responses remains consistent.
Handling requests for multiple LLM Models: The ability to handle requests for multiple LLM models. It can make /chat/completions requests for more than 50 LLM models, including Azure, OpenAI, Replicate, Anthropic, and Hugging Face.
Model fallbacks: Error handling is a crucial aspect of any application, and LiteLLM Proxy excels in this regard. It uses model fallbacks for error handling. If a model fails, it tries another model as a fallback.How to learn More about LiteLLM?
Please refer LiteLLM Document page for more information.

## PoC: Deploy LiteLLM Proxy
We are doing LiteLLM POC  for Explore on how to connect multiple LLM Providers, Deploy LiteLLM in Docker & AICore as proxy server and provide proxy server inference in OpenAI Format.

## Local Development
### Pre-requisite

- Python [Installation](https://www.python.org/downloads/)
- GitCLi [Installation](https://github.com/cli/cli#installation)
- Docker [Installation](https://docs.docker.com/engine/install/)

### Clone liteLLM from Litellm

Clone liteLLM server code  from Litellm Repo
```
git clone https://github.com/BerriAI/litellm.git
```
<b>Note:</b> Update the repo to support proxy deployment for finetuned models  if model serve support openai format lile vLLM library

### Prepare Docker Image
Default behaviour LiteLLM docker file is when you build Docker image it  will run automatically so we need to change the default behaviour to run docker when we use the run command
- Navigate to Docker file
- Comment the RUN command in docker file
- Add CMD commend to run docker file

### Build Docker Image
Open VS Integrated terminal from VS Studio code or Open command line navigate to project directory and Run below command to build a docker file

```
docker build  --platform linux/amd64 -t genai-platform-exp/litellm-proxy-poc:01 .
```
Now, verify if the image is built successfully.

To see the list of docker images, run the below command:

```
Docker images
```
### Run Docker Image

<b> Note: </b> Test docker image locally please add llm keys to secrets_template.toml or .env.

```
docker run -p 8000:8000 -d genai-platform-exp/litellm-proxy-poc:01
```
Note: Test docker image locally please add llm keys to secrets_template.toml.

Once run successfully we can see the running image id and also we can see local binding instance.

For swagger documentation (http://localhost:8000/)

### Push Docker Image

Before pushing to Docker repository, ensure you have logged in to the Docker Artifactory by following commands.

docker login dockerhub
provide your credentials for logging in (if logging in first time)

Push the docker image by running following command.

```
docker push genai-platform-exp/litellm-proxy-poc:01

```
- Navigate to project directory
- Docker push command
- Once successfully pushed you can find docker id
Check whether the newly created docker image is present in the Docker hub.

## AICore deployment
### Pre-requisite

Basic of [AICore & AILunch Pad](https://learning.sap.com/learning-journey/learning-how-to-use-the-sap-ai-core-service-on-sap-business-technology-platform)

### Generic Secrets
LiteLLM proxy-server always fetch llms authentication keys & configurations from environment variables to connect multiple llms. As per security standards we can add environments variables directly at project level. To Solve above security problem we can use AICore Generic secret to save llm authentication information. AICore Generic secret  accept only encoded format so we can resolve security problem also.

Create Generic secrets in AICore in two ways

- AI Launchpad ( URL )
- Postman Tool

### Serve Template

Serve template used for deploy litellm proxy application in AICore. LiteLLM required environment variable to connect multiple remote llm servers. AICore standards we can defined environment variables at serving template level. you can bind generic secret in Serve template.

- Executable ID – unique identifier of the workflow template
- Scenario ID: Give the scenario id:
- Resource plan: Specify resource configuration for Application
- Docker Registry secret:  name Docker registry which is already configured in AICore
- Docker Image: Provided the created docker image which was later pushed into artifactory.
- Environment variable: Name of the environment variable, this variable  available at application environment level
- Generic Secret: Name of the Generic secret to read reference value
- Generic Secret Key: Key name of the generic secret , it pair with encoded environment variable.

## Supported Providers Models

Litellm support [models](https://docs.litellm.ai/docs/providers)
