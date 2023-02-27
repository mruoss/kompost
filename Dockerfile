
ARG ERLANG_IMAGE
ARG ELIXIR_IMAGE
#########################
###### Build Image ######
#########################

FROM --platform=$BUILDPLATFORM ${ELIXIR_IMAGE} as builder

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

FROM --platform=$BUILDPLATFORM ${ERLANG_IMAGE}

# elixir expects utf8.
ENV LANG=C.UTF-8

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/kompost ./
RUN chown -R nobody: /app

LABEL org.opencontainers.image.source="https://github.com/mruoss/kompost"
LABEL org.opencontainers.image.authors="michael@michaelruoss.ch"

ENTRYPOINT ["/app/bin/kompost"]
CMD ["start"]

