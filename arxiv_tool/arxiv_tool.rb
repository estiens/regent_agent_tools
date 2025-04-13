require_relative "../regent_tool"
require 'fileutils'
require 'json'
require 'arxiv'
require 'open-uri'
require 'nokogiri'

module Regent
  # ArXiv tool for Regent - provides access to scientific papers from ArXiv
  class ArXivTool < Regent::Tool
    def initialize(name: "arxiv", description: "Search and read ArXiv scientific papers", **options)
      super(name: name, description: description)
      @download_dir = options[:download_dir] || File.join(Dir.pwd, "arxiv_pdfs")
      
      # Create download directory if it doesn't exist
      FileUtils.mkdir_p(@download_dir) unless Dir.exist?(@download_dir)
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "search_arxiv"
        search_arxiv_and_return_articles(arguments[1], arguments[2] || 10)
      when "read_arxiv_papers"
        read_arxiv_papers(arguments[1], arguments[2])
      else
        raise ToolError, "Unknown ArXiv action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "ArXiv tool error: #{e.message}"
    end

    private

    def search_arxiv_and_return_articles(query, num_articles = 10)
      articles = []
      
      # Use the ArXiv API directly
      url = "http://export.arxiv.org/api/query?search_query=all:#{URI.encode_www_form_component(query)}&start=0&max_results=#{num_articles}"
      response = Nokogiri::XML(URI.open(url)).remove_namespaces!
      
      entries = response.xpath('//entry')
      
      entries.each do |entry|
        title = entry.xpath('./title').text.strip
        id = entry.xpath('./id').text.strip.split('/').last
        summary = entry.xpath('./summary').text.strip
        
        authors = entry.xpath('./author/name').map { |author| author.text.strip }
        
        pdf_url = "https://arxiv.org/pdf/#{id}.pdf"
        
        published = entry.xpath('./published').text.strip
        
        primary_category = entry.xpath('./category').first['term'] if entry.xpath('./category').first
        
        categories = entry.xpath('./category').map { |cat| cat['term'] }
        
        article = {
          title: title,
          id: id,
          authors: authors,
          primary_category: primary_category,
          categories: categories,
          published: published,
          pdf_url: pdf_url,
          summary: summary,
          comment: entry.xpath('./comment').text.strip
        }
        
        articles << article
      end
      
      JSON.generate(articles)
    end

    def read_arxiv_papers(id_list, pages_to_read = nil)
      require 'pdf-reader'
      
      articles = []
      
      # Split the id list if multiple IDs are provided
      ids = id_list.to_s.split(',').map(&:strip)
      
      ids.each do |id|
        begin
          # Get the paper information using the ArXiv API directly
          url = "http://export.arxiv.org/api/query?id_list=#{id}"
          response = Nokogiri::XML(URI.open(url)).remove_namespaces!
          
          entry = response.xpath('//entry').first
          
          if entry
            title = entry.xpath('./title').text.strip
            summary = entry.xpath('./summary').text.strip
            authors = entry.xpath('./author/name').map { |author| author.text.strip }
            pdf_url = "https://arxiv.org/pdf/#{id}.pdf"
            published = entry.xpath('./published').text.strip
            primary_category = entry.xpath('./category').first['term'] if entry.xpath('./category').first
            categories = entry.xpath('./category').map { |cat| cat['term'] }
            
            article = {
              title: title,
              id: id,
              authors: authors,
              primary_category: primary_category,
              categories: categories,
              published: published,
              pdf_url: pdf_url,
              summary: summary,
              comment: entry.xpath('./comment').text.strip
            }
            
            if pdf_url
              # Download PDF
              pdf_path = File.join(@download_dir, "#{id}.pdf")
              download_pdf(pdf_url, pdf_path)
              
              # Extract text from PDF
              article["content"] = []
              
              begin
                reader = PDF::Reader.new(pdf_path)
                reader.pages.each_with_index do |page, index|
                  break if pages_to_read && (index + 1) > pages_to_read
                  
                  content = {
                    page: index + 1,
                    text: page.text
                  }
                  article["content"] << content
                end
              rescue => e
                article["content"] << {
                  page: 0,
                  text: "Error extracting PDF content: #{e.message}"
                }
              end
            end
          else
            article = {
              id: id,
              error: "Manuscript not found"
            }
          end
        rescue => e
          article = {
            id: id,
            error: "Error retrieving manuscript: #{e.message}"
          }
        end
        
        articles << article
      end
      
      JSON.generate(articles)
    end

    def download_pdf(url, path)
      require 'open-uri'
      
      File.open(path, "wb") do |file|
        # Use more permissive options to allow redirects
        uri_options = {
          redirect: true,
          allow_redirections: :all
        }
        file.write(URI.open(url, uri_options).read)
      end
      
      path
    end
  end
end
