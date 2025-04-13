require 'rspec'
require_relative '../website_tool/website_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::WebsiteTool do
  let(:tool) { described_class.new }
  # Using example.com as a stable test site that should always be available
  let(:test_url) { 'http://example.com' }

  describe '#initialize' do
    it 'creates an instance of WebsiteTool' do
      expect(tool).to be_an_instance_of(Regent::WebsiteTool)
      expect(tool.name).to eq('website')
    end

    it 'sets default user agent' do
      expect(tool.instance_variable_get(:@user_agent)).to eq('Regent WebsiteTool/1.0')
    end

    it 'sets default timeout' do
      expect(tool.instance_variable_get(:@timeout)).to eq(30)
    end

    it 'allows custom user agent and timeout' do
      custom_tool = described_class.new(user_agent: 'Custom Agent', timeout: 60)
      expect(custom_tool.instance_variable_get(:@user_agent)).to eq('Custom Agent')
      expect(custom_tool.instance_variable_get(:@timeout)).to eq(60)
    end
  end

  describe '#call' do
    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Website action/)
      end
    end

    context 'with get_webpage action' do
      it 'fetches a webpage' do
        result = tool.call('get_webpage', test_url)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(test_url)
        expect(parsed['title']).to include('Example')
        expect(parsed['html']).to include('<html')
      end
    end

    context 'with extract_text action' do
      it 'extracts text from a webpage' do
        result = tool.call('extract_text', test_url)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(test_url)
        expect(parsed['title']).to include('Example')
        expect(parsed['headings']).to be_an_instance_of(Hash)
        expect(parsed['paragraphs']).to be_an_instance_of(Array)
        expect(parsed['full_text']).to be_a(String)

        expect(parsed['paragraphs'].first).to include('example') unless parsed['paragraphs'].empty?
      end
    end

    context 'with extract_links action' do
      it 'extracts links from a webpage' do
        result = tool.call('extract_links', test_url)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(test_url)
        expect(parsed['links']).to be_an_instance_of(Array)

        # The links on example.com may change, but there should be at least one
        # link to iana.org or similar
        unless parsed['links'].empty?
          # Check structure of at least one link
          link = parsed['links'].first
          expect(link).to have_key('text')
          expect(link).to have_key('url')
        end
      end
    end

    context 'with extract_tables action' do
      it 'extracts tables from a webpage' do
        # example.com doesn't typically have tables, so this may return empty results
        # but the structure should be valid
        result = tool.call('extract_tables', test_url)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(test_url)
        expect(parsed['tables']).to be_an_instance_of(Array)
      end

      it 'extracts tables from a webpage with tables' do
        # Wikipedia always has tables we can test against
        wikipedia_url = 'https://en.wikipedia.org/wiki/HTML'
        result = tool.call('extract_tables', wikipedia_url)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(wikipedia_url)
        expect(parsed['tables']).to be_an_instance_of(Array)
        expect(parsed['tables'].length).to be > 0

        # Check structure of first table
        unless parsed['tables'].empty?
          table = parsed['tables'].first
          expect(table).to have_key('index')
          expect(table).to have_key('headers')
          expect(table).to have_key('rows')
        end
      end
    end

    context 'with search_content action' do
      it 'finds content matching a query' do
        result = tool.call('search_content', test_url, 'example')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed['url']).to eq(test_url)
        expect(parsed['query']).to eq('example')
        expect(parsed['matches']).to be_an_instance_of(Array)
        expect(parsed['match_count']).to be > 0

        # Check matches structure
        unless parsed['matches'].empty?
          match = parsed['matches'].first
          expect(match).to have_key('tag')
          expect(match).to have_key('text')
          expect(match).to have_key('highlight')
          expect(match['highlight']).to include('**example**')
        end
      end
    end

    context 'with invalid URLs' do
      it 'raises an error for non-existent domains' do
        expect do
          tool.call('get_webpage', 'http://nonexistent-domain-for-testing-123456789.com')
        end.to raise_error(Regent::ToolError)
      end
    end
  end
end
