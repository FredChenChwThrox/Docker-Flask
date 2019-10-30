#Version: 0.1
FROM python:3.7.5-alpine3.10
MAINTAINER chenhw@asiainfo-sec.com
RUN cat /etc/passwd
ADD src/flask-demo /opt/test/flask-demo
ADD pkg/requirements.txt /opt/test/deps/requirements.txt
RUN pip install -r /opt/test/deps/requirements.txt
WORKDIR /opt/test/flask-demo/
RUN addgroup -S flaskusr && adduser -S flaskusr -G flaskusr
USER flaskusr
ENV FLASK_APP=app.py
CMD flask run --host=0.0.0.0
EXPOSE 5000
