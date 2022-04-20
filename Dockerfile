ARG BASE_CONTAINER=ubuntu
ARG BASE_VERSION=latest
FROM ${BASE_CONTAINER}:${BASE_VERSION}

LABEL maintainer="phish108 <info@mobinaut.io>"
LABEL version="30"

USER root

# R pre-requisites
RUN echo "v0029-1" && \
    apt-get update --yes && \
    apt-get install -y --no-install-recommends \
      wget \
      ca-certificates \
      xorriso \
      p7zip-full \
      fakeroot \
      binutils \
      isolinux \
    && \
    apt-get autoremove --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY build.sh .
ENTRYPOINT ["/bin/bash", "/build.sh"]