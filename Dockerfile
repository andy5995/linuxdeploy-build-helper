ARG CODENAME=focal
FROM andy5995/linuxdeploy:dependencies-$CODENAME-latest
USER builder
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
  sudo apt install -y libcurl4-gnutls-dev && \
  git clone --depth 1 --branch 1-alpha-20230713-1 https://github.com/linuxdeploy/linuxdeploy-plugin-appimage --recurse-submodules && \
    cd linuxdeploy-plugin-appimage && \
    cmake . -G Ninja -DCMAKE_INSTALL_PREFIX=$HOME/.local && ninja && ninja install && cd .. && \
    rm -rf linuxdeploy-plugin-appimage

ARG CODENAME
RUN \
  git clone --depth 1 --branch main https://github.com/AppImage/appimagetool.git && \
  cd appimagetool && \
  git fetch --depth 1 origin feac85722a75471fe62a3fbb5fe54dbccbc83729 && \
  git checkout feac85722a75471fe62a3fbb5fe54dbccbc83729 && \
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

