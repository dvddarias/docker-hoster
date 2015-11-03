FROM debian:8.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3.4 python3-pip \
    && pip3 install docker-py \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/dockerfiles"]
ENTRYPOINT ["/dockerfiles/entrypoint.sh"]

CMD ["python3"]



