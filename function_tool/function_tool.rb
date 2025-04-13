# frozen_string_literal: true

module Regent
  # Function tool for Regent - provides general function execution capabilities
  class FunctionTool < Regent::Tool
    def initialize(name: "function", description: "Execute custom functions and code", **options)
      super(name: name, description: description)
      @functions = options[:functions] || {}
      @safe_mode = options.fetch(:safe_mode, true)
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "register_function"
        register_function(arguments[1], arguments[2])
      when "execute_function"
        execute_function(arguments[1], arguments[2] || [])
      when "list_functions"
        list_functions
      when "evaluate_expression"
        evaluate_expression(arguments[1])
      else
        raise ToolError, "Unknown Function action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Function tool error: #{e.message}"
    end

    private

    def register_function(name, code)
      if @safe_mode
        # In safe mode, we validate the function code
        validate_function_code(code)
      end
      
      begin
        # Create a lambda from the code
        function = eval("lambda { |args| #{code} }")
        
        # Store the function
        @functions[name] = {
          code: code,
          function: function
        }
        
        JSON.generate({
          status: "success",
          message: "Function '#{name}' registered successfully"
        })
      rescue => e
        raise ToolError, "Error registering function: #{e.message}"
      end
    end

    def execute_function(name, args = [])
      function_data = @functions[name]
      
      if function_data.nil?
        raise ToolError, "Function '#{name}' not found"
      end
      
      begin
        # Execute the function with the provided arguments
        result = function_data[:function].call(args)
        
        # Convert result to JSON if it's not already a string
        result_json = result.is_a?(String) ? result : JSON.generate(result)
        
        result_json
      rescue => e
        raise ToolError, "Error executing function '#{name}': #{e.message}"
      end
    end

    def list_functions
      function_list = @functions.keys.map do |name|
        {
          name: name,
          code: @functions[name][:code]
        }
      end
      
      JSON.generate(function_list)
    end

    def evaluate_expression(expression)
      if @safe_mode
        # In safe mode, we validate the expression
        validate_expression(expression)
      end
      
      begin
        # Evaluate the expression
        result = eval(expression)
        
        # Convert result to JSON if it's not already a string
        result_json = result.is_a?(String) ? result : JSON.generate(result)
        
        result_json
      rescue => e
        raise ToolError, "Error evaluating expression: #{e.message}"
      end
    end

    def validate_function_code(code)
      # This is a simplified validation
      # In a real implementation, you would use a more robust approach
      
      forbidden_patterns = [
        /`/, # Backticks for shell commands
        /system\s*\(/, # System calls
        /exec\s*\(/, # Exec calls
        /eval\s*\(/, # Nested evals
        /File\.(open|read|write)/, # File operations
        /require\s+['"]/, # Requiring additional libraries
        /ENV\[/ # Environment variables
      ]
      
      forbidden_patterns.each do |pattern|
        if code =~ pattern
          raise ToolError, "Forbidden code pattern detected: #{pattern.inspect}"
        end
      end
    end

    def validate_expression(expression)
      # Similar validation as for function code
      validate_function_code(expression)
    end
  end
end
