require 'rspec'
require_relative '../financial_datasets_tool/financial_datasets_tool'
require_relative '../regent_tool'
require 'json'

RSpec.describe Regent::FinancialDatasetsTool do
  let(:tool) { described_class.new }

  describe '#initialize' do
    it 'creates an instance of FinancialDatasetsTool' do
      expect(tool).to be_an_instance_of(Regent::FinancialDatasetsTool)
      expect(tool.name).to eq('financial_datasets')
    end
  end

  describe '#call' do
    context 'when API key is not provided' do
      it 'raises a ToolError for API-dependent actions' do
        expect { tool.call('get_stock_price', 'AAPL') }.to raise_error(Regent::ToolError, /API key not provided/)
      end
    end

    context 'when given an invalid action' do
      it 'raises a ToolError' do
        expect { tool.call('invalid_action') }.to raise_error(Regent::ToolError, /Unknown Financial Datasets action/)
      end
    end
  end

  # NOTE: Full API functionality tests would be added here if an API key were available
  # These would test get_stock_price, get_stock_history, get_company_info, and get_market_news
  # without mocks, using real API calls
end
