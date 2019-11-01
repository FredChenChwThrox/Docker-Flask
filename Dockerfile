#Version: 0.1
FROM python:3.7.5-alpine3.10
MAINTAINER fred_chen chw_throx@163.com
ADD src/flask_demo /opt/test/flask_demo
ADD pkg/requirements.txt /opt/test/deps/requirements.txt
RUN pip install -r /opt/test/deps/requirements.txt
WORKDIR /opt/test/flask_demo/
RUN addgroup -S flaskusr && adduser -S flaskusr -G flaskusr
USER flaskusr
ENV FLASK_APP=app.py
CMD flask run --host=0.0.0.0
EXPOSE 5000
