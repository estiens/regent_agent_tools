# frozen_string_literal: true

module Regent
  # PubMed tool for Regent - provides access to medical and biomedical research papers
  class PubMedTool < Regent::Tool
    def initialize(name: "pubmed", description: "Search PubMed for medical research papers", **options)
      super(name: name, description: description)
      @email = options[:email] || "your_email@example.com"
      @max_results = options[:max_results]
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "search_pubmed"
        search_pubmed(arguments[1], arguments[2] || 10)
      else
        raise ToolError, "Unknown PubMed action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "PubMed tool error: #{e.message}"
    end

    private

    def search_pubmed(query, max_results = 10)
      require 'httparty'
      require 'nokogiri'
      
      begin
        # Use max_results from initialization if provided, otherwise use the argument
        max_results_to_use = @max_results || max_results
        
        # Fetch PubMed IDs
        ids = fetch_pubmed_ids(query, max_results_to_use, @email)
        
        # Fetch details for those IDs
        details_root = fetch_details(ids)
        
        # Parse the details
        articles = parse_details(details_root)
        
        # Format results
        results = articles.map do |article|
          "Published: #{article['Published']}\nTitle: #{article['Title']}\nSummary:\n#{article['Summary']}"
        end
        
        JSON.generate(results)
      rescue => e
        raise ToolError, "Could not fetch articles. Error: #{e.message}"
      end
    end

    def fetch_pubmed_ids(query, max_results, email)
      url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
      params = {
        db: "pubmed",
        term: query,
        retmax: max_results,
        email: email,
        usehistory: "y"
      }
      
      response = HTTParty.get(url, query: params)
      root = Nokogiri::XML(response.body)
      
      root.xpath("//Id").map(&:text)
    end

    def fetch_details(pubmed_ids)
      url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
      params = {
        db: "pubmed",
        id: pubmed_ids.join(","),
        retmode: "xml"
      }
      
      response = HTTParty.get(url, query: params)
      Nokogiri::XML(response.body)
    end

    def parse_details(xml_root)
      articles = []
      
      xml_root.xpath("//PubmedArticle").each do |article|
        pub_date = article.at_xpath(".//PubDate/Year")
        title = article.at_xpath(".//ArticleTitle")
        abstract = article.at_xpath(".//AbstractText")
        
        articles << {
          "Published" => pub_date&.text || "No date available",
          "Title" => title&.text || "No title available",
          "Summary" => abstract&.text || "No abstract available"
        }
      end
      
      articles
    end
  end
end
