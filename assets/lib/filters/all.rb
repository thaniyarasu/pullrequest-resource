require 'octokit'
require_relative '../pull_request'

module Filters
  class All
    def initialize(pull_requests: [], input: Input.instance)
      @input = input
    end

    def pull_requests
      @pull_requests = if Commands::Base.bb
                         tmp = Commands::Base.bb.repos.pull_request.list(Commands::Base.user, Commands::Base.repo).to_hash["values"]
                         tmp.map do |pr|
                           PullRequest.new(pr: pr)
                         end
                       else
                         Octokit.pulls(input.source.repo, pull_options).map do |pr|
                           PullRequest.new(pr: pr)
                         end
                       end
    end

    private

    attr_reader :input

    def pull_options
      options = { state: 'open', sort: 'updated', direction: 'asc' }
      options[:base] = input.source.base if input.source.base
      options
    end
  end
end
