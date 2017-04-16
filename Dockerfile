FROM alpine

RUN apk add --update \
  ruby \
  perl \
  jq \
  git \
  openssh-client \
  ruby-json \
  ca-certificates
RUN gem install octokit httpclient --no-rdoc --no-ri

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*


#docker build -t thaniyarasu/pr-base .
#FROM thaniyarasu/pr-base
#RUN gem install octokit httpclient --no-rdoc --no-ri
#COPY bitbucket_rest_api-0.1.7.gem /
#RUN gem install /bitbucket_rest_api-0.1.7.gem --no-rdoc --no-ri
#RUN rm /bitbucket_rest_api-0.1.7.gem
#RUN gem clean
#ADD assets/ /opt/resource/
#RUN chmod +x /opt/resource/*
#RUN rm -rf /var/cache/apk/*
