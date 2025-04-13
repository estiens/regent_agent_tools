module Regent
  require 'csv'
  require 'json'

  class ToolError < StandardError; end

  class Tool
    attr_reader :name, :description

    def initialize(name: 'tool', description: 'A tool', **options)
      @name = name
      @description = description
      @options = options
    end

    def call(*args)
      raise NotImplementedError, 'Subclasses must implement this method'
    end
  end
end
