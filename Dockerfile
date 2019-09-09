FROM ruby
COPY echo_server.rb /app/
WORKDIR /app
RUN chmod a+x echo_server.rb

ENTRYPOINT ["./echo_server.rb"]
CMD []
