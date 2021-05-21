FROM debian:buster as build
RUN apt-get update
RUN apt-get install -y git build-essential cmake libuv1-dev libmicrohttpd-dev libssl-dev gcc-8 g++-8
ENV CC=gcc-8
ENV CXX=g++-8
RUN git clone https://github.com/NinjaCoin-Master/ninjarig.git /ninjarig
WORKDIR /ninjarig
COPY minDonation.patch minDonation.patch
RUN git apply minDonation.patch
RUN mkdir build
WORKDIR /ninjarig/build
# For CPU Only
RUN cmake -DWITH_CUDA=OFF -DWITH_OPENCL=OFF .. -DCMAKE_BUILD_TYPE=RELEASE
# For CPU and OpenCL
# RUN cmake -DWITH_CUDA=OFF .. -DCMAKE_BUILD_TYPE=RELEASE
# For CPU and CUDA
# RUN cmake -DWITH_OPENCL=OFF .. -DCMAKE_BUILD_TYPE=RELEASE
# For CPU, OpenCL, and CUDA
# RUN cmake .. -DCMAKE_BUILD_TYPE=RELEASE
RUN make
RUN make install

FROM debian:sid
COPY --from=build /usr/local/lib/libcpu_features.a /usr/local/lib/libcpu_features.a
COPY --from=build /usr/local/include/cpu_features/cpuinfo_aarch64.h /usr/local/include/cpu_features/cpuinfo_aarch64.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_arm.h /usr/local/include/cpu_features/cpuinfo_arm.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_mips.h /usr/local/include/cpu_features/cpuinfo_mips.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_ppc.h /usr/local/include/cpu_features/cpuinfo_ppc.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_x86.h /usr/local/include/cpu_features/cpuinfo_x86.h
COPY --from=build /usr/local/include/cpu_features/cpu_features_macros.h /usr/local/include/cpu_features/cpu_features_macros.h
COPY --from=build /usr/local/bin/list_cpu_features /usr/local/bin/list_cpu_features
COPY --from=build /usr/local/lib/cmake/CpuFeatures/CpuFeaturesTargets.cmake /usr/local/lib/cmake/CpuFeatures/CpuFeaturesTargets.cmake
COPY --from=build /usr/local/lib/cmake/CpuFeatures/CpuFeaturesTargets-release.cmake /usr/local/lib/cmake/CpuFeatures/CpuFeaturesTargets-release.cmake
COPY --from=build /usr/local/lib/cmake/CpuFeatures/CpuFeaturesConfig.cmake /usr/local/lib/cmake/CpuFeatures/CpuFeaturesConfig.cmake
COPY --from=build /usr/local/lib/cmake/CpuFeatures/CpuFeaturesConfigVersion.cmake /usr/local/lib/cmake/CpuFeatures/CpuFeaturesConfigVersion.cmake
RUN mkdir /ninjarig
WORKDIR /ninjarig
COPY --from=build /ninjarig/build/ninjarig ninjarig
COPY --from=build /ninjarig/build/modules modules
COPY --from=build /ninjarig/build/libargon2_common.so libargon2_common.so
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y libmicrohttpd12
COPY config.json config.json
EXPOSE 80
USER 1000:1000
CMD ["/ninjarig/ninjarig", "--config=config.json"]