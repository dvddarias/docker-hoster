# syntax=docker/dockerfile:1

ARG BASE_IMAGE=docker.io/library/python:3-alpine
ARG APP_DIR=/hoster

FROM ${BASE_IMAGE}

RUN pip3 install docker

ARG APP_DIR=/hoster
WORKDIR ${APP_DIR}

ADD hoster.py ./

CMD ["python3", "-u", "hoster.py"]
# CMD "whoami"
