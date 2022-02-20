FROM ubuntu:20.04 as base

# user data provided by the host system via the make file
# without these, the container will fail-safe and be unable to write output
ARG EPACTS_DIR

# Put the user name and ID into the ENV, so the runtime inherits them
ENV EPACTS_DIR=${EPACTS_DIR}

# Install OS updates, security fixes and utils, generic app dependencies
# htslib is libhts3 in Ubuntu see https://github.com/samtools/htslib/
RUN apt -y update -qq && apt -y upgrade && \
	DEBIAN_FRONTEND=noninteractive apt -y install \
		ca-certificates \
		dirmngr \
		ghostscript gnuplot \
		less libfile-pushd-perl libhts3 \
		r-base r-base-core r-recommended \
		software-properties-common \
		strace tabix wget xz-utils zlib1g

# The builder image starts here
FROM base as builder

# Now we are ready to set up the container containing study scripts
RUN set -x && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	automake \
	autoconf \
	build-essential \
	cmake \
	curl \
	gcc \
	git \
	groff \
	help2man \
	libedit2 \
	libbz2-dev \
	libcurl4-openssl-dev \
	libgsl-dev \
	liblzma-dev \
	libncurses5-dev \
	libncursesw5-dev \
	libssl-dev \
	libtool \
	libzstd-dev \
	lsb-release \
	make \
	python3 \
	python3-pip \
	pkg-config \
	zlib1g-dev \
	&& pip install cget

ARG SRC_DIR="/src/"
WORKDIR ${SRC_DIR}

# Package notes:
# epacts is from https://github.com/statgen/EPACTS
ARG EPACTS_URL="github.com/statgen/EPACTS/archive/refs/tags/"
ARG EPACTS_VER="3.4.2"

RUN wget https://${EPACTS_URL}/v${EPACTS_VER}.tar.gz && \
	tar xzf v${EPACTS_VER}.tar.gz && rm v${EPACTS_VER}.tar.gz && \
	cd EPACTS-${EPACTS_VER} && \
	cget install -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC" \
		-f requirements.txt && mkdir -p build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=${EPACTS_DIR} \
		-DCMAKE_TOOLCHAIN_FILE=../cget/cget/cget.cmake \
		-DCMAKE_BUILD_TYPE=Release .. && make && make install && \
		rm -r $SRC_DIR/EPACTS-${EPACTS_VER}

# This creates the actual container we will run
FROM base AS release
ENV PATH=${PATH}:${EPACTS_DIR}/bin

WORKDIR /runtime

# copy the applications from the builder image
COPY --from=builder $EPACTS_DIR/ $EPACTS_DIR/

RUN epacts download

ENTRYPOINT [ "epacts" ]
