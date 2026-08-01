# syntax=docker/dockerfile:1
FROM rust:1.88.0-slim-trixie AS builderrs

RUN apt-get update -qq && apt-get install -qq -y wget pkg-config libssl-dev clang git cmake libsonic-dev libpcaudio-dev && rustup component add rustfmt

WORKDIR /app

COPY . .
COPY Cargo.toml .
COPY Cargo.lock .

RUN chmod +x ./download_all.sh && ./download_all.sh

RUN cargo build --release

FROM debian:sid-slim AS runner

WORKDIR /app

COPY --from=builderrs /app/target/release/build ./target/release/build
COPY --from=builderrs /app/target/release/koko ./target/release/koko
COPY --from=builderrs /app/data ./data
COPY --from=builderrs /app/checkpoints ./checkpoints

RUN chmod +x ./target/release/koko && apt-get update -qq && apt-get install -qq -y pkg-config libssl-dev libsonic-dev libpcaudio-dev

# Expose is just for documentation, Railway handles dynamic port binding
EXPOSE 3000

# Run in a shell to expand the PORT environment variable assigned by Railway
CMD ./target/release/koko openai --port ${PORT:-3000} --ip 0.0.0.0
