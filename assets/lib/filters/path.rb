require_relative '../input'

module Filters
  class Path
    def initialize(pull_requests:, input: Input.instance)
      @pull_requests = pull_requests
      @input = input
    end

    def pull_requests
      paths        = @input.source.paths || []
      ignore_paths = @input.source.ignore_paths || []

      return @pull_requests if paths.empty? && ignore_paths.empty?

      @memoized ||= @pull_requests.select do |pr|
        files = if Commands::Base.bb
                  #TODO : filter pull request based on changed file names , not yet supported by bitbucket
                else
                  Octokit.pull_request_files(@input.source.repo, pr.id)
                end
        unless paths.empty?
          files.select! do |file|
            paths.find do |path|
              File.fnmatch?(path, file['filename'])
            end
          end
        end
        unless ignore_paths.empty?
          files.reject! do |file|
            ignore_paths.find do |path|
              File.fnmatch?(path, file['filename'])
            end
          end
        end
        !files.empty?
      end
    end
  end
end
