require 'rspec'
require_relative '../python_tool/python_tool'
require_relative '../regent_tool'
require 'json'
require 'fileutils'
require 'tempfile'

RSpec.describe Regent::PythonTool do
  # Create a temporary directory for testing
  let(:test_dir) { Dir.mktmpdir }
  let(:tool) { described_class.new(base_dir: test_dir) }

  after do
    # Clean up our test directory
    FileUtils.remove_entry(test_dir) if File.exist?(test_dir)
  end

  describe '#initialize' do
    it 'creates an instance of PythonTool' do
      expect(tool).to be_an_instance_of(Regent::PythonTool)
      expect(tool.name).to eq('python')
    end

    it 'sets base_dir' do
      expect(tool.instance_variable_get(:@base_dir)).to eq(test_dir)
    end

    it 'initializes empty safe globals and locals by default' do
      expect(tool.instance_variable_get(:@safe_globals)).to eq({})
      expect(tool.instance_variable_get(:@safe_locals)).to eq({})
    end
  end

  describe '#call' do
    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Python action/)
      end
    end

    context 'with run_python_code action' do
      it 'executes simple Python code' do
        # We need to pass a variable name to get the output
        code = "x = 'Hello from Python'\nprint(x)"
        result = tool.call('run_python_code', code, 'x')
        expect(result).to include('Hello from Python')
      end

      it 'handles code that prints a variable' do
        # We need to pass a variable name to get the output
        code = "x = 42\nprint(x)"
        result = tool.call('run_python_code', code, 'x')
        expect(result).to include('42')
      end

      # The Python tool doesn't actually raise errors for Python runtime errors
      # It only catches Ruby exceptions in the rescue block
      it 'handles file system errors' do
        # Force a Ruby file system error by using an invalid path
        allow(Tempfile).to receive(:new).and_raise(Errno::EACCES, 'Permission denied')
        expect do
          tool.call('run_python_code', 'print("test")')
        end.to raise_error(Regent::ToolError, /Error running python code/)
      end

      it 'returns default message when no variable is requested' do
        code = "print('Hello from Python')"
        result = tool.call('run_python_code', code)
        expect(result).to eq('successfully ran python code')
      end
    end

    context 'with save_to_file_and_run action' do
      it 'saves code to a file and executes it' do
        code = "print('File execution test')"
        result = tool.call('save_to_file_and_run', 'test.py', code)
        expect(result).to include('successfully ran')

        # Verify the file was created
        expect(File.exist?(File.join(test_dir, 'test.py'))).to be true
        expect(File.read(File.join(test_dir, 'test.py'))).to eq(code)
      end

      it 'creates nested directories if needed' do
        code = "print('Nested directory test')"
        result = tool.call('save_to_file_and_run', 'nested/dir/test.py', code)
        expect(result).to include('successfully ran')

        # Verify the file was created in the nested directory
        expect(File.exist?(File.join(test_dir, 'nested/dir/test.py'))).to be true
      end

      it 'returns variable values if requested' do
        code = "x = 100\nprint(x)"
        result = tool.call('save_to_file_and_run', 'var_test.py', code, 'x')
        expect(result).to include('100')
      end
    end

    context 'with read_file action' do
      before do
        # Create a test file
        File.write(File.join(test_dir, 'read_test.txt'), 'Test content')
      end

      it 'reads the content of a file' do
        result = tool.call('read_file', 'read_test.txt')
        expect(result).to eq('Test content')
      end

      it 'raises an error for non-existent files' do
        expect { tool.call('read_file', 'nonexistent.txt') }.to raise_error(Regent::ToolError)
      end
    end

    context 'with list_files action' do
      before do
        # Create some test files
        File.write(File.join(test_dir, 'file1.txt'), 'Content 1')
        File.write(File.join(test_dir, 'file2.py'), "print('Content 2')")
      end

      it 'lists files in the base directory' do
        result = tool.call('list_files')
        expect(result).to include('file1.txt')
        expect(result).to include('file2.py')
      end
    end

    # Skip pip install test in normal runs as it modifies the system
    context 'with pip_install_package action', skip: 'Skipping pip install to avoid system modification' do
      it 'installs a Python package' do
        # This is commented out to avoid actual package installation during tests
        # result = tool.call("pip_install_package", "pytest")
        # expect(result).to include("successfully installed")
      end
    end
  end
end
