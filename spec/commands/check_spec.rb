require_relative '../../assets/lib/commands/check'
require 'webmock/rspec'
require 'json'

describe Commands::Check do
  def check(payload)
    payload['source']['no_ssl_verify'] = true

    Input.instance(payload: payload)
    Commands::Check.new.output.map &:as_json
  end

  def stub_json(uri, body)
    stub_request(:get, uri)
      .to_return(headers: { 'Content-Type' => 'application/json' }, body: body.to_json)
  end

  context 'when targetting a base branch other than master' do
    before do
      stub_json('https://api.github.com/repos/jtarchie/test/statuses/abcdef', [])
      stub_json('https://api.github.com:443/repos/jtarchie/test/pulls?base=my-base-branch&direction=asc&per_page=100&sort=updated&state=open', [{ number: 1, head: { sha: 'abcdef' } }])
    end

    it 'retrieves pull requests for the specified base branch' do
      expect(check('source' => { 'repo' => 'jtarchie/test', 'base' => 'my-base-branch' })).to eq [{ 'ref' => 'abcdef', 'pr' => '1' }]
    end
  end

  context 'when there are no pull requests' do
    before do
      stub_json('https://api.github.com/repos/jtarchie/test/pulls?direction=asc&per_page=100&sort=updated&state=open', [])
    end

    it 'returns no versions' do
      expect(check('source' => { 'repo' => 'jtarchie/test' })).to eq []
    end

    context 'when there is a last known version' do
      it 'returns no versions' do
        payload = { 'version' => { 'ref' => '1' }, 'source' => { 'repo' => 'jtarchie/test' } }

        expect(check(payload)).to eq []
      end
    end
  end

  context 'when there is an open pull request' do
    before do
      stub_json('https://api.github.com:443/repos/jtarchie/test/pulls?direction=asc&per_page=100&sort=updated&state=open', [{ number: 1, head: { sha: 'abcdef' } }])
    end

    it 'returns SHA of the pull request' do
      expect(check('source' => { 'repo' => 'jtarchie/test' }, 'version' => {})).to eq [{ 'ref' => 'abcdef', 'pr' => '1' }]
    end

    context 'and the version is the same as the pull request' do
      it 'returns that pull request' do
        payload = { 'version' => { 'ref' => 'abcdef', 'pr' => '1' }, 'source' => { 'repo' => 'jtarchie/test' } }

        expect(check(payload)).to eq [
          { 'ref' => 'abcdef', 'pr' => '1' }
        ]
      end
    end
  end

  context 'when there is more than one open pull request' do
    before do
      stub_json('https://api.github.com/repos/jtarchie/test/pulls?direction=asc&per_page=100&sort=updated&state=open', [
                  { number: 1, head: { sha: 'abcdef', repo: { full_name: 'jtarchie/test' } }, base: { repo: { full_name: 'jtarchie/test' } } },
                  { number: 2, head: { sha: 'zyxwvu', repo: { full_name: 'someotherowner/repo' } }, base: { repo: { full_name: 'jtarchie/test' } } }
                ])
    end

    it 'returns all PRs oldest to newest last' do
      expect(check('source' => { 'repo' => 'jtarchie/test' }, 'version' => {})).to eq [
        { 'ref' => 'abcdef', 'pr' => '1' },
        { 'ref' => 'zyxwvu', 'pr' => '2' }
      ]
    end

    context 'and `disable_forks` is set to true' do
      it 'returns ' do
        expect(check('source' => { 'repo' => 'jtarchie/test', 'disable_forks' => true })).to eq [{ 'ref' => 'abcdef', 'pr' => '1' }]
      end
    end
  end
end
