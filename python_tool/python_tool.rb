require_relative '../regent_tool'
require 'fileutils'
require 'tempfile'
module Regent
  # Python tool for Regent - provides Python code execution capabilities
  class PythonTool < Regent::Tool
    def initialize(name: 'python', description: 'Execute Python code and manage Python environment', **options)
      super(name: name, description: description)
      @base_dir = options[:base_dir] || Dir.pwd
      @safe_globals = options[:safe_globals] || {}
      @safe_locals = options[:safe_locals] || {}
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]

      case action
      when 'run_python_code'
        run_python_code(arguments[1], arguments[2])
      when 'save_to_file_and_run'
        save_to_file_and_run(arguments[1], arguments[2], arguments[3], arguments[4] || true)
      when 'pip_install_package'
        pip_install_package(arguments[1])
      when 'run_python_file_return_variable'
        run_python_file_return_variable(arguments[1], arguments[2])
      when 'read_file'
        read_file(arguments[1])
      when 'list_files'
        list_files
      else
        raise ToolError, "Unknown Python action: #{action}"
      end
    rescue ToolError
      raise
    rescue StandardError => e
      raise ToolError, "Python tool error: #{e.message}"
    end

    private

    def warn
      puts 'PythonTool can run arbitrary code, please provide human supervision.'
    end

    def save_to_file_and_run(file_name, code, variable_to_return = nil, overwrite = true)
      warn

      begin
        file_path = File.join(@base_dir, file_name)
        dir_path = File.dirname(file_path)

        # Create directory if it doesn't exist
        FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)

        # Check if file exists and overwrite is false
        return "File #{file_name} already exists" if File.exist?(file_path) && !overwrite

        # Write code to file
        File.write(file_path, code)

        # Run the file
        result = `python3 #{file_path}`

        return "successfully ran #{file_path}" unless variable_to_return
        # This is a simplified approach - in a real implementation,
        # you would need to extract the variable from the Python environment
        # For now, we'll assume the variable is printed at the end of execution
        return "Variable #{variable_to_return} not found" if result.strip.empty?

        result.strip
      rescue StandardError => e
        raise ToolError, "Error saving and running code: #{e.message}"
      end
    end

    def run_python_file_return_variable(file_name, variable_to_return = nil)
      warn

      begin
        file_path = File.join(@base_dir, file_name)

        # Run the file
        result = `python3 #{file_path}`

        return "successfully ran #{file_path}" unless variable_to_return
        # This is a simplified approach - in a real implementation,
        # you would need to extract the variable from the Python environment
        # For now, we'll assume the variable is printed at the end of execution
        return "Variable #{variable_to_return} not found" if result.strip.empty?

        result.strip
      rescue StandardError => e
        raise ToolError, "Error running file: #{e.message}"
      end
    end

    def read_file(file_name)
      file_path = File.join(@base_dir, file_name)
      File.read(file_path)
    rescue StandardError => e
      raise ToolError, "Error reading file: #{e.message}"
    end

    def list_files
      files = Dir.entries(@base_dir).reject { |f| f.start_with?('.') }
      files.join(', ')
    rescue StandardError => e
      raise ToolError, "Error reading files: #{e.message}"
    end

    def run_python_code(code, variable_to_return = nil)
      warn

      begin
        # Create a temporary file to run the code
        temp_file = Tempfile.new(['python_code', '.py'])
        temp_file.write(code)
        temp_file.close

        # Run the code
        result = `python3 #{temp_file.path}`
        temp_file.unlink

        return 'successfully ran python code' unless variable_to_return
        # This is a simplified approach - in a real implementation,
        # you would need to extract the variable from the Python environment
        # For now, we'll assume the variable is printed at the end of execution
        return "Variable #{variable_to_return} not found" if result.strip.empty?

        result.strip
      rescue StandardError => e
        raise ToolError, "Error running python code: #{e.message}"
      end
    end

    def pip_install_package(package_name)
      warn

      begin
        `pip3 install #{package_name}`
        "successfully installed package #{package_name}"
      rescue StandardError => e
        raise ToolError, "Error installing package #{package_name}: #{e.message}"
      end
    end
  end
end
