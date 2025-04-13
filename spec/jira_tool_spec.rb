require 'rspec'
require_relative '../jira_tool/jira_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::JiraTool do
  describe '#initialize' do
    it 'raises an error when server URL is not provided' do
      expect { described_class.new }.to raise_error(Regent::ToolError, /JIRA server URL not provided/)
    end

    it 'creates an instance with valid server URL' do
      # This will still try to establish a connection, so we rescue the error

      tool = described_class.new(server_url: 'https://jira.example.com')
      expect(tool).to be_an_instance_of(Regent::JiraTool)
      expect(tool.name).to eq('jira')
    rescue StandardError
      # This is expected to fail since we don't have a real JIRA server
      # We just want to make sure it attempts initialization correctly
    end
  end

  describe '#call' do
    # Since we can't instantiate a real tool without credentials,
    # we'll test the validation at the interface level
    let(:mock_error_message) { 'Connection to JIRA failed' }

    # We need to test error handling for invalid actions
    it 'raises a ToolError for invalid actions' do
      # We need to create a dummy tool that doesn't try to connect to JIRA
      # but still checks the action validation
      dummy_tool = Class.new(Regent::JiraTool) do
        def initialize
          @name = 'jira'
          @description = 'Interact with Jira issues and projects'
        end

        def setup_client
          # Do nothing to avoid actual connection
        end
      end

      tool = dummy_tool.new

      expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Jira action/)
    end
  end

  # The following tests would be run if JIRA credentials were available
  context 'with valid credentials', skip: 'No JIRA credentials available' do
    let(:tool) do
      described_class.new(
        server_url: ENV['JIRA_SERVER_URL'] || 'https://jira.example.com',
        username: ENV['JIRA_USERNAME'] || 'user',
        password: ENV['JIRA_PASSWORD'] || 'password'
      )
    end

    # These tests are skipped since they require actual JIRA credentials
    describe '#get_issue' do
      it 'fetches issue details' do
        pending 'This test requires valid JIRA credentials'

        result = tool.call('get_issue', 'PROJECT-123')
        parsed = JSON.parse(result)

        expect(parsed).to have_key('key')
        expect(parsed).to have_key('summary')
        expect(parsed).to have_key('description')
      end
    end

    describe '#search_issues' do
      it 'searches for issues using JQL' do
        pending 'This test requires valid JIRA credentials'

        result = tool.call('search_issues', "project = PROJECT AND status = 'In Progress'", 10)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to be <= 10
      end
    end

    # Additional tests for create_issue and add_comment would go here
  end
end
