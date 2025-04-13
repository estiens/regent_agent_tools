require 'rspec'
require_relative '../google_search_tool/google_search_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::GoogleSearchTool do
  describe '#initialize' do
    it 'creates an instance of GoogleSearchTool' do
      tool = described_class.new
      expect(tool).to be_an_instance_of(Regent::GoogleSearchTool)
      expect(tool.name).to eq('google_search')
    end

    it 'sets default values' do
      tool = described_class.new
      expect(tool.instance_variable_get(:@num_results)).to eq(10)
    end
  end

  describe '#call' do
    let(:tool) { described_class.new }

    context 'when API key or CX is not provided' do
      it 'raises a ToolError for the search action' do
        expect { tool.call('search', 'test query') }.to raise_error(Regent::ToolError, /Google API key not provided/)
      end
    end

    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Google Search action/)
      end
    end

    # The following tests would be run if API keys were available
    context 'when API keys are provided', skip: 'No API keys available' do
      let(:tool) do
        # This would be used if we had actual API keys for testing
        described_class.new(
          api_key: ENV['GOOGLE_API_KEY'] || 'fake_key',
          cx: ENV['GOOGLE_CX'] || 'fake_cx'
        )
      end

      # With real API keys, we could test the search functionality
      it 'returns search results' do
        pending 'This test requires valid Google API credentials'

        result = tool.call('search', 'Ruby programming language', 3)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to be <= 3

        unless parsed.empty?
          first_result = parsed.first
          expect(first_result).to have_key('title')
          expect(first_result).to have_key('link')
          expect(first_result).to have_key('snippet')
        end
      end

      it 'handles date range filtering' do
        pending 'This test requires valid Google API credentials'

        # Test with date range
        result = tool.call('search', 'Ruby programming language', 3, 'past_week')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
      end
    end
  end
end
