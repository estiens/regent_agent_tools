require 'rspec'
require_relative '../hackernews_tool/hackernews_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::HackerNewsTool do
  let(:tool) { described_class.new }

  describe '#initialize' do
    it 'creates an instance of HackerNewsTool' do
      expect(tool).to be_an_instance_of(Regent::HackerNewsTool)
      expect(tool.name).to eq('hacker_news')
    end

    it 'sets default values' do
      expect(tool.instance_variable_get(:@get_top_stories)).to be true
      expect(tool.instance_variable_get(:@get_user_details)).to be true
    end
  end

  describe '#call' do
    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown HackerNews action/)
      end
    end

    context 'get_top_hackernews_stories' do
      it 'fetches top stories from Hacker News' do
        result = tool.call('get_top_hackernews_stories', 3)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to be <= 3

        unless parsed.empty?
          story = parsed.first
          expect(story).to have_key('id')
          expect(story).to have_key('title')
          # URL is optional as some stories are text posts
          expect(story).to have_key('score')
          expect(story).to have_key('username') # renamed from "by" in the tool
        end
      end
    end

    context 'get_user_details' do
      it 'fetches user details from Hacker News' do
        # Using "pg" (Paul Graham) as he's a well-known user that should exist
        result = tool.call('get_user_details', 'pg')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Hash)
        expect(parsed).to have_key('id')
        expect(parsed).to have_key('karma')
        expect(parsed).to have_key('about')
        expect(parsed).to have_key('total_items_submitted')

        expect(parsed['id']).to eq('pg')
        expect(parsed['karma']).to be_an(Integer)
        expect(parsed['karma']).to be > 0
      end

      it 'handles non-existent users' do
        # Using a random string that's unlikely to be a real user
        expect do
          tool.call('get_user_details', 'non_existent_user_12345678901234567890')
        end.to raise_error(Regent::ToolError)
      end
    end
  end
end
