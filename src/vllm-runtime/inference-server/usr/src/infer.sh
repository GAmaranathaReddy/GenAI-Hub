#!/bin/bash

# Inference Example
set -x
function normal() {
    URL=${HOST:-http://localhost:${PORT:-8000}}/generate

    # For vllm normal inference
    curl $URL \
        -H "Content-Type: application/json" \
        -d '{
            "prompt": "[INST] <<SYS>>\n\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature.\n\nIf a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you dont know the answer to a question, please dont share false information.\n<</SYS>>\n\nGive me a summary of \"John Carter\" movie.\n[/INST] ",
            "max_tokens": 7,
            "temperature": 0
        }'

}

function openai_chat() {
    MODEL_ID=${MODEL_ID:?Model is not selected. Please set Environment variable MODEL_ID}
    MODEL=${MODEL_SERVE_NAME:-${MODEL_ID/\//--}}
    URL=${HOST:-http://localhost:${PORT:-8000}}/v1/chat/completions

    # For vllm OpenAI inference
    curl -X POST $URL \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
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
}

function openai() {
    MODEL_ID=${MODEL_ID:?Model is not selected. Please set Environment variable MODEL_ID}
    MODEL=${MODEL_SERVE_NAME:-${MODEL_ID/\//--}}
    URL=${HOST:-http://localhost:${PORT:-8000}}/v1/completions

    # For vllm OpenAI inference
    curl -X POST $URL \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$MODEL\",
            \"prompt\": \"San Francisco is a\",
            \"max_tokens\": 7,
            \"temperature\": 0
        }"

}

${@}
