# frozen_string_literal: true

module Regent
  # Financial Datasets tool for Regent - provides access to financial data
  class FinancialDatasetsTool < Regent::Tool
    def initialize(name: "financial_datasets", description: "Access financial data and market information", **options)
      super(name: name, description: description)
      @api_key = options[:api_key] || ENV['FINANCIAL_API_KEY']
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "get_stock_price"
        get_stock_price(arguments[1])
      when "get_stock_history"
        get_stock_history(arguments[1], arguments[2], arguments[3])
      when "get_company_info"
        get_company_info(arguments[1])
      when "get_market_news"
        get_market_news(arguments[2] || 5)
      else
        raise ToolError, "Unknown Financial Datasets action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Financial Datasets tool error: #{e.message}"
    end

    private

    def get_stock_price(symbol)
      require 'httparty'
      
      raise ToolError, "API key not provided" unless @api_key
      
      begin
        url = "https://www.alphavantage.co/query"
        params = {
          function: "GLOBAL_QUOTE",
          symbol: symbol,
          apikey: @api_key
        }
        
        response = HTTParty.get(url, query: params)
        
        if response.code != 200
          raise ToolError, "API request failed: #{response.message}"
        end
        
        data = response.parsed_response
        
        if data["Error Message"]
          raise ToolError, data["Error Message"]
        end
        
        if data["Global Quote"].empty?
          raise ToolError, "No data found for symbol: #{symbol}"
        end
        
        quote = data["Global Quote"]
        
        result = {
          symbol: quote["01. symbol"],
          price: quote["05. price"],
          change: quote["09. change"],
          change_percent: quote["10. change percent"],
          volume: quote["06. volume"],
          latest_trading_day: quote["07. latest trading day"]
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error fetching stock price: #{e.message}"
      end
    end

    def get_stock_history(symbol, start_date, end_date = nil)
      require 'httparty'
      
      raise ToolError, "API key not provided" unless @api_key
      
      begin
        url = "https://www.alphavantage.co/query"
        params = {
          function: "TIME_SERIES_DAILY",
          symbol: symbol,
          outputsize: "full",
          apikey: @api_key
        }
        
        response = HTTParty.get(url, query: params)
        
        if response.code != 200
          raise ToolError, "API request failed: #{response.message}"
        end
        
        data = response.parsed_response
        
        if data["Error Message"]
          raise ToolError, data["Error Message"]
        end
        
        time_series = data["Time Series (Daily)"]
        
        if time_series.nil? || time_series.empty?
          raise ToolError, "No historical data found for symbol: #{symbol}"
        end
        
        # Filter by date range
        start_date = Date.parse(start_date) if start_date.is_a?(String)
        end_date = end_date ? Date.parse(end_date) : Date.today
        
        filtered_data = time_series.select do |date_str, _|
          date = Date.parse(date_str)
          date >= start_date && date <= end_date
        end
        
        # Format the results
        result = filtered_data.map do |date_str, values|
          {
            date: date_str,
            open: values["1. open"],
            high: values["2. high"],
            low: values["3. low"],
            close: values["4. close"],
            volume: values["5. volume"]
          }
        end
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error fetching stock history: #{e.message}"
      end
    end

    def get_company_info(symbol)
      require 'httparty'
      
      raise ToolError, "API key not provided" unless @api_key
      
      begin
        url = "https://www.alphavantage.co/query"
        params = {
          function: "OVERVIEW",
          symbol: symbol,
          apikey: @api_key
        }
        
        response = HTTParty.get(url, query: params)
        
        if response.code != 200
          raise ToolError, "API request failed: #{response.message}"
        end
        
        data = response.parsed_response
        
        if data["Error Message"]
          raise ToolError, data["Error Message"]
        end
        
        if data.empty? || !data["Symbol"]
          raise ToolError, "No company information found for symbol: #{symbol}"
        end
        
        # Select relevant fields
        result = {
          symbol: data["Symbol"],
          name: data["Name"],
          description: data["Description"],
          exchange: data["Exchange"],
          industry: data["Industry"],
          sector: data["Sector"],
          market_cap: data["MarketCapitalization"],
          pe_ratio: data["PERatio"],
          dividend_yield: data["DividendYield"],
          earnings_per_share: data["EPS"],
          beta: data["Beta"],
          fifty_two_week_high: data["52WeekHigh"],
          fifty_two_week_low: data["52WeekLow"]
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error fetching company information: #{e.message}"
      end
    end

    def get_market_news(limit = 5)
      require 'httparty'
      
      raise ToolError, "API key not provided" unless @api_key
      
      begin
        url = "https://www.alphavantage.co/query"
        params = {
          function: "NEWS_SENTIMENT",
          topics: "financial_markets",
          apikey: @api_key
        }
        
        response = HTTParty.get(url, query: params)
        
        if response.code != 200
          raise ToolError, "API request failed: #{response.message}"
        end
        
        data = response.parsed_response
        
        if data["Error Message"]
          raise ToolError, data["Error Message"]
        end
        
        if !data["feed"] || data["feed"].empty?
          raise ToolError, "No market news found"
        end
        
        # Format the results
        result = data["feed"].take(limit).map do |article|
          {
            title: article["title"],
            url: article["url"],
            time_published: article["time_published"],
            authors: article["authors"],
            summary: article["summary"],
            source: article["source"],
            overall_sentiment: article["overall_sentiment_label"]
          }
        end
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error fetching market news: #{e.message}"
      end
    end
  end
end
