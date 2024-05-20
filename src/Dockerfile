FROM nvcr.io/nvidia/pytorch:24.01-py3 AS runtime

WORKDIR /usr/src

RUN mkdir /nonexistent && \
    chmod 777 /nonexistent

# Install infinity-emb and its dependencies from PyPI and remove the cache to reduce the image size
# Update sthe infinity-emb version to the latest version if required
RUN python3 -m pip install --upgrade pip==23.2.1 && \
    python3 -m pip install "infinity-emb[all]==0.0.32" && \
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
