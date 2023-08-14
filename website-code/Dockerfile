# syntax=docker/dockerfile:1

FROM python:3.8-slim-buster

WORKDIR /notes-deployment

RUN apt-get update
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2

COPY . .

EXPOSE 5000

CMD [ "python3", "main.py"]