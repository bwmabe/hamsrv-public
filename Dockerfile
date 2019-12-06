FROM ruby:alpine

RUN apk update; apk add perl

COPY main.rb /app/
COPY src/* /app/src/
COPY config.yml /app/
COPY *.conf /app/

ADD sample/cs531-test-files.tar.gz /app/web-root

WORKDIR /app
RUN chmod a+x main.rb

WORKDIR /app
ENTRYPOINT ["./main.rb"]
CMD ["80"]
