# --- Build ---
## Install elixir and erlang
FROM hexpm/elixir:1.18.4-erlang-28.0.2-alpine-3.22.1 AS build
WORKDIR /app

## Install elixir dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

## Copy source and compile
COPY lib lib
COPY config config
RUN MIX_ENV=prod mix release


# --- Run ---
## Use a minimal base image for the runtime
FROM alpine:3.22.1 AS app
WORKDIR /app

## Install OS packages (including OpenSSL 1.1 compat for Elixir)
RUN apk add --no-cache \
  libstdc++ \
  ncurses-libs \
  openssl

## Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/fwd_code_exercise .

## Start the application
CMD ["bin/fwd_code_exercise", "start"]
