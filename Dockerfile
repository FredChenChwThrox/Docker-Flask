#Version: 0.1
FROM reg.test.k8s/prog_lang/python:3.7.5-alpine3.10
MAINTAINER chenhw@asiainfo-sec.com
RUN cat /etc/passwd
ADD src/flask-demo /opt/xdr/flask-demo
ADD pkg/requirements.txt /opt/xdr/deps/requirements.txt
#RUN mkdir /opt/xdr/log
RUN pip install -r /opt/xdr/deps/requirements.txt
WORKDIR /opt/xdr/flask-demo/
RUN addgroup -S flaskusr && adduser -S flaskusr -G flaskusr
USER flaskusr
ENV FLASK_APP=app.py
CMD flask run --host=0.0.0.0
EXPOSE 5000
