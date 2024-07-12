FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
    iputils-ping \
    traceroute \
    dnsutils \
    nmap \
    docker.io

WORKDIR /nettools
COPY . /nettools

RUN pip install flask


CMD ["python", "nettools.py"]
