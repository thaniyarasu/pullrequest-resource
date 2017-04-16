#!/usr/bin/env ruby

require 'English'
require 'json'
require_relative 'base'
require_relative '../pull_request'

module Commands
  class In < Commands::Base
    attr_reader :destination

    def initialize(destination:, input: Input.instance)
      @destination = destination
      @destination ||= 'repo' if ENV['DEV']
      super(input: input)
    end

    def output
      get_pull_reqs
      raise 'PR has merge conflicts' if @pr.pr['mergeable'] == false && fetch_merge
      unless input.params.skip
        system("git clone #{depth_flag} -b #{@pr.head_ref} #{uri} #{destination} 1>&2")
        raise 'git clone failed' unless $CHILD_STATUS.exitstatus.zero?

        Dir.chdir(destination) do
          if Commands::Base.bb.nil?
            raise 'git clone failed' unless system("git fetch -q origin pull/#{@pr.id}/#{remote_ref}:#{@pr.branch_ref} 1>&2")
            system("git checkout #{@pr.branch_ref} 1>&2")
          end
          system <<-BASH
          git config --add pullrequest.url #{@pr.url} 1>&2
          git config --add pullrequest.id #{@pr.id} 1>&2
          git config --add pullrequest.branch #{@pr.head_ref} 1>&2
          git config --add pullrequest.basebranch #{@pr.base_ref} 1>&2
          BASH

          case input.params.git.submodules
            when 'all', nil
              system("git submodule update --init --recursive #{depth_flag} 1>&2")
            when Array
              input.params.git.submodules.each do |path|
                system("git submodule update --init --recursive #{depth_flag} #{path} 1>&2")
              end
          end
        end
      end
    end

    {
        'version' => {'ref' => ref, 'pr' => @pr.id.to_s},
        'metadata' => [{'name' => 'url', 'value' => @pr.url}]
    }
  end

    private

    def get_pull_reqs
      pr0 ||= if Commands::Base.bb
                Commands::Base.bb.repos.pull_request.get(Commands::Base.user, Commands::Base.repo, input.version.pr)
              else
                Octokit.pull_request(input.source.repo, input.version.pr)
              end
      @pr = PullRequest.new(pr: pr0)
    end

    def uri
      return input.source.uri if input.source.uri
      if Commands::Base.bb
        #TODO : add pub key
        #"git@bitbucket.org:#{input.source.repo}.git"
        "https://#{input.source.user}:#{input.source.access_token}@bitbucket.org/#{input.source.repo}"
      else
        "https://github.com/#{input.source.repo}"
      end
    end

    def ref
      input.version.ref
    end

    def remote_ref
      fetch_merge ? 'merge' : 'head'
    end

    def fetch_merge
      input.params.fetch_merge
    end

    def depth_flag
      if depth = input.params.git.depth
        "--depth #{depth}"
      else
        ''
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  destination = ARGV.shift
  command = Commands::In.new(destination: destination)
  puts JSON.generate(command.output)
end
