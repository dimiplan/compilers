# Multi-stage Dockerfile for compilers image
# Each stage can be cached independently, preventing full rebuilds on errors

# Check for latest version here: https://hub.docker.com/_/buildpack-deps?tab=tags&page=1&ordering=last_updated
FROM buildpack-deps:stable AS base

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

# Stage 4: Build Octave (requires many dependencies)
FROM python-stage AS octave-stage
# Check for latest version here: https://ftpmirror.gnu.org/gnu/octave
ENV OCTAVE_VERSION=10.3.0
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends libopenblas-dev liblapack-dev libpcre2-dev libarpack2-dev \
    libcurl4-gnutls-dev epstool libfftw3-dev fig2dev libfltk1.3-dev \
    libfontconfig1-dev libfreetype-dev libgl2ps-dev libglpk-dev libreadline-dev \
    gnuplot libgraphicsmagick++1-dev libhdf5-dev openjdk-21-jdk libsndfile1-dev \
    llvm-dev texinfo libgl1-mesa-dev libosmesa6-dev pstoedit portaudio19-dev \
    libjack-jackd2-dev libqhull-dev libqrupdate-dev libqt5core5t64 qtbase5-dev \
    qttools5-dev qttools5-dev-tools libqscintilla2-qt5-dev libsuitesparse-dev \
    texlive texlive-latex-extra libxft-dev libsundials-dev && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://ftpmirror.gnu.org/gnu/octave/octave-$OCTAVE_VERSION.tar.gz" -o /tmp/octave.tar.gz && \
    mkdir /tmp/octave-build && \
    tar -xf /tmp/octave.tar.gz -C /tmp/octave-build --strip-components=1 && \
    rm /tmp/octave.tar.gz && \
    cd /tmp/octave-build && \
    ./configure \
      --prefix=/usr/local/octave-$OCTAVE_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 5: Install Java (OpenJDK)
FROM octave-stage AS java-stage
# Check for latest version here: https://jdk.java.net
RUN set -xe && \
    curl -fSsL "https://download.java.net/java/GA/jdk25.0.1/2fbf10d8c78e40bd87641c434705079d/8/GPL/openjdk-25.0.1_linux-x64_bin.tar.gz" -o /tmp/openjdk.tar.gz && \
    mkdir /usr/local/openjdk13 && \
    tar -xf /tmp/openjdk.tar.gz -C /usr/local/openjdk13 --strip-components=1 && \
    rm /tmp/openjdk.tar.gz && \
    ln -s /usr/local/openjdk13/bin/javac /usr/local/bin/javac && \
    ln -s /usr/local/openjdk13/bin/java /usr/local/bin/java && \
    ln -s /usr/local/openjdk13/bin/jar /usr/local/bin/jar

# Stage 6: Build Bash
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

# Stage 7: Build Free Pascal
FROM bash-stage AS fpc-stage
# Check for latest version here: https://www.freepascal.org/download.html
ENV FPC_VERSION=3.2.2
RUN set -xe && \
    curl -fSsL "http://downloads.freepascal.org/fpc/dist/$FPC_VERSION/x86_64-linux/fpc-$FPC_VERSION.x86_64-linux.tar" -o /tmp/fpc-$FPC_VERSION.tar && \
    mkdir /tmp/fpc-$FPC_VERSION && \
    tar -xf /tmp/fpc-$FPC_VERSION.tar -C /tmp/fpc-$FPC_VERSION --strip-components=1 && \
    rm /tmp/fpc-$FPC_VERSION.tar && \
    cd /tmp/fpc-$FPC_VERSION && \
    echo "/usr/local/fpc-$FPC_VERSION" | bash install.sh && \
    rm -rf /tmp/*

# Stage 8: Build Haskell (GHC)
FROM fpc-stage AS haskell-stage
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

# Stage 9: Build Mono (C#)
FROM haskell-stage AS mono-stage
# Check for latest version here: https://www.mono-project.com/download/stable
ENV MONO_VERSION=6.12.0.199
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends cmake && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://download.mono-project.com/sources/mono/mono-$MONO_VERSION.tar.xz" -o /tmp/mono.tar.xz && \
    mkdir /tmp/mono-build && \
    tar -xf /tmp/mono.tar.xz -C /tmp/mono-build --strip-components=1 && \
    rm /tmp/mono.tar.xz && \
    cd /tmp/mono-build && \
    ./configure \
      --prefix=/usr/local/mono-$MONO_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 10: Build Node.js
FROM mono-stage AS node-stage
# Check for latest version here: https://nodejs.org/en
ENV NODE_VERSION=24.11.0
RUN set -xe && \
    curl -fSsL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" -o /tmp/node.tar.gz && \
    mkdir /tmp/node-build && \
    tar -xf /tmp/node.tar.gz -C /tmp/node-build --strip-components=1 && \
    rm /tmp/node.tar.gz && \
    cd /tmp/node-build && \
    ./configure \
      --prefix=/usr/local/node-$NODE_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 11: Build Erlang
FROM node-stage AS erlang-stage
# Check for latest version here: https://github.com/erlang/otp/releases
ENV ERLANG_VERSION=28.1.1
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends unzip && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://github.com/erlang/otp/releases/download/OTP-$ERLANG_VERSION/otp_src_$ERLANG_VERSION.tar.gz" -o /tmp/erlang.tar.gz && \
    mkdir /tmp/erlang-build && \
    tar -xf /tmp/erlang.tar.gz -C /tmp/erlang-build --strip-components=1 && \
    rm /tmp/erlang.tar.gz && \
    cd /tmp/erlang-build && \
    ./otp_build autoconf && \
    ./configure \
      --prefix=/usr/local/erlang-$ERLANG_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/* && \
    ln -s /usr/local/erlang-$ERLANG_VERSION/bin/erl /usr/local/bin/erl

# Stage 12: Build Rust
FROM erlang-stage AS rust-stage
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

# Stage 13: Install Go
FROM rust-stage AS go-stage
# Check for latest version here: https://golang.org/dl
ENV GO_VERSION=1.25.3
RUN set -xe && \
    curl -fSsL "https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz" -o /tmp/go.tar.gz && \
    mkdir /usr/local/go-$GO_VERSION && \
    tar -xf /tmp/go.tar.gz -C /usr/local/go-$GO_VERSION --strip-components=1 && \
    rm -rf /tmp/*

# Stage 14: Install FreeBASIC
FROM go-stage AS fbc-stage
# Check for latest version here: https://sourceforge.net/projects/fbc/files/Binaries%20-%20Linux
ENV FBC_VERSION=1.10.1
RUN set -xe && \
    curl -fSsL "https://downloads.sourceforge.net/project/fbc/Binaries%20-%20Linux/FreeBASIC-$FBC_VERSION-linux-x86_64.tar.gz" -o /tmp/fbc.tar.gz && \
    mkdir /usr/local/fbc-$FBC_VERSION && \
    tar -xf /tmp/fbc.tar.gz -C /usr/local/fbc-$FBC_VERSION --strip-components=1 && \
    rm -rf /tmp/*

# Stage 15: Build OCaml
FROM fbc-stage AS ocaml-stage
# Check for latest version here: https://github.com/ocaml/ocaml/releases
ENV OCAML_VERSION=5.4.0
RUN set -xe && \
    curl -fSsL "https://github.com/ocaml/ocaml/releases/download/$OCAML_VERSION/$OCAML_VERSION.tar.gz" -o /tmp/ocaml.tar.gz && \
    mkdir /tmp/ocaml-build && \
    tar -xf /tmp/ocaml.tar.gz -C /tmp/ocaml-build --strip-components=1 && \
    rm /tmp/ocaml.tar.gz && \
    cd /tmp/ocaml-build && \
    ./configure \
      -prefix /usr/local/ocaml-$OCAML_VERSION \
      --disable-ocamldoc --disable-debugger && \
    make -j"$(nproc)" world.opt && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 16: Build PHP
FROM ocaml-stage AS php-stage
# Check for latest version here: https://www.php.net/downloads
ENV PHP_VERSION=8.4
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends bison re2c && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://codeload.github.com/php/php-src/tar.gz/php-$PHP_VERSION" -o /tmp/php.tar.gz && \
    mkdir /tmp/php-build && \
    tar -xf /tmp/php.tar.gz -C /tmp/php-build --strip-components=1 && \
    rm /tmp/php.tar.gz && \
    cd /tmp/php-build && \
    ./buildconf --force && \
    ./configure \
      --prefix=/usr/local/php-$PHP_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 17: Install D (DMD)
FROM php-stage AS d-stage
# Check for latest version here: https://dlang.org/download.html#dmd
ENV D_VERSION=2.111.0
RUN set -xe && \
    curl -fSsL "http://downloads.dlang.org/releases/2.x/$D_VERSION/dmd.$D_VERSION.linux.tar.xz" -o /tmp/d.tar.gz && \
    mkdir /usr/local/d-$D_VERSION && \
    tar -xf /tmp/d.tar.gz -C /usr/local/d-$D_VERSION --strip-components=1 && \
    rm -rf /usr/local/d-$D_VERSION/linux/*32 && \
    rm -rf /tmp/*

# Stage 18: Install Lua
FROM d-stage AS lua-stage
# Check for latest version here: https://www.lua.org/download.html
ENV LUA_VERSION=5.4.8
RUN set -xe && \
    curl -fSsL "https://downloads.sourceforge.net/project/luabinaries/$LUA_VERSION/Tools%20Executables/lua-${LUA_VERSION}_Linux44_64_bin.tar.gz" -o /tmp/lua.tar.gz && \
    mkdir /usr/local/lua-$LUA_VERSION && \
    tar -xf /tmp/lua.tar.gz -C /usr/local/lua-$LUA_VERSION && \
    rm -rf /tmp/* && \
    ln -s /lib/x86_64-linux-gnu/libreadline.so.7 /lib/x86_64-linux-gnu/libreadline.so.6

# Stage 19: Install TypeScript
FROM lua-stage AS typescript-stage
# Check for latest version here: https://github.com/microsoft/TypeScript/releases
ENV TYPESCRIPT_VERSION=5.9.3
RUN set -xe && \
    curl -fSsL "https://deb.nodesource.com/setup_22.x" | bash - && \
    apt update && \
    apt install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g typescript@$TYPESCRIPT_VERSION

# Stage 20: Build NASM
FROM typescript-stage AS nasm-stage
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

# Stage 21: Build GNU Prolog
FROM nasm-stage AS gprolog-stage
# Check for latest version here: http://gprolog.org/#download
ENV GPROLOG_VERSION=1.5.0
RUN set -xe && \
    curl -fSsL "http://gprolog.org/gprolog-$GPROLOG_VERSION.tar.gz" -o /tmp/gprolog.tar.gz && \
    mkdir /tmp/gprolog-build && \
    tar -xf /tmp/gprolog.tar.gz -C /tmp/gprolog-build --strip-components=1 && \
    rm /tmp/gprolog.tar.gz && \
    cd /tmp/gprolog-build/src && \
    ./configure \
      --prefix=/usr/local/gprolog-$GPROLOG_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install-strip && \
    rm -rf /tmp/*

# Stage 22: Install SBCL (Common Lisp)
FROM gprolog-stage AS sbcl-stage
# Check for latest version here: http://www.sbcl.org/platform-table.html
ENV SBCL_VERSION=2.5.10
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends bison re2c && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://downloads.sourceforge.net/project/sbcl/sbcl/$SBCL_VERSION/sbcl-$SBCL_VERSION-x86-64-linux-binary.tar.bz2" -o /tmp/sbcl.tar.bz2 && \
    mkdir /tmp/sbcl-build && \
    tar -xf /tmp/sbcl.tar.bz2 -C /tmp/sbcl-build --strip-components=1 && \
    cd /tmp/sbcl-build && \
    export INSTALL_ROOT=/usr/local/sbcl-$SBCL_VERSION && \
    sh install.sh && \
    rm -rf /tmp/*

# Stage 23: Build GnuCOBOL
FROM sbcl-stage AS cobol-stage
# Check for latest version here: https://ftpmirror.gnu.org/gnu/gnucobol
ENV COBOL_VERSION=3.2
RUN set -xe && \
    curl -fSsL "https://ftp.gnumirror.org/gnu/gnucobol/gnucobol-$COBOL_VERSION.tar.xz" -o /tmp/gnucobol.tar.xz && \
    mkdir /tmp/gnucobol-build && \
    tar -xf /tmp/gnucobol.tar.xz -C /tmp/gnucobol-build --strip-components=1 && \
    rm /tmp/gnucobol.tar.xz && \
    cd /tmp/gnucobol-build && \
    ./configure \
      --prefix=/usr/local/gnucobol-$COBOL_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 24: Install Swift
FROM cobol-stage AS swift-stage
# Check for latest version here: https://swift.org/download
ENV SWIFT_VERSION=6.2
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends libncurses5 && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://download.swift.org/swift-$SWIFT_VERSION-release/ubuntu2404/swift-$SWIFT_VERSION-RELEASE/swift-$SWIFT_VERSION-RELEASE-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz && \
    mkdir /usr/local/swift-$SWIFT_VERSION && \
    tar -xf /tmp/swift.tar.gz -C /usr/local/swift-$SWIFT_VERSION --strip-components=2 && \
    rm -rf /tmp/*

# Stage 25: Install Kotlin
FROM swift-stage AS kotlin-stage
# Check for latest version here: https://kotlinlang.org
ENV KOTLIN_VERSION=2.2.21
RUN set -xe && \
    curl -fSsL "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-compiler-$KOTLIN_VERSION.zip" -o /tmp/kotlin.zip && \
    unzip -d /usr/local/kotlin-$KOTLIN_VERSION /tmp/kotlin.zip && \
    mv /usr/local/kotlin-$KOTLIN_VERSION/kotlinc/* /usr/local/kotlin-$KOTLIN_VERSION/ && \
    rm -rf /usr/local/kotlin-$KOTLIN_VERSION/kotlinc && \
    rm -rf /tmp/*

# Stage 26: Install Clang and Objective-C support
FROM kotlin-stage AS clang-stage
# Check for latest version here: https://packages.debian.org/buster/clang-7
# Used for additional compilers for C, C++ and used for Objective-C.
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends clang-14 gnustep-devel && \
    rm -rf /var/lib/apt/lists/*

# Stage 27: Build R
FROM clang-stage AS r-stage
# Check for latest version here: https://cloud.r-project.org/src/base
ENV R_VERSION=4.5.2
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends libpcre2-dev && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fSsL "https://cloud.r-project.org/src/base/R-4/R-$R_VERSION.tar.gz" -o /tmp/r.tar.gz && \
    mkdir /tmp/r-build && \
    tar -xf /tmp/r.tar.gz -C /tmp/r-build --strip-components=1 && \
    rm /tmp/r.tar.gz && \
    cd /tmp/r-build && \
    ./configure \
      --prefix=/usr/local/r-$R_VERSION && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install && \
    rm -rf /tmp/*

# Stage 28: Install SQLite
FROM r-stage AS sqlite-stage
# Check for latest version here: https://packages.debian.org/buster/sqlite3
# Used for support of SQLite.
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# Stage 29: Install Scala
FROM sqlite-stage AS scala-stage
# Check for latest version here: https://scala-lang.org
ENV SCALA_VERSION=3.3.6
RUN set -xe && \
    curl -fSsL "https://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz" -o /tmp/scala.tgz && \
    mkdir /usr/local/scala-$SCALA_VERSION && \
    tar -xf /tmp/scala.tgz -C /usr/local/scala-$SCALA_VERSION --strip-components=1 && \
    rm -rf /tmp/*

# Stage 30: Build Clojure
FROM scala-stage AS clojure-stage
# Support for Perl came "for free" since it is already installed.
# Check for latest version here: https://github.com/clojure/clojure/releases
ENV CLOJURE_VERSION=1.12.3
RUN set -xe && \
    apt update && \
    apt install -y --no-install-recommends maven && \
    cd /tmp && \
    git clone https://github.com/clojure/clojure && \
    cd clojure && \
    git checkout clojure-$CLOJURE_VERSION && \
    mvn -Plocal -Dmaven.test.skip=true package && \
    mkdir /usr/local/clojure-$CLOJURE_VERSION && \
    cp clojure.jar /usr/local/clojure-$CLOJURE_VERSION && \
    apt remove --purge -y maven && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Stage 31: Install .NET SDK
FROM clojure-stage AS dotnet-stage
# Check for latest version here: https://github.com/dotnet/sdk/releases
RUN set -xe && \
    curl -fSsL "https://builds.dotnet.microsoft.com/dotnet/Sdk/9.0.306/dotnet-sdk-9.0.306-linux-x64.tar.gz" -o /tmp/dotnet.tar.gz && \
    mkdir /usr/local/dotnet-sdk && \
    tar -xf /tmp/dotnet.tar.gz -C /usr/local/dotnet-sdk && \
    rm -rf /tmp/*

# Stage 32: Install Groovy
FROM dotnet-stage AS groovy-stage
# Check for latest version here: https://groovy.apache.org/download.html
RUN set -xe && \
    curl -fSsL "https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips/apache-groovy-binary-5.0.2.zip" -o /tmp/groovy.zip && \
    unzip /tmp/groovy.zip -d /usr/local && \
    rm -rf /tmp/*

# Final stage: Add locale and isolate sandbox
FROM groovy-stage AS final
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
