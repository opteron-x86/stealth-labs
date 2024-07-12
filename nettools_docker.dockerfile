FROM python:3.8-slim

RUN apt-get update && apt-get install -y iputils-ping traceroute

WORKDIR /app
COPY nettools.py /app

RUN pip install flask

CMD ["python", "nettools.py"]
