FROM alpine:3.10 as build
RUN apk update
RUN apk add git build-base cmake libuv-dev openssl-dev libmicrohttpd-dev
RUN git clone https://github.com/NinjaCoin-Master/ninjarig.git /ninjarig
WORKDIR /ninjarig
COPY minDonation.patch minDonation.patch
RUN git apply minDonation.patch
RUN mkdir build
WORKDIR /ninjarig/build
RUN cmake -DWITH_CUDA=OFF -DWITH_OPENCL=OFF .. -DCMAKE_BUILD_TYPE=RELEASE
RUN make
RUN make install

FROM alpine
RUN apk update
RUN apk add libuv libstdc++ openssl libmicrohttpd
COPY --from=build /usr/local/lib64/libcpu_features.a /usr/local/lib64/libcpu_features.a
COPY --from=build /usr/local/include/cpu_features/cpuinfo_aarch64.h /usr/local/include/cpu_features/cpuinfo_aarch64.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_arm.h /usr/local/include/cpu_features/cpuinfo_arm.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_mips.h /usr/local/include/cpu_features/cpuinfo_mips.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_ppc.h /usr/local/include/cpu_features/cpuinfo_ppc.h
COPY --from=build /usr/local/include/cpu_features/cpuinfo_x86.h /usr/local/include/cpu_features/cpuinfo_x86.h
COPY --from=build /usr/local/include/cpu_features/cpu_features_macros.h /usr/local/include/cpu_features/cpu_features_macros.h
COPY --from=build /usr/local/bin/list_cpu_features /usr/local/bin/list_cpu_features
COPY --from=build /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesTargets.cmake /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesTargets.cmake
COPY --from=build /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesTargets-release.cmake /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesTargets-release.cmake
COPY --from=build /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesConfig.cmake /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesConfig.cmake
COPY --from=build /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesConfigVersion.cmake /usr/local/lib64/cmake/CpuFeatures/CpuFeaturesConfigVersion.cmake
RUN mkdir /ninjarig
WORKDIR /ninjarig
COPY --from=build /ninjarig/build/ninjarig ninjarig
COPY --from=build /ninjarig/build/modules modules
COPY --from=build /ninjarig/build/libargon2_common.so libargon2_common.so
COPY config.json config.json
EXPOSE 80
USER 1000:1000
CMD ["/ninjarig/ninjarig", "--config=config.json"]