# Multi-stage Dockerfile for compilers image
# Each stage can be cached independently, preventing full rebuilds on errors

# Check for latest version here: https://hub.docker.com/_/buildpack-deps?tab=tags&page=1&ordering=last_updated
FROM --platform=linux/amd64 buildpack-deps:stable AS base

# Stage 1: Build GCC compiler suite (C, C++, Fortran)
FROM base AS gcc-stage
# Check for latest version here: https://gcc.gnu.org/releases.html, https://ftpmirror.gnu.org/gcc
ENV GCC_VERSION=15.2.0
RUN set -xe && \
    curl -fSsL "https://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz" -o /tmp/gcc.tar.gz && \
    mkdir /tmp/gcc-build && \
    tar -xf /tmp/gcc.tar.gz -C /tmp/gcc-build --strip-components=1 && \
    rm /tmp/gcc.tar.gz && \
    cd /tmp/gcc-build && \
    ./contrib/download_prerequisites && \
    { rm *.tar.* || true; } && \
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    /tmp/gcc-build/configure \
    --disable-multilib \
    --enable-languages=c,c++ \
    --prefix=/usr/local/gcc-$GCC_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install-strip && \
    rm -rf /tmp/*

# Stage 2: Build Ruby
FROM gcc-stage AS ruby-stage
# Check for latest version here: https://www.ruby-lang.org/en/downloads
ENV RUBY_VERSION=3.4.7
RUN set -xe && \
    curl -fSsL "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-$RUBY_VERSION.tar.gz" -o /tmp/ruby.tar.gz && \
    mkdir /tmp/ruby-build && \
    tar -xf /tmp/ruby.tar.gz -C /tmp/ruby-build --strip-components=1 && \
    rm /tmp/ruby.tar.gz && \
    cd /tmp/ruby-build && \
    ./configure \
    --disable-install-doc \
    --prefix=/usr/local/ruby-$RUBY_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 3: Build Python
FROM ruby-stage AS python-stage
# Check for latest version here: https://www.python.org/downloads
ENV PYTHON_VERSION=3.14.0
RUN set -xe && \
    curl -fSsL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o /tmp/python.tar.xz && \
    mkdir /tmp/python-build && \
    tar -xf /tmp/python.tar.xz -C /tmp/python-build --strip-components=1 && \
    rm /tmp/python.tar.xz && \
    cd /tmp/python-build && \
    ./configure \
    --prefix=/usr/local/python-$PYTHON_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 4: Install Java (OpenJDK)
FROM ruby-stage AS java-stage
# Check for latest version here: https://jdk.java.net
RUN set -xe && \
    curl -fSsL "https://download.java.net/java/GA/jdk25.0.1/2fbf10d8c78e40bd87641c434705079d/8/GPL/openjdk-25.0.1_linux-x64_bin.tar.gz" -o /tmp/openjdk.tar.gz && \
    mkdir /usr/local/openjdk13 && \
    tar -xf /tmp/openjdk.tar.gz -C /usr/local/openjdk13 --strip-components=1 && \
    rm /tmp/openjdk.tar.gz && \
    ln -s /usr/local/openjdk13/bin/javac /usr/local/bin/javac && \
    ln -s /usr/local/openjdk13/bin/java /usr/local/bin/java && \
    ln -s /usr/local/openjdk13/bin/jar /usr/local/bin/jar

# Stage 5: Build Bash
FROM java-stage AS bash-stage
# Check for latest version here: https://ftpmirror.gnu.org/bash
ENV BASH_VERSION=5.3
RUN set -xe && \
    curl -fSsL "https://ftpmirror.gnu.org/bash/bash-$BASH_VERSION.tar.gz" -o /tmp/bash.tar.gz && \
    mkdir /tmp/bash-build && \
    tar -xf /tmp/bash.tar.gz -C /tmp/bash-build --strip-components=1 && \
    rm /tmp/bash.tar.gz && \
    cd /tmp/bash-build && \
    ./configure \
    --prefix=/usr/local/bash-$BASH_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*


# Stage 6: Build Haskell (GHC)
FROM bash-stage AS haskell-stage
# Check for latest version here: https://www.haskell.org/ghc/download.html
ENV HASKELL_VERSION=9.12.2
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends libgmp-dev libnuma-dev libncurses-dev  && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://downloads.haskell.org/~ghc/$HASKELL_VERSION/ghc-$HASKELL_VERSION-x86_64-deb12-linux.tar.xz" -o /tmp/ghc.tar.xz && \
    mkdir /tmp/ghc-build && \
    tar -xf /tmp/ghc.tar.xz -C /tmp/ghc-build --strip-components=1 && \
    rm /tmp/ghc.tar.xz && \
    cd /tmp/ghc-build && \
    ./configure \
    --prefix=/usr/local/ghc-$HASKELL_VERSION && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 7: Install Bun
FROM haskell-stage AS bun-stage
# Check for latest version here: https://github.com/oven-sh/bun/releases
ENV BUN_VERSION=1.3.1
RUN set -xe && \
    curl -fSsL "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip" -o /tmp/bun.zip && \
    unzip /tmp/bun.zip -d /tmp && \
    mkdir -p /usr/local/bun-$BUN_VERSION/bin && \
    mv /tmp/bun-linux-x64/bun /usr/local/bun-$BUN_VERSION/bin/bun && \
    chmod +x /usr/local/bun-$BUN_VERSION/bin/bun && \
    rm -rf /tmp/*

# Stage 8: Build Rust
FROM bun-stage AS rust-stage
# Check for latest version here: https://www.rust-lang.org
ENV RUST_VERSION=1.91.0
RUN set -xe && \
    curl -fSsL "https://static.rust-lang.org/dist/rust-$RUST_VERSION-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/rust.tar.gz && \
    mkdir /tmp/rust-build && \
    tar -xf /tmp/rust.tar.gz -C /tmp/rust-build --strip-components=1 && \
    rm /tmp/rust.tar.gz && \
    cd /tmp/rust-build && \
    ./install.sh \
    --prefix=/usr/local/rust-$RUST_VERSION \
    --components=rustc,rust-std-x86_64-unknown-linux-gnu && \
    rm -rf /tmp/*

# Stage 9: Install Go
FROM rust-stage AS go-stage
# Check for latest version here: https://golang.org/dl
ENV GO_VERSION=1.25.3
RUN set -xe && \
    curl -fSsL "https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz" -o /tmp/go.tar.gz && \
    mkdir /usr/local/go-$GO_VERSION && \
    tar -xf /tmp/go.tar.gz -C /usr/local/go-$GO_VERSION --strip-components=1 && \
    rm -rf /tmp/*

# Stage 10: Build NASM
FROM go-stage AS nasm-stage
# Check for latest version here: https://nasm.us
ENV NASM_VERSION=3.01
RUN set -xe && \
    curl -fSsL "https://www.nasm.us/pub/nasm/releasebuilds/$NASM_VERSION/nasm-$NASM_VERSION.tar.gz" -o /tmp/nasm.tar.gz && \
    mkdir /tmp/nasm-build && \
    tar -xf /tmp/nasm.tar.gz -C /tmp/nasm-build --strip-components=1 && \
    rm /tmp/nasm.tar.gz && \
    cd /tmp/nasm-build && \
    ./configure \
    --prefix=/usr/local/nasm-$NASM_VERSION && \
    make -j"$(nproc)" nasm ndisasm && \
    make -j"$(nproc)" strip && \
    make -j"$(nproc)" install && \
    echo "/usr/local/nasm-$NASM_VERSION/bin/nasm -o main.o \$@ && ld main.o" >> /usr/local/nasm-$NASM_VERSION/bin/nasmld && \
    chmod +x /usr/local/nasm-$NASM_VERSION/bin/nasmld && \
    rm -rf /tmp/*

# Stage 11: Install Swift
FROM nasm-stage AS swift-stage
# Check for latest version here: https://swift.org/download
ENV SWIFT_VERSION=6.2
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends libncurses6 && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://download.swift.org/swift-$SWIFT_VERSION-release/ubuntu2404/swift-$SWIFT_VERSION-RELEASE/swift-$SWIFT_VERSION-RELEASE-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz && \
    mkdir /usr/local/swift-$SWIFT_VERSION && \
    tar -xf /tmp/swift.tar.gz -C /usr/local/swift-$SWIFT_VERSION --strip-components=2 && \
    rm -rf /tmp/*

# Stage 12: Install Kotlin
FROM swift-stage AS kotlin-stage
# Check for latest version here: https://kotlinlang.org
ENV KOTLIN_VERSION=2.2.21
RUN set -xe && \
    curl -fSsL "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-compiler-$KOTLIN_VERSION.zip" -o /tmp/kotlin.zip && \
    unzip -d /usr/local/kotlin-$KOTLIN_VERSION /tmp/kotlin.zip && \
    mv /usr/local/kotlin-$KOTLIN_VERSION/kotlinc/* /usr/local/kotlin-$KOTLIN_VERSION/ && \
    rm -rf /usr/local/kotlin-$KOTLIN_VERSION/kotlinc && \
    rm -rf /tmp/*

# Stage 13: Install Clang and Objective-C support
FROM kotlin-stage AS clang-stage
# Check for latest version here: https://packages.debian.org/buster/clang-7
# Used for additional compilers for C, C++ and used for Objective-C.
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends clang-19 gnustep-devel && \
    rm -rf /var/lib/apt/lists/*

# Stage 14: Install SQLite
FROM clang-stage AS sqlite-stage
# Check for latest version here: https://packages.debian.org/buster/sqlite3
# Used for support of SQLite.
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# Final stage: Add locale and isolate sandbox
FROM sqlite-stage AS final
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends locales && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends git libcap-dev && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/judge0/isolate.git /tmp/isolate && \
    cd /tmp/isolate && \
    git checkout ad39cc4d0fbb577fb545910095c9da5ef8fc9a1a && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*
ENV BOX_ROOT=/var/local/lib/isolate

LABEL maintainer="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL version="1.4.0"
