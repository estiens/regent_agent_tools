require 'rspec'
require_relative '../pubmed_tool/pubmed_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::PubMedTool do
  let(:tool) { described_class.new(email: 'test@example.com') }

  describe '#initialize' do
    it 'creates an instance of PubMedTool' do
      expect(tool).to be_an_instance_of(Regent::PubMedTool)
      expect(tool.name).to eq('pubmed')
    end

    it 'uses default email if not provided' do
      default_tool = described_class.new
      expect(default_tool.instance_variable_get(:@email)).to eq('your_email@example.com')
    end

    it 'sets max_results if provided' do
      custom_tool = described_class.new(max_results: 5)
      expect(custom_tool.instance_variable_get(:@max_results)).to eq(5)
    end
  end

  describe '#call' do
    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown PubMed action/)
      end
    end

    context 'with search_pubmed action' do
      it 'returns search results' do
        # Using a very common medical term that should always have results
        result = tool.call('search_pubmed', 'cancer', 3)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to be <= 3

        unless parsed.empty?
          article = parsed.first
          expect(article).to include('Published')
          expect(article).to include('Title')
          expect(article).to include('Summary')
        end
      end

      it 'handles empty results' do
        # Using a very unlikely search term
        result = tool.call('search_pubmed', 'xyznonexistenttermxyz123456789', 5)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed).to be_empty
      end
    end
  end
end
