FROM ruby:2.7

RUN apt-get update && \
    apt-get install -y mariadb-client locales ldap-utils

RUN sed -i '/en_GB\.UTF-8.*/s/^# *//' /etc/locale.gen && \
    locale-gen

ENV LANG=en_GB.UTF-8

RUN mkdir /app && \
    ln -s /app /opt/project

WORKDIR /app

RUN gem update --system && \
    gem install bundler

RUN curl -sL https://deb.nodesource.com/setup_15.x | bash - && \
    apt-get install -y nodejs && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn

COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN bundle install

RUN yarn install --frozen-lockfile --non-interactive

ADD scripts /
RUN chmod +x /entrypoint.sh

EXPOSE 3000
VOLUME /app
VOLUME /devise_cas_authenticatable

ENTRYPOINT ["/entrypoint.sh"]

CMD ["dev"]
