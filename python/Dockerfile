ARG VERSION
FROM python:$VERSION
COPY requirements.txt /
RUN pip install -r /requirements.txt
RUN rm -rf /var/lib/apt/lists/*
