### builder
FROM arm32v7/debian:buster AS builder

ARG SCRCPY_VER=1.13
ARG SERVER_HASH="5fee64ca1ccdc2f38550f31f5353c66de3de30c2e929a964e30fa2d005d5f885"

RUN set -x \
        # update source
        && apt-get update \
        # client build dependencies
        && apt-get install -y curl gcc git pkg-config ninja-build \
        libavcodec-dev libavformat-dev libavutil-dev libsdl2-dev \
        && apt-get install -y python3-pip && pip3 install meson \
        # server build dependencies
        # && apt-get install -y default-jdk \
        # clean
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# RUN PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/bin
RUN curl -L -o scrcpy-server https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VER}/scrcpy-server-v${SCRCPY_VER}
RUN echo "$SERVER_HASH  /scrcpy-server" | sha256sum -c -
RUN git clone https://github.com/Genymobile/scrcpy.git
RUN cd scrcpy && meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=/scrcpy-server
RUN cd scrcpy/x && ninja

### runner
FROM arm32v7/debian:buster AS runner

LABEL maintainer="Niuren.Zhu <niuren.zhu@icloud.com>"

RUN set -x \
        # update source
        && apt-get update \
        # running dependencies
        && apt-get install -y adb ffmpeg \
        # clean
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

COPY --from=builder /scrcpy-server /usr/local/share/scrcpy/
COPY --from=builder /scrcpy/x/app/scrcpy /usr/local/bin/
