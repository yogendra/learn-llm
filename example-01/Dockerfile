FROM python:3



RUN set -e \
  && mkdir /app

WORKDIR /app
  
ADD requirements.txt /app

RUN set -e \
  && pip install -r /app/requirements.txt \
  && apt-get update \
  && apt-get install -qqy libaio1 alien \
  && wget https://download.oracle.com/otn_software/linux/instantclient/2340000/oracle-instantclient-basiclite-23.4.0.24.05-1.el8.x86_64.rpm \
  && alien -i --scripts oracle-instantclient-basiclite-23.4.0.24.05-1.el8.x86_64.rpm \
  && rm oracle-instantclient-basiclite-23.4.0.24.05-1.el8.x86_64.rpm 

ADD . /app

ENTRYPOINT ["/bin/bash", "-c", "tail -f /dev/null"]
