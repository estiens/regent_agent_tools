require 'rspec'
require_relative '../google_sheets_tool/google_sheets_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::GoogleSheetsTool do
  describe '#initialize' do
    it 'creates an instance of GoogleSheetsTool' do
      tool = described_class.new
      expect(tool).to be_an_instance_of(Regent::GoogleSheetsTool)
      expect(tool.name).to eq('google_sheets')
    end

    it 'sets application name' do
      tool = described_class.new(application_name: 'Test App')
      expect(tool.instance_variable_get(:@application_name)).to eq('Test App')
    end

    it 'uses default application name if not provided' do
      tool = described_class.new
      expect(tool.instance_variable_get(:@application_name)).to eq('Regent Google Sheets Tool')
    end
  end

  describe '#call' do
    let(:tool) { described_class.new }

    context 'when credentials are not provided' do
      it 'raises a ToolError for API-dependent actions' do
        # Since setup_client requires credentials, any action will fail
        expect { tool.call('read_sheet', 'spreadsheet_id', 'A1:D10') }.to raise_error(Regent::ToolError)
      end
    end

    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Google Sheets action/)
      end
    end

    # NOTE: Full API functionality tests would require valid Google credentials
    # These would test read_sheet, write_to_sheet, create_sheet, and add_sheet actions
    context 'with valid credentials', skip: 'No credentials available' do
      let(:tool) do
        # This setup would be used if we had credentials for testing
        described_class.new(
          credentials_file: 'path/to/credentials.json',
          token_path: 'path/to/token.yaml'
        )
      end

      # Example of how a test would be structured if we had credentials
      it 'reads data from a spreadsheet' do
        pending 'This test requires valid Google Sheets credentials'

        result = tool.call('read_sheet', 'spreadsheet_id', 'Sheet1!A1:D10')
        parsed = JSON.parse(result)

        expect(parsed).to be_an_instance_of(Array)
      end
    end
  end
end
