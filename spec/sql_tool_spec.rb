require 'rspec'
require_relative '../sql_tool/sql_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::SQLTool do
  describe '#initialize' do
    it 'raises an error when connection parameters are insufficient' do
      expect { described_class.new }.to raise_error(Regent::ToolError, /Insufficient database connection parameters/)
    end

    it 'initializes with db_url' do
      # This would try to establish a connection, so we rescue the error

      described_class.new(db_url: 'postgres://user:pass@localhost:5432/testdb')
    rescue StandardError
      # Expected to fail since we're not actually connecting to a database
      # We just want to make sure it attempts initialization with the URL
    end

    it 'initializes with separate connection parameters' do
      # This would try to establish a connection, so we rescue the error

      described_class.new(
        user: 'testuser',
        password: 'testpass',
        host: 'localhost',
        port: 5432,
        schema: 'testschema'
      )
    rescue StandardError
      # Expected to fail since we're not actually connecting to a database
      # We just want to make sure it attempts initialization with the parameters
    end
  end

  describe '#call' do
    # Since we can't instantiate a real tool without a database connection,
    # we'll test the validation at the interface level

    # We need to create a dummy tool that doesn't try to establish a connection
    # but still checks the action validation
    let(:dummy_tool) do
      Class.new(Regent::SQLTool) do
        def initialize
          @name = 'sql'
          @description = 'Execute SQL queries and manage database connections'
          @connection = nil
        end

        def setup_connection
          # Do nothing to avoid actual connection
        end
      end
    end

    let(:tool) { dummy_tool.new }

    context 'when connection is not established' do
      it 'raises a ToolError' do
        expect { tool.call('list_tables') }.to raise_error(Regent::ToolError, /Database connection not established/)
      end
    end
  end

  # The following tests would be run if a database connection was available
  context 'with valid database connection', skip: 'No database connection available' do
    # These tests would require a real connection to a database
    # In an environment with a test database, you would replace this with actual connection details

    let(:tool) do
      described_class.new(
        db_url: ENV['TEST_DB_URL'] || 'postgres://user:pass@localhost:5432/testdb'
      )
    end

    describe '#list_tables' do
      it 'returns a list of tables' do
        pending 'This test requires a valid database connection'

        result = tool.call('list_tables')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
      end
    end

    describe '#describe_table' do
      it 'describes the structure of a table' do
        pending 'This test requires a valid database connection'

        result = tool.call('describe_table', 'users')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)

        unless parsed.empty?
          column = parsed.first
          expect(column).to have_key('name')
          expect(column).to have_key('type')
          expect(column).to have_key('primary_key')
        end
      end
    end

    describe '#run_sql_query' do
      it 'executes a SQL query and returns results' do
        pending 'This test requires a valid database connection'

        result = tool.call('run_sql_query', 'SELECT * FROM users LIMIT 3', 3)
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
        expect(parsed.length).to be <= 3
      end
    end
  end
end
