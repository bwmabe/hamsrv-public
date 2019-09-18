FROM ruby
COPY main.rb /app/
COPY rsc/* /app/rsc/
COPY src/* /app/src/
COPY config.yml /app/
WORKDIR /app
RUN chmod a+x main.rb

ENTRYPOINT ["./main.rb"]
CMD []
