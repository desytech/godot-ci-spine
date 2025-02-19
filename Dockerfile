FROM ubuntu:jammy
LABEL author="https://github.com/aBARICHELLO/godot-ci/graphs/contributors"

USER root
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    git-lfs \
    unzip \
    wget \
    zip \
    adb \
    openjdk-17-jdk-headless \
    rsync \
    wine64 \
    osslsigncode \
    && rm -rf /var/lib/apt/lists/*

# When in doubt, see the downloads page: https://downloads.tuxfamily.org/godotengine/
ARG GODOT_VERSION="4.3"

# Example values: stable, beta3, rc1, dev2, etc.
# Also change the `SUBDIR` argument below when NOT using stable.
ARG RELEASE_NAME="stable"

# This is only needed for non-stable builds (alpha, beta, RC)
# e.g. SUBDIR "/beta3"
# Use an empty string "" when the RELEASE_NAME is "stable".
ARG SUBDIR="4.2"

ARG GODOT_TEST_ARGS=""
ARG GODOT_PLATFORM="linux.x86_64"

ARG SPINE_GODOT_EDITOR_FILE="godot-editor-linux.zip"
ARG SPINE_GODOT_BINARY="godot-${SUBDIR}-${GODOT_VERSION}-${RELEASE_NAME}"

ARG SPINE_GODOT_TEMPLATES_FILE="spine-godot-templates-${SUBDIR}-${GODOT_VERSION}-${RELEASE_NAME}.tpz"

RUN wget https://spine-godot.s3.eu-central-1.amazonaws.com/${SUBDIR}/${GODOT_VERSION}-${RELEASE_NAME}/${SPINE_GODOT_EDITOR_FILE} \
    && wget https://spine-godot.s3.eu-central-1.amazonaws.com/${SUBDIR}/${GODOT_VERSION}-${RELEASE_NAME}/${SPINE_GODOT_TEMPLATES_FILE} \
    && mkdir ~/.cache \
    && mkdir -p ~/.config/godot \
    && mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && unzip ${SPINE_GODOT_EDITOR_FILE} \
    && mv ${SPINE_GODOT_BINARY} /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && unzip ${SPINE_GODOT_TEMPLATES_FILE} -d ~/.local/share/godot/export_templates/${GODOT_VERSION}.${RELEASE_NAME} \
    && rm -f ${SPINE_GODOT_TEMPLATES_FILE} ${SPINE_GODOT_EDITOR_FILE}

RUN whoami
RUN godot -v -e --quit --headless ${GODOT_TEST_ARGS}
# Godot editor settings are stored per minor version since 4.3.
# `${GODOT_VERSION:0:3}` transforms a string of the form `x.y.z` into `x.y`, even if it's already `x.y` (until Godot 4.9).
RUN echo '[gd_resource type="EditorSettings" format=3]' > ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo '[resource]' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres

# Download and set up rcedit to change Windows executable icons on export.
RUN wget https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe -O /opt/rcedit.exe
RUN echo 'export/windows/rcedit = "/opt/rcedit.exe"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
RUN echo 'export/windows/wine = "/usr/bin/wine64-stable"' >> ~/.config/godot/editor_settings-${GODOT_VERSION:0:3}.tres
