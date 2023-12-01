FROM us-central1-docker.pkg.dev/webb-store/images/infrastructure/gamemaker-ubuntu-base:1.3.1

COPY dist ./

# Copy app version from build-args to env var
ARG APP_VERSION=build
ENV APP_VERSION=$APP_VERSION

EXPOSE 5000

CMD ["sh", "-c", "./webhost -noaudio"]
