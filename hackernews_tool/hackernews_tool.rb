# frozen_string_literal: true

module Regent
  # HackerNews tool for Regent - provides access to Hacker News stories and user data
  class HackerNewsTool < Regent::Tool
    def initialize(name: "hacker_news", description: "Access Hacker News stories and user data", **options)
      super(name: name, description: description)
      @get_top_stories = options.fetch(:get_top_stories, true)
      @get_user_details = options.fetch(:get_user_details, true)
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "get_top_hackernews_stories"
        get_top_hackernews_stories(arguments[1] || 10)
      when "get_user_details"
        get_user_details(arguments[1])
      else
        raise ToolError, "Unknown HackerNews action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "HackerNews tool error: #{e.message}"
    end

    private

    def get_top_hackernews_stories(num_stories = 10)
      require 'httparty'
      
      begin
        # Fetch top story IDs
        response = HTTParty.get("https://hacker-news.firebaseio.com/v0/topstories.json")
        
        if response.code != 200
          raise ToolError, "Failed to fetch top stories: #{response.message}"
        end
        
        story_ids = response.parsed_response
        
        # Fetch story details
        stories = []
        
        story_ids.take(num_stories).each do |story_id|
          story_response = HTTParty.get("https://hacker-news.firebaseio.com/v0/item/#{story_id}.json")
          
          if story_response.code == 200
            story = story_response.parsed_response
            story["username"] = story["by"] if story["by"]
            stories << story
          end
        end
        
        JSON.generate(stories)
      rescue => e
        raise ToolError, "Error fetching HackerNews stories: #{e.message}"
      end
    end

    def get_user_details(username)
      require 'httparty'
      
      begin
        # Fetch user details
        response = HTTParty.get("https://hacker-news.firebaseio.com/v0/user/#{username}.json")
        
        if response.code != 200
          raise ToolError, "Failed to fetch user details: #{response.message}"
        end
        
        user = response.parsed_response
        
        user_details = {
          id: user["id"],
          karma: user["karma"],
          about: user["about"],
          total_items_submitted: user["submitted"] ? user["submitted"].length : 0
        }
        
        JSON.generate(user_details)
      rescue => e
        raise ToolError, "Error getting user details: #{e.message}"
      end
    end
  end
end
