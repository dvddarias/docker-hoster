FROM frolvlad/alpine-python3

RUN pip3 install docker-py
RUN mkdir /hoster
WORKDIR /hoster
COPY ./hoster.py .

CMD ["python3", "hoster.py"]



