FROM ruby:slim

ENV RACK_ENV production
ENV MAIN_APP_FILE app.rb
ENV APP_HOME /usr/src/app

RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME

RUN apt-get -qq update && \
    apt-get -qq -y install build-essential dnsutils curl --fix-missing --no-install-recommends

ADD Gemfile* $APP_HOME/
RUN bundle install

ADD app.rb $APP_HOME

EXPOSE 80

CMD ["ruby", "/usr/src/app/app.rb", "-p", "80"]
