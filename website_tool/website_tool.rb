# frozen_string_literal: true

module Regent
  # Website tool for Regent - provides web scraping and interaction capabilities
  class WebsiteTool < Regent::Tool
    def initialize(name: "website", description: "Scrape and interact with websites", **options)
      super(name: name, description: description)
      @user_agent = options[:user_agent] || "Regent WebsiteTool/1.0"
      @timeout = options[:timeout] || 30
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "get_webpage"
        get_webpage(arguments[1])
      when "extract_text"
        extract_text(arguments[1])
      when "extract_links"
        extract_links(arguments[1])
      when "extract_tables"
        extract_tables(arguments[1])
      when "search_content"
        search_content(arguments[1], arguments[2])
      else
        raise ToolError, "Unknown Website action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Website tool error: #{e.message}"
    end

    private

    def get_webpage(url)
      require 'httparty'
      require 'nokogiri'
      
      begin
        response = HTTParty.get(
          url,
          headers: { "User-Agent" => @user_agent },
          timeout: @timeout
        )
        
        if response.code != 200
          raise ToolError, "Failed to fetch webpage: HTTP #{response.code}"
        end
        
        html = response.body
        doc = Nokogiri::HTML(html)
        
        # Extract basic information
        title = doc.at_css('title')&.text || "No title"
        meta_description = doc.at_css('meta[name="description"]')&.[]('content') || "No description"
        
        result = {
          url: url,
          title: title,
          description: meta_description,
          html: html
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error fetching webpage: #{e.message}"
      end
    end

    def extract_text(url)
      require 'httparty'
      require 'nokogiri'
      
      begin
        response = HTTParty.get(
          url,
          headers: { "User-Agent" => @user_agent },
          timeout: @timeout
        )
        
        if response.code != 200
          raise ToolError, "Failed to fetch webpage: HTTP #{response.code}"
        end
        
        html = response.body
        doc = Nokogiri::HTML(html)
        
        # Remove script and style elements
        doc.css('script, style').remove
        
        # Extract text from body
        text = doc.css('body').text.gsub(/\s+/, ' ').strip
        
        # Extract headings
        headings = {}
        ['h1', 'h2', 'h3'].each do |h|
          headings[h] = doc.css(h).map(&:text).map(&:strip)
        end
        
        # Extract paragraphs
        paragraphs = doc.css('p').map(&:text).map(&:strip).reject(&:empty?)
        
        result = {
          url: url,
          title: doc.at_css('title')&.text || "No title",
          headings: headings,
          paragraphs: paragraphs,
          full_text: text
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error extracting text: #{e.message}"
      end
    end

    def extract_links(url)
      require 'httparty'
      require 'nokogiri'
      require 'uri'
      
      begin
        response = HTTParty.get(
          url,
          headers: { "User-Agent" => @user_agent },
          timeout: @timeout
        )
        
        if response.code != 200
          raise ToolError, "Failed to fetch webpage: HTTP #{response.code}"
        end
        
        html = response.body
        doc = Nokogiri::HTML(html)
        base_uri = URI.parse(url)
        
        links = doc.css('a').map do |link|
          href = link['href']
          next if href.nil? || href.empty? || href.start_with?('#')
          
          # Convert relative URLs to absolute
          begin
            href_uri = URI.parse(href)
            href = if href_uri.relative?
                    URI.join(base_uri, href_uri).to_s
                  else
                    href
                  end
          rescue URI::InvalidURIError
            next
          end
          
          {
            text: link.text.strip,
            url: href
          }
        end.compact
        
        result = {
          url: url,
          links: links
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error extracting links: #{e.message}"
      end
    end

    def extract_tables(url)
      require 'httparty'
      require 'nokogiri'
      
      begin
        response = HTTParty.get(
          url,
          headers: { "User-Agent" => @user_agent },
          timeout: @timeout
        )
        
        if response.code != 200
          raise ToolError, "Failed to fetch webpage: HTTP #{response.code}"
        end
        
        html = response.body
        doc = Nokogiri::HTML(html)
        
        tables = []
        
        doc.css('table').each_with_index do |table, table_index|
          headers = table.css('th').map(&:text).map(&:strip)
          
          # If no headers found, try using the first row
          if headers.empty?
            headers = table.css('tr:first-child td').map(&:text).map(&:strip)
          end
          
          rows = []
          
          table.css('tr').each do |row|
            cells = row.css('td').map(&:text).map(&:strip)
            next if cells.empty?
            
            if headers.empty?
              rows << cells
            else
              row_data = {}
              headers.each_with_index do |header, i|
                row_data[header] = i < cells.length ? cells[i] : nil
              end
              rows << row_data
            end
          end
          
          tables << {
            index: table_index,
            headers: headers,
            rows: rows
          }
        end
        
        result = {
          url: url,
          tables: tables
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error extracting tables: #{e.message}"
      end
    end

    def search_content(url, query)
      require 'httparty'
      require 'nokogiri'
      
      begin
        response = HTTParty.get(
          url,
          headers: { "User-Agent" => @user_agent },
          timeout: @timeout
        )
        
        if response.code != 200
          raise ToolError, "Failed to fetch webpage: HTTP #{response.code}"
        end
        
        html = response.body
        doc = Nokogiri::HTML(html)
        
        # Remove script and style elements
        doc.css('script, style').remove
        
        # Search for the query in different elements
        matches = []
        
        ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'td', 'div'].each do |tag|
          doc.css(tag).each do |element|
            text = element.text.strip
            if text.include?(query)
              context = text.gsub(/\s+/, ' ')
              matches << {
                tag: tag,
                text: context,
                highlight: highlight_match(context, query)
              }
            end
          end
        end
        
        result = {
          url: url,
          query: query,
          match_count: matches.length,
          matches: matches
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error searching content: #{e.message}"
      end
    end

    def highlight_match(text, query)
      text.gsub(/(#{Regexp.escape(query)})/i, '**\1**')
    end
  end
end
