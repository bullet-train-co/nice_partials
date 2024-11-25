FROM gitpod/workspace-full
USER gitpod

RUN gem update --system && gem install bundler