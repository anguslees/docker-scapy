# syntax=docker/dockerfile:experimental
FROM --platform=$BUILDPLATFORM python:3.10.4-slim-buster@sha256:48c4a798972f30b485fea59076ec186644da63c1845f38e32b6c2fada51e7144 AS build

# Theoretically the following requires --platform $(pyplatform) .. but
#  a) this doesn't work on the scapy package (no wheel) and
#  b) scapy and dependencies seem to be arch-neutral anyway.
# Look ma, no hands! :)
#ARG TARGETPLATFORM
#COPY pyplatform /usr/local/bin/
RUN pip install --user --compile scapy

FROM --platform=$BUILDPLATFORM python:3.10.4-slim-buster@sha256:48c4a798972f30b485fea59076ec186644da63c1845f38e32b6c2fada51e7144 AS tcpdump

ARG TARGETPLATFORM

COPY debplatform /usr/local/bin/
RUN dpkg --add-architecture $(debplatform)
RUN apt-get update

RUN apt-get install -qy --no-install-recommends tcpdump:$(debplatform)

FROM python:3.10.4-slim-buster@sha256:48c4a798972f30b485fea59076ec186644da63c1845f38e32b6c2fada51e7144

# Invoked by scapy to compile BPF filters
COPY --from=tcpdump /usr/sbin/tcpdump /usr/bin/
COPY --from=tcpdump /usr/lib/*/libpcap.so.* /usr/lib/*/libcrypto.so.* /usr/lib/

COPY --from=build /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
CMD ["scapy"]
