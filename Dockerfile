FROM python:3.10.6-alpine3.16

RUN pip3 install docker
RUN mkdir /hoster
WORKDIR /hoster
ADD hoster.py /hoster/

CMD ["python3", "-u", "hoster.py"]