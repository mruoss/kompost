ARG ERLANG_IMAGE_TAG

FROM erlang:${ERLANG_IMAGE_TAG}

# elixir expects utf8.
ENV LANG=C.UTF-8

WORKDIR /app

CMD ["bin/kompost", "start"]

COPY rel/ ./

