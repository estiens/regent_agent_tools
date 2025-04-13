require 'rspec'
require_relative '../function_tool/function_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::FunctionTool do
  let(:tool) { described_class.new }

  describe '#initialize' do
    it 'creates an instance of FunctionTool' do
      expect(tool).to be_an_instance_of(Regent::FunctionTool)
      expect(tool.name).to eq('function')
    end

    it 'initializes with empty functions by default' do
      expect(tool.instance_variable_get(:@functions)).to eq({})
    end

    it 'initializes with safe mode enabled by default' do
      expect(tool.instance_variable_get(:@safe_mode)).to be true
    end
  end

  describe '#call' do
    context 'when registering a function' do
      it 'registers a valid function' do
        result = tool.call('register_function', 'add_numbers', 'args.reduce(0) { |sum, num| sum + num.to_i }')
        parsed = JSON.parse(result)

        expect(parsed['status']).to eq('success')
        expect(parsed['message']).to include('registered successfully')

        # Verify the function was stored
        functions = tool.instance_variable_get(:@functions)
        expect(functions).to have_key('add_numbers')
        expect(functions['add_numbers'][:code]).to eq('args.reduce(0) { |sum, num| sum + num.to_i }')
      end

      it 'rejects functions with forbidden patterns' do
        expect do
          tool.call('register_function', 'bad_function', "system('ls')")
        end.to raise_error(Regent::ToolError, /Forbidden code pattern detected/)
      end
    end

    context 'when executing a function' do
      before do
        tool.call('register_function', 'add_numbers', 'args.reduce(0) { |sum, num| sum + num.to_i }')
        tool.call('register_function', 'multiply_numbers', 'args.reduce(1) { |product, num| product * num.to_i }')
      end

      it 'executes a registered function with arguments' do
        result = tool.call('execute_function', 'add_numbers', [1, 2, 3, 4, 5])
        expect(result.to_i).to eq(15)

        result = tool.call('execute_function', 'multiply_numbers', [2, 3, 4])
        expect(result.to_i).to eq(24)
      end

      it 'raises an error when executing a non-existent function' do
        expect do
          tool.call('execute_function', 'non_existent_function')
        end.to raise_error(Regent::ToolError, /Function 'non_existent_function' not found/)
      end
    end

    context 'when listing functions' do
      before do
        tool.call('register_function', 'function1', 'args.sum')
        tool.call('register_function', 'function2', "args.join('-')")
      end

      it 'returns a list of registered functions' do
        result = tool.call('list_functions')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to eq(2)

        function_names = parsed.map { |f| f['name'] }
        expect(function_names).to include('function1', 'function2')
      end
    end

    context 'when evaluating expressions' do
      it 'evaluates a simple expression' do
        result = tool.call('evaluate_expression', '2 + 3 * 4')
        expect(result.to_i).to eq(14)
      end

      it 'evaluates a complex expression' do
        result = tool.call('evaluate_expression', '[1, 2, 3, 4, 5].select { |n| n.even? }.map { |n| n * 2 }')
        parsed = JSON.parse(result)
        expect(parsed).to eq([4, 8])
      end

      it 'rejects expressions with forbidden patterns' do
        expect do
          tool.call('evaluate_expression', "File.read('/etc/passwd')")
        end.to raise_error(Regent::ToolError, /Forbidden code pattern detected/)
      end
    end

    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect do
          tool.call('invalid_action')
        end.to raise_error(Regent::ToolError, /Unknown Function action/)
      end
    end
  end
end
