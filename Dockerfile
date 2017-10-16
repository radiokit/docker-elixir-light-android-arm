FROM ubuntu:xenial

ENV OTP_VERSION="19.3.6.1"
ENV REBAR_VERSION="2.6.4"
ENV REBAR3_VERSION="3.4.1"
ENV ELIXIR_VERSION="1.4.5"
ENV ANDROID_NDK_VERSION="r15c"
ENV ANDROID_API_VERSION="21"
ENV LANG=C.UTF-8
ENV CPATH=/usr/local/lib/erlang/usr/include/
ENV PATH="/usr/local/android_toolchain/bin:${PATH}"
ENV NDK_ROOT="android-ndk-${ANDROID_NDK_VERSION}"

RUN set -ex; \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    libssl-dev \
    make \
    patch \
    build-essential \
    wget \
    libncurses-dev \
    ca-certificates \
    unzip \
    python && \
  update-ca-certificates --fresh

RUN set -xe \
  && NDK_DOWNLOAD_URL="https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip" \
  && NDK_DOWNLOAD_SHA256="f01788946733bf6294a36727b99366a18369904eb068a599dde8cca2c1d2ba3c" \
  && wget -O ndk.zip "$NDK_DOWNLOAD_URL" \
  && echo "$NDK_DOWNLOAD_SHA256 ndk.zip" | sha256sum -c - \
  && unzip -o ndk.zip \
  && android-ndk-${ANDROID_NDK_VERSION}/build/tools/make_standalone_toolchain.py --arch arm --api ${ANDROID_API_VERSION} --install-dir /usr/local/android_toolchain

RUN set -xe \
  && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
  && OTP_DOWNLOAD_SHA256="79f7e116e8c7eb2a859706de8cea2bf11c67c97893c2bb451c3290f86885aabc" \
  && wget -O otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
  && echo "$OTP_DOWNLOAD_SHA256 otp-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/src/otp-src \
  && tar -xzf otp-src.tar.gz -C /usr/src/otp-src --strip-components=1 \
  && rm otp-src.tar.gz \
  && cd /usr/src/otp-src \
  && ./otp_build autoconf \
  && ./otp_build configure \
    --xcomp-conf=xcomp/erl-xcomp-arm-android.conf \
    --enable-dirty-schedulers \
    --enable-hipe \
    --disable-sctp \
    --without-javac \
    --with-ssl \
    --with-clock-resolution=high \
    --with-asn1 \
    --with-common_test \
    --with-eunit \
    --without-cosEvent \
    --without-cosEventDomain \
    --without-cosFileTransfer \
    --without-cosNotification \
    --without-cosProperty \
    --without-cosTime \
    --without-cosTransactions \
  && make -j$(nproc) \
  && make install \
  && find /usr/local -name examples | xargs rm -rf \
  && apt-get purge -y --auto-remove $buildDeps \
  && rm -rf /usr/src/otp-src /var/lib/apt/lists/*

# RUN set -xe \
#   && REBAR_DOWNLOAD_URL="https://github.com/rebar/rebar/archive/${REBAR_VERSION}.tar.gz" \
#   && REBAR_DOWNLOAD_SHA256="577246bafa2eb2b2c3f1d0c157408650446884555bf87901508ce71d5cc0bd07" \
#   && mkdir -p /usr/src/rebar-src \
#   && wget -O rebar-src.tar.gz "$REBAR_DOWNLOAD_URL" \
#   && echo "$REBAR_DOWNLOAD_SHA256 rebar-src.tar.gz" | sha256sum -c - \
#   && tar -xzf rebar-src.tar.gz -C /usr/src/rebar-src --strip-components=1 \
#   && rm rebar-src.tar.gz \
#   && cd /usr/src/rebar-src \
#   && ./bootstrap \
#   && install -v ./rebar /usr/local/bin/ \
#   && rm -rf /usr/src/rebar-src

# RUN set -xe \
#   && REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
#   && REBAR3_DOWNLOAD_SHA256="fa8b056c37ed3781728baf0fc5b1d87a31edbc5f8dd9b50a5d1ad92b0230e5dd" \
#   && mkdir -p /usr/src/rebar3-src \
#   && wget -O rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
#   && echo "$REBAR3_DOWNLOAD_SHA256 rebar3-src.tar.gz" | sha256sum -c - \
#   && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
#   && rm rebar3-src.tar.gz \
#   && cd /usr/src/rebar3-src \
#   && HOME=$PWD ./bootstrap \
#   && install -v ./rebar3 /usr/local/bin/ \
#   && rm -rf /usr/src/rebar3-src

# RUN set -xe \
#   && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/Precompiled.zip" \
#   && ELIXIR_DOWNLOAD_SHA256="a740e634e3c68b1477e16d75a0fd400237a46c62ceb5d04551dbc46093a03f98"\
#   && buildDeps=' \
#     unzip \
#   ' \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends $buildDeps \
#   && wget -O elixir-precompiled.zip $ELIXIR_DOWNLOAD_URL \
#   && echo "$ELIXIR_DOWNLOAD_SHA256 elixir-precompiled.zip" | sha256sum -c - \
#   && unzip -d /usr/local elixir-precompiled.zip \
#   && rm elixir-precompiled.zip \
#   && apt-get purge -y --auto-remove $buildDeps \
#   && rm -rf /var/lib/apt/lists/*

# RUN mix local.hex --force
# RUN mix local.rebar --force
