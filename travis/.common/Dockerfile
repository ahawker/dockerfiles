# dockerfiles/travis
#
# Dockerfile for Travis CI CLI (https://github.com/travis-ci/travis.rb).
ARG REPO
ARG BASE_IMAGE
ARG TAG=latest

FROM $REPO/$BASE_IMAGE:$TAG

ARG LABEL_PREFIX
ARG TRAVIS_VERSION
ARG ALPINE_RUBY_DEV_PACKAGE_NAME
ARG ALPINE_RUBY_DEV_PACKAGE_VERSION
ARG ALPINE_RUBY_FFI_PACKAGE_NAME
ARG ALPINE_RUBY_FFI_PACKAGE_VERSION

RUN test -n "$LABEL_PREFIX" && \
    test -n "$ALPINE_RUBY_DEV_PACKAGE_NAME" && \
    test -n "$ALPINE_RUBY_DEV_PACKAGE_VERSION" && \
    test -n "$ALPINE_RUBY_FFI_PACKAGE_NAME" && \
    test -n "$ALPINE_RUBY_FFI_PACKAGE_VERSION"

LABEL $LABEL_PREFIX.travis.version=$TRAVIS_VERSION \
      $LABEL_PREFIX.alpine.ruby.dev.package.name=$ALPINE_RUBY_DEV_PACKAGE_NAME \
      $LABEL_PREFIX.alpine.ruby.dev.package.version=$ALPINE_RUBY_DEV_PACKAGE_VERSION \
      $LABEL_PREFIX.alpine.ruby.ffi.package.name=$ALPINE_RUBY_FFI_PACKAGE_NAME \
      $LABEL_PREFIX.alpine.ruby.ffi.package.version=$ALPINE_RUBY_FFI_PACKAGE_VERSION

ENV TRAVIS_VERSION=$TRAVIS_VERSION \
    ALPINE_RUBY_DEV_PACKAGE_NAME=$ALPINE_RUBY_DEV_PACKAGE_NAME \
    ALPINE_RUBY_DEV_PACKAGE_VERSION=$ALPINE_RUBY_DEV_PACKAGE_VERSION \
    ALPINE_RUBY_FFI_PACKAGE_NAME=$ALPINE_RUBY_FFI_PACKAGE_NAME \
    ALPINE_RUBY_FFI_PACKAGE_VERSION=$ALPINE_RUBY_FFI_PACKAGE_VERSION

USER root

RUN apk add --no-cache \
    git \
    $ALPINE_RUBY_DEV_PACKAGE_NAME="$ALPINE_RUBY_DEV_PACKAGE_VERSION" \
    $ALPINE_RUBY_FFI_PACKAGE_NAME="$ALPINE_RUBY_FFI_PACKAGE_VERSION"

USER $USR

RUN gem install travis --version $TRAVIS_VERSION
