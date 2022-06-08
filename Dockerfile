# syntax=docker/dockerfile:experimental
FROM --platform=$BUILDPLATFORM python:3.10.5-slim-buster@sha256:807f16dc51eb1ce7ed1178d82ebb60a41ad67fe74840a0bf6bf502368d4bdd47 AS build

# Theoretically the following requires --platform $(pyplatform) .. but
#  a) this doesn't work on the scapy package (no wheel) and
#  b) scapy and dependencies seem to be arch-neutral anyway.
# Look ma, no hands! :)
#ARG TARGETPLATFORM
#COPY pyplatform /usr/local/bin/
RUN pip install --user --compile scapy

FROM --platform=$BUILDPLATFORM python:3.10.5-slim-buster@sha256:807f16dc51eb1ce7ed1178d82ebb60a41ad67fe74840a0bf6bf502368d4bdd47 AS tcpdump

ARG TARGETPLATFORM

COPY debplatform /usr/local/bin/
RUN dpkg --add-architecture $(debplatform)
RUN apt-get update

RUN apt-get install -qy --no-install-recommends tcpdump:$(debplatform)

FROM python:3.10.5-slim-buster@sha256:807f16dc51eb1ce7ed1178d82ebb60a41ad67fe74840a0bf6bf502368d4bdd47

# Invoked by scapy to compile BPF filters
COPY --from=tcpdump /usr/sbin/tcpdump /usr/bin/
COPY --from=tcpdump /usr/lib/*/libpcap.so.* /usr/lib/*/libcrypto.so.* /usr/lib/

COPY --from=build /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
CMD ["scapy"]
