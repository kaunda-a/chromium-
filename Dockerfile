FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    software-properties-common \
    git \
    curl \
    tar \
    xz-utils \
    libglib2.0-0 \
    libnss3 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-distutils \
    python3.11-dev \
    python3.11-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up Python 3.11
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 \
    && python3.11 -m pip install --no-cache-dir --upgrade pip

# Download and install Ungoogled Chromium
RUN wget -q https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/releases/download/134.0.6998.35-1/ungoogled-chromium_134.0.6998.35-1_linux.tar.xz \
    && echo "f20616cebbaac86ee357a7037da8e0450f0e5100e0ee3f09e53232490ddb722a ungoogled-chromium_134.0.6998.35-1_linux.tar.xz" | sha256sum --check \
    && tar xf ungoogled-chromium_134.0.6998.35-1_linux.tar.xz \
    && mkdir -p /usr/local/ungoogled-chromium \
    && mv ungoogled-chromium_134.0.6998.35-1_linux/* /usr/local/ungoogled-chromium/ \
    && ln -sf /usr/local/ungoogled-chromium/chrome /usr/local/bin/ungoogled-chromium \
    && rm ungoogled-chromium_134.0.6998.35-1_linux.tar.xz

# Set up the application directory
WORKDIR /app

# Copy project files
COPY pyproject.toml .
COPY components/ components/
COPY protection_system/ protection_system/
COPY config/ config/
COPY patches/ patches/

# Install build dependencies and project dependencies
RUN python3.11 -m pip install --no-cache-dir hatchling \
    && python3.11 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install --no-cache-dir -e .

# Set virtual environment in PATH
ENV PATH="/opt/venv/bin:$PATH"

# Initialize protection components
RUN python3.11 -m protection_system.initialize \
    --chrome-path=/usr/local/bin/ungoogled-chromium \
    --protection-level=maximum \
    --enable-all-features

