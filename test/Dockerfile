FROM debian:stretch-slim
RUN apt-get update && apt-get install -y \
  curl \
  bash \
  netcat
COPY test.sh .
CMD [ "./test.sh" ]

# - ENV VARIABLES
ENV CFT_FQDN             127.0.0.1
