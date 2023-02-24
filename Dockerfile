
ARG ERLANG_IMAGE_TAG
ARG ELIXIR_IMAGE_TAG
#########################
###### Build Image ######
#########################

FROM --platform=$BUILDPLATFORM hexpm/elixir:${ELIXIR_IMAGE_TAG} as builder

ENV MIX_ENV=prod \
  MIX_HOME=/opt/mix \
  HEX_HOME=/opt/hex

RUN mix local.hex --force && \
  mix local.rebar --force

WORKDIR /app

COPY mix.lock mix.exs ./
COPY config config

RUN mix deps.get --only-prod && \
    mix deps.clean --unused && \
    mix deps.compile

# COPY priv priv
COPY lib lib

RUN mix release

#########################
##### Release Image #####
#########################

FROM --platform=$BUILDPLATFORM hexpm/erlang:${ERLANG_IMAGE_TAG}

# elixir expects utf8.
ENV LANG=C.UTF-8

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/kompost ./
RUN chown -R nobody: /app

ENTRYPOINT ["/app/bin/kompost"]
CMD ["start"]

