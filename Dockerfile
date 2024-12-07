ARG CODENAME=focal
FROM ubuntu:$CODENAME
ARG CODENAME=$CODENAME

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
    update-ca-certificates -f

# Cmake Dependencies
RUN \
  apt install -y \
    librhash-dev \
    libcurl4-openssl-dev \
    libarchive-dev \
    libjsoncpp-dev \
    libuv1-dev

# https://apt.kitware.com/
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1A127079A92F09ED
# RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
# RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null
# RUN apt update  && \
#  apt-get install kitware-archive-keyring && \
#  apt install -y cmake
# The following signatures couldn't be verified because the public key is not
# available: NO_PUBKEY 1A127079A92F09ED

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

ARG CMAKE_VER=3.30.5
RUN \
  curl -LO https://github.com/Kitware/CMake/releases/download/v$CMAKE_VER/cmake-$CMAKE_VER.tar.gz && \
  tar xvf cmake-$CMAKE_VER.tar.gz && \
  cd cmake-$CMAKE_VER && \
  ./bootstrap \
    --prefix=/home/builder/.local \
    --system-libs \
    --no-system-cppdap \
    --parallel=$(nproc) && \
  make -j $(nproc) && make install && \
  cd .. && rm -rf cmake-"$CMAKE_VER"*

# So pip will not report about the path...
ENV PATH=/home/builder/.local/bin:$PATH
RUN python3 -m pip install pip --upgrade --user

# On arm/v7, pip can't install cmake from source, which is needed to build ninja
RUN python3 -m pip install meson ninja --upgrade --user

WORKDIR /home/builder

RUN \
  git clone --depth 1 --branch 2.0.0-alpha-1-20241106 https://github.com/linuxdeploy/linuxdeploy --recurse-submodules && \
    cd linuxdeploy && cp src/core/copyright/copyright.h src/core && \
    # On arm/v7, wget fails if --no-check-certificate isn't used
    sed -i 's/wget --quiet \"$url\" -O -/curl -o - \"$url\"/g' src/core/generate-excludelist.sh && \
    cmake . \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local \
      -DBUILD_TESTING=OFF \
      -DINSTALL_GTEST=OFF \
      -DBUILD_GMOCK=OFF && \
    ninja && ninja install linuxdeploy && cd .. && \
    rm -rf linuxdeploy
RUN \
  git clone --depth 1 --branch 1-alpha-20230713-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . -G Ninja -DCMAKE_INSTALL_PREFIX=$HOME/.local && ninja && ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage

ARG CODENAME
RUN \
  git clone --depth 1 --branch continuous https://github.com/AppImage/appimagetool.git && \
  cd appimagetool && \
  cmake . -DCMAKE_INSTALL_PREFIX=$HOME/.local && \
  make install && \
  sudo apt install -y libzstd-dev && \
  sed -i 's@wget https://github.com/plougher/squashfs-tools/archive/refs/tags/"$version".tar.gz -qO - | tar xvz --strip-components=1@curl -sL https://github.com/plougher/squashfs-tools/archive/refs/tags/"$version".tar.gz | tar xvz --strip-components=1@' ci/install-static-mksquashfs.sh && \
  sudo bash -euxo pipefail ci/install-static-mksquashfs.sh 4.6.1 && \
  cd .. && rm -rf appimagetool

WORKDIR /home/builder/.local/bin
RUN \
  curl -LO https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/3b67a1d1c1b0c8268f57f2bce40fe2d33d409cea/linuxdeploy-plugin-gtk.sh && \
  chmod +x linuxdeploy-plugin-gtk.sh

USER root
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt upgrade -y && \
  if [ "$CODENAME" = "focal" ];then \
    apt install -y \
      libgtk2.0-dev \
      libgtk-3-dev \
      nlohmann-json3-dev \
      qt5-default;  \
  else \
    apt install -y \
      libgtk2.0-dev \
      libgtk-3-dev \
      nlohmann-json3-dev \
      qtbase5-dev; \
  fi

USER builder
WORKDIR /home/builder
RUN \
  git clone \
    --branch 2.0.0-alpha-1-20241106 \
    --depth 1 \
    https://github.com/linuxdeploy/linuxdeploy-plugin-qt \
    --recurse-submodules && \
  cd linuxdeploy-plugin-qt && \
  # On arm/v7, wget fails if --no-check-certificate isn't used
  sed -i 's/wget --quiet \"$url\" -O -/curl -o - \"$url\"/g' lib/linuxdeploy/src/core/generate-excludelist.sh && \
  cmake . \
    -G Ninja \
    -DBUILD_GMOCK=OFF \
    -DBUILD_TESTING=OFF \
    -DINSTALL_GTEST=OFF \
    -DCMAKE_INSTALL_PREFIX=$HOME/.local && \
  ninja && ninja install && \
  cd .. && rm -rf linuxdeploy-plugin-qt

ENV DOCKER_BUILD=TRUE
USER root
WORKDIR /
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
