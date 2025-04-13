# frozen_string_literal: true

module Regent
  # Google Search tool for Regent - provides web search capabilities
  class GoogleSearchTool < Regent::Tool
    def initialize(name: "google_search", description: "Search the web using Google", **options)
      super(name: name, description: description)
      @api_key = options[:api_key] || ENV['GOOGLE_API_KEY']
      @cx = options[:cx] || ENV['GOOGLE_CX']  # Custom Search Engine ID
      @num_results = options[:num_results] || 10
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "search"
        search(arguments[1], arguments[2] || @num_results, arguments[3])
      else
        raise ToolError, "Unknown Google Search action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Google Search tool error: #{e.message}"
    end

    private

    def search(query, num_results = 10, date_range = nil)
      require 'httparty'
      
      raise ToolError, "Google API key not provided" unless @api_key
      raise ToolError, "Google Custom Search Engine ID not provided" unless @cx
      
      url = "https://www.googleapis.com/customsearch/v1"
      
      params = {
        key: @api_key,
        cx: @cx,
        q: query,
        num: [num_results, 10].min  # Google API limits to 10 results per request
      }
      
      # Add date range if specified
      if date_range
        case date_range
        when "past_hour"
          params[:dateRestrict] = "h1"
        when "past_day"
          params[:dateRestrict] = "d1"
        when "past_week"
          params[:dateRestrict] = "w1"
        when "past_month"
          params[:dateRestrict] = "m1"
        when "past_year"
          params[:dateRestrict] = "y1"
        end
      end
      
      response = HTTParty.get(url, query: params)
      
      if response.code != 200
        raise ToolError, "Google Search API error: #{response.message}"
      end
      
      results = response.parsed_response["items"] || []
      
      # Format results
      formatted_results = results.map do |item|
        {
          title: item["title"],
          link: item["link"],
          snippet: item["snippet"],
          displayLink: item["displayLink"]
        }
      end
      
      # If we need more than 10 results, make additional requests
      if num_results > 10
        remaining_results = num_results - 10
        start_index = 11
        
        while remaining_results > 0 && start_index <= 100  # Google API limits to 100 results total
          params[:start] = start_index
          params[:num] = [remaining_results, 10].min
          
          response = HTTParty.get(url, query: params)
          
          if response.code == 200 && response.parsed_response["items"]
            additional_results = response.parsed_response["items"].map do |item|
              {
                title: item["title"],
                link: item["link"],
                snippet: item["snippet"],
                displayLink: item["displayLink"]
              }
            end
            
            formatted_results.concat(additional_results)
            remaining_results -= additional_results.length
            start_index += 10
          else
            break
          end
        end
      end
      
      JSON.generate(formatted_results)
    end
  end
end
