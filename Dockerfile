FROM ruby:alpine

COPY main.rb /app/
COPY src/* /app/src/
COPY config.yml /app/

ADD sample/cs531-test-files.tar.gz /app/web-root

WORKDIR /app
RUN chmod a+x main.rb

WORKDIR /app
ENTRYPOINT ["./main.rb"]
CMD ["80"]
