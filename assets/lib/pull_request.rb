require 'octokit'
require 'bitbucket_rest_api'

class PullRequest
  def self.from_git_api(repo:, id:)
    pr = if Commands::Base.bb
           Commands::Base.bb.repos.pull_request.get(Commands::Base.user, Commands::Base.repo, id)
         else
           Octokit.pull_request(repo.name, id)
         end
    PullRequest.new(pr: pr)
  end

  def initialize(pr:)
    @pr = pr
  end

  def from_fork?
    base_repo != head_repo
  end

  def equals?(id:, sha:)
    [self.sha, self.id.to_s] == [sha, id.to_s]
  end

  def to_json(*)
    as_json.to_json
  end

  def as_json
    { 'ref' => sha, 'pr' => id.to_s }
  end

  def branch_ref
    "pr-#{head_ref}"
  end

  def id
    Commands::Base.bb ? @pr['id'] :  @pr['number']
  end

  def sha
    Commands::Base.bb ? @pr['source']['commit']['hash'] : @pr['head']['sha']
  end

  def url
    Commands::Base.bb ? @pr['links']['html']['href'] : @pr['html_url']
  end

  def head_ref
    Commands::Base.bb ? @pr['source']['branch']['name'] : @pr['head']['ref']
  end

  def base_ref
    Commands::Base.bb ? @pr['destination']['branch']['name'] : @pr['base']['ref']
  end

  def pr
    @pr
  end

  private

  def base_repo
    Commands::Base.bb ? @pr['destination']['repository']['full_name'] : @pr['base']['repo']['full_name']
  end

  def head_repo
    Commands::Base.bb ? @pr['source']['repository']['full_name'] : @pr['head']['repo']['full_name']
  end
end
