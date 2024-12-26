ARG CODENAME=focal
FROM ubuntu:$CODENAME
ARG CODENAME=focal
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && apt install -y \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    curl \
    desktop-file-utils \
    fuse \
    gettext \
    gpg \
    git \
    libcairo-dev \
    libfuse2 \
    libfuse-dev \
    libgcrypt-dev \
    libglib2.0-dev \
    libgpgme-dev \
    libjpeg-dev \
    libpng-dev \
    libssl-dev \
    libtool \
    patchelf \
    python3-pip \
    sudo \
    wget \
    xxd && \
    update-ca-certificates -f && \
  rm -rf /var/lib/apt/lists

RUN useradd -m builder && passwd -d builder
RUN echo "builder ALL=(ALL) ALL" >> /etc/sudoers
WORKDIR /home/builder

# This would get downloaded during the linuxdeploy cmake config,
# but we'll do it here to potentially help things along
RUN \
  git clone --depth=1 --branch v.3.3.3 https://github.com/GreycLab/CImg && \
  mv CImg/CImg.h /usr/include && \
  rm -rf CImg

USER builder

RUN \
  export CODENAME=$CODENAME && \
  test -f /usr/share/doc/kitware-archive-keyring/copyright || \
  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $CODENAME main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
  sudo apt-get update && \
  sudo apt install -y kitware-archive-keyring && \
  echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $CODENAME-rc main" | sudo tee -a /etc/apt/sources.list.d/kitware.list >/dev/null && \
  sudo apt update && \
  sudo apt install -y cmake

# So pip will not report about the path...
ENV PATH=/home/builder/.local/bin:$PATH
RUN python3 -m pip install pip --upgrade --user

# On arm/v7, pip can't install cmake from source, which is needed to build ninja
RUN python3 -m pip install meson ninja --upgrade --user

USER root
