# frozen_string_literal: true

module Regent
  # SQL tool for Regent - provides database access and query capabilities
  class SQLTool < Regent::Tool
    def initialize(name: "sql", description: "Execute SQL queries and manage database connections", **options)
      super(name: name, description: description)
      
      # Database connection parameters
      @db_url = options[:db_url]
      @user = options[:user] || ENV['SQL_USER']
      @password = options[:password] || ENV['SQL_PASSWORD']
      @host = options[:host] || ENV['SQL_HOST']
      @port = options[:port] || ENV['SQL_PORT']
      @schema = options[:schema] || ENV['SQL_SCHEMA']
      @dialect = options[:dialect] || ENV['SQL_DIALECT'] || 'postgresql'
      
      # Initialize database connection
      setup_connection
    end

    def call(*arguments)
      # Ensure we have a valid connection
      raise ToolError, "Database connection not established" unless @connection
      
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "list_tables"
        list_tables
      when "describe_table"
        describe_table(arguments[1])
      when "run_sql_query"
        run_sql_query(arguments[1], arguments[2])
      else
        raise ToolError, "Unknown SQL action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "SQL tool error: #{e.message}"
    end

    private

    def setup_connection
      require 'sequel'
      
      if @db_url
        @connection = Sequel.connect(@db_url)
      elsif @user && @password && @host && @port
        connection_string = "#{@dialect}://#{@user}:#{@password}@#{@host}:#{@port}"
        connection_string += "/#{@schema}" if @schema
        @connection = Sequel.connect(connection_string)
      else
        raise ToolError, "Insufficient database connection parameters"
      end
    end

    def list_tables
      tables = @connection.tables
      JSON.generate(tables)
    end

    def describe_table(table_name)
      raise ToolError, "Table name is required" if table_name.nil? || table_name.empty?
      
      begin
        columns = @connection.schema(table_name.to_sym)
        column_info = columns.map do |column|
          name, info = column
          {
            name: name,
            type: info[:type],
            primary_key: info[:primary_key] || false,
            allow_null: info[:allow_null] || true,
            default: info[:default]
          }
        end
        
        JSON.generate(column_info)
      rescue => e
        raise ToolError, "Error describing table #{table_name}: #{e.message}"
      end
    end

    def run_sql_query(query, limit = 10)
      raise ToolError, "SQL query is required" if query.nil? || query.empty?
      
      begin
        result = @connection[query]
        
        if limit && limit > 0
          rows = result.limit(limit).all
        else
          rows = result.all
        end
        
        JSON.generate(rows)
      rescue => e
        raise ToolError, "Error executing SQL query: #{e.message}"
      end
    end
  end
end
