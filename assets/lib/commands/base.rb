require 'faraday'
# httpclient and excon are the only Faraday adpater which support
# the no_proxy environment variable atm
# NOTE: this has to be set before require octokit
::Faraday.default_adapter = :httpclient

require 'octokit'
require 'bitbucket_rest_api'
require_relative '../input'

Hashie.logger = Logger.new(nil)
module Commands
  class Base
    attr_reader :input
    @@bb = @@user = @@repo = nil

    def initialize(input: Input.instance)
      @input = input
      if input.source.bitbucket
        @@bb = setup_bitbucket
      else
        setup_octokit
      end
    end
    def self.bb
      @@bb
    end
    def self.user
      @@user
    end
    def self.repo
      @@repo
    end

    private

    def setup_octokit
      Octokit.auto_paginate = true
      Octokit.connection_options[:ssl] = { verify: false } if input.source.no_ssl_verify
      Octokit.configure do |c|
        c.api_endpoint = input.source.api_endpoint if input.source.api_endpoint
        c.access_token = input.source.access_token
      end
    end

    def setup_bitbucket
      @@user, @@repo = input.source.repo.split("/")
      BitBucket.connection_options[:ssl] = { verify: false } if input.source.no_ssl_verify
      BitBucket.new(basic_auth: [input.source.user, input.source.access_token].join(':')) #'login:token'
    end

  end
end
