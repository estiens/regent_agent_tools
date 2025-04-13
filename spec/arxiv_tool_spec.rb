require "rspec"
require_relative "../arxiv_tool/arxiv_tool"
require "fileutils"
require "json"

RSpec.describe Regent::ArXivTool do
  let(:tool) { described_class.new(download_dir: "/tmp/arxiv_test_#{Time.now.to_i}") }

  after(:each) do
    FileUtils.rm_rf(tool.instance_variable_get(:@download_dir)) if Dir.exist?(tool.instance_variable_get(:@download_dir))
  end

  describe "#initialize" do
    it "creates an instance of ArXivTool" do
      expect(tool).to be_an_instance_of(Regent::ArXivTool)
      expect(tool.name).to eq("arxiv")
    end

    it "creates the download directory" do
      expect(Dir.exist?(tool.instance_variable_get(:@download_dir))).to be true
    end
  end

  describe "#call with search_arxiv" do
    it "returns formatted search results for quantum computing" do
      result = tool.call("search_arxiv", "quantum computing", 2)
      parsed = JSON.parse(result)

      expect(parsed).to be_an_instance_of(Array)
      expect(parsed.length).to be >= 1

      article = parsed.first
      expect(article).to have_key("title")
      expect(article).to have_key("authors")
      expect(article).to have_key("summary")
      expect(article).to have_key("pdf_url")
      expect(article["title"]).to be_a(String)
      expect(article["authors"]).to be_an(Array)
    end
  end

  describe "#call with invalid action" do
    it "raises a ToolError" do
      expect { tool.call("invalid_action") }.to raise_error(StandardError)
    end
  end
end
