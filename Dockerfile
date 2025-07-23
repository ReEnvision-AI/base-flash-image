#FROM nvcr.io/nvidia/cuda:11.0.3-cudnn8-devel-ubuntu20.04
FROM nvcr.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
LABEL maintainer="ReEnvision-AI"
LABEL repository="base-flash-image"
LABEL org.opencontainers.image.source="https://github.com/ReEnvision-AI/base-flash-image"

WORKDIR /home
# Set en_US.UTF-8 locale by default
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment

# Install system packages, Python, and Ninja
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  software-properties-common \
  git \
  tzdata \
  ninja-build \
  && add-apt-repository -y ppa:deadsnakes/ppa \
  && apt-get update && apt-get install -y --no-install-recommends \
  python3.11 \
  python3.11-dev \
  python3.11-distutils \
  curl \
  && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
  && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 \
  && apt-get -y purge software-properties-common \
  && apt-get clean autoclean && rm -rf /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

# Install PyTorch
RUN pip install --no-cache-dir "torch==2.6.0" --index-url "https://download.pytorch.org/whl/cu124"

# Conditionally install flash attention using Ninja and all available CPU cores
ARG WITH_FLASH=true
RUN if [ "$WITH_FLASH" = "true" ]; then \
      echo "Installing flash-attn with Ninja..."; \
      MAX_JOBS=4 pip install -v --no-cache-dir "flash-attn==2.6.2" --use-pep517 --no-build-isolation; \
    fi
