# syntax=docker/dockerfile:experimental
FROM --platform=$BUILDPLATFORM python:3.10.8-slim-buster@sha256:e65113ae8e79dcf2d986bcf26d971ba5c1db2eeda96f5497b7912a433817ac42 AS build

# Theoretically the following requires --platform $(pyplatform) .. but
#  a) this doesn't work on the scapy package (no wheel) and
#  b) scapy and dependencies seem to be arch-neutral anyway.
# Look ma, no hands! :)
#ARG TARGETPLATFORM
#COPY pyplatform /usr/local/bin/
RUN pip install --user --compile scapy

FROM --platform=$BUILDPLATFORM python:3.10.8-slim-buster@sha256:e65113ae8e79dcf2d986bcf26d971ba5c1db2eeda96f5497b7912a433817ac42 AS tcpdump

ARG TARGETPLATFORM

COPY debplatform /usr/local/bin/
RUN dpkg --add-architecture $(debplatform)
RUN apt-get update

RUN apt-get install -qy --no-install-recommends tcpdump:$(debplatform)

FROM python:3.10.8-slim-buster@sha256:e65113ae8e79dcf2d986bcf26d971ba5c1db2eeda96f5497b7912a433817ac42

# Invoked by scapy to compile BPF filters
COPY --from=tcpdump /usr/sbin/tcpdump /usr/bin/
COPY --from=tcpdump /usr/lib/*/libpcap.so.* /usr/lib/*/libcrypto.so.* /usr/lib/

COPY --from=build /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
CMD ["scapy"]
