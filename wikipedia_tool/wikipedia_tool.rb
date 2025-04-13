# frozen_string_literal: true

module Regent
  # Wikipedia tool for Regent - provides access to Wikipedia content
  class WikipediaTool < Regent::Tool
    def initialize(name: "wikipedia", description: "Search Wikipedia for information", **options)
      super(name: name, description: description)
      @knowledge_base = options[:knowledge_base]
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "search_wikipedia"
        search_wikipedia(arguments[1])
      when "search_wikipedia_and_update_knowledge_base"
        if @knowledge_base
          search_wikipedia_and_update_knowledge_base(arguments[1])
        else
          raise ToolError, "Knowledge base not provided"
        end
      else
        raise ToolError, "Unknown Wikipedia action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Wikipedia tool error: #{e.message}"
    end

    private

    def search_wikipedia(query)
      require 'wikipedia'
      
      begin
        page = Wikipedia.find(query)
        
        if page.text.empty?
          raise ToolError, "No Wikipedia article found for: #{query}"
        end
        
        document = {
          name: query,
          content: page.summary,
          url: page.fullurl,
          title: page.title,
          categories: page.categories,
          links: page.links
        }
        
        JSON.generate(document)
      rescue => e
        raise ToolError, "Error searching Wikipedia: #{e.message}"
      end
    end

    def search_wikipedia_and_update_knowledge_base(topic)
      require 'wikipedia'
      
      begin
        # Add topic to knowledge base
        @knowledge_base.topics ||= []
        @knowledge_base.topics << topic
        
        # Load knowledge base
        @knowledge_base.load(recreate: false)
        
        # Search knowledge base for the topic
        relevant_docs = @knowledge_base.search(query: topic)
        
        # Convert documents to hashes
        doc_hashes = relevant_docs.map do |doc|
          {
            name: doc.name,
            content: doc.content,
            metadata: doc.metadata
          }
        end
        
        JSON.generate(doc_hashes)
      rescue => e
        raise ToolError, "Error updating knowledge base: #{e.message}"
      end
    end
  end
end
