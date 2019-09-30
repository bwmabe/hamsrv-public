FROM ruby:alpine

COPY main.rb /app/
COPY src/* /app/src/
COPY config.yml /app/

ADD sample/cs531-test-files.tar.gz /app/

WORKDIR /app

RUN chmod a+x main.rb \
	&&  wget https://github.com/ibnesayeed/cs531-webserver/raw/master/sample/cs531-test-files.tar.gz \
	&& tar -xzf *.tar.gz

ENTRYPOINT ["./main.rb"]
CMD []
