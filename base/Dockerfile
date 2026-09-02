FROM codercom/enterprise-base:ubuntu

USER root

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
        curl wget \
        ripgrep jq fzf \
        nano vim && \
    rm -rf /var/lib/apt/lists/*

USER coder