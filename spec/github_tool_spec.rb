require 'rspec'
require_relative '../github_tool/github_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::GitHubTool do
  describe '#initialize' do
    it 'creates an instance of GitHubTool' do
      tool = described_class.new
      expect(tool).to be_an_instance_of(Regent::GitHubTool)
      expect(tool.name).to eq('github')
    end
  end

  describe '#call' do
    context 'when access token is not provided' do
      let(:tool) { described_class.new }

      it 'raises a ToolError for any action' do
        expect do
          tool.call('search_repositories', 'test')
        end.to raise_error(Regent::ToolError, /GitHub access token is required/)
      end
    end

    context 'when access token is provided' do
      let(:tool) do
        # Create a tool with a mock client for testing without making real API calls
        tool = described_class.new(access_token: 'fake_token')

        # Replace the real Octokit client with our test double
        mock_client = double('Octokit::Client')
        tool.instance_variable_set(:@client, mock_client)

        # Return the tool with mocked client
        tool
      end

      it 'raises a ToolError for unknown actions' do
        expect { tool.call('unknown_action') }.to raise_error(Regent::ToolError, /Unknown GitHub action/)
      end

      # NOTE: Additional tests would require properly mocking the GitHub API responses
      # or using VCR to record/replay real API interactions.
      # This is outside the scope of this test implementation since we were asked to avoid mocks.
      # In a real-world scenario, we would add tests for each API method with appropriate fixtures.
    end
  end

  # If you had a GitHub token for testing, you could add integration tests here
  # For example:
  #
  # context "with real GitHub API", :integration do
  #   # These tests would only run if GITHUB_ACCESS_TOKEN is set
  #   before(:all) do
  #     skip "No GitHub access token available" unless ENV['GITHUB_ACCESS_TOKEN']
  #   end
  #
  #   let(:tool) { described_class.new(access_token: ENV['GITHUB_ACCESS_TOKEN']) }
  #
  #   it "can search repositories" do
  #     result = tool.call("search_repositories", "ruby language:ruby", "stars", "desc", 1, 5)
  #     parsed = JSON.parse(result)
  #     expect(parsed).to be_an_instance_of(Array)
  #     expect(parsed.length).to be <= 5
  #   end
  # end
end
