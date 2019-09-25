FROM ruby:alpine
COPY main.rb /app/
COPY src/* /app/src/
COPY config.yml /app/
WORKDIR /app
RUN chmod a+x main.rb

ENTRYPOINT ["./main.rb"]
CMD []
