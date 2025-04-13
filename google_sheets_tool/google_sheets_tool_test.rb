require 'minitest/autorun'
require_relative '../ported_tools/google_sheets_tool'
require 'json'

class GoogleSheetsToolTest < Minitest::Test
  def setup
    @tool = Regent::GoogleSheetsTool.new(
      credentials_file: "/path/to/credentials.json",
      token_path: "/path/to/token.json"
    )
    
    # Mock Google Sheets service
    @mock_service = Minitest::Mock.new
    @tool.instance_variable_set(:@service, @mock_service)
    
    # Mock the setup_client method to return our mock service
    def @tool.setup_client
      @service
    end
  end

  def test_initialization
    assert_instance_of Regent::GoogleSheetsTool, @tool
    assert_equal "google_sheets", @tool.name
  end

  def test_read_sheet
    # Mock response for get_spreadsheet_values
    mock_response = OpenStruct.new(
      values: [
        ["Header1", "Header2", "Header3"],
        ["Value1A", "Value1B", "Value1C"],
        ["Value2A", "Value2B", "Value2C"]
      ]
    )
    
    @mock_service.expect :get_spreadsheet_values, mock_response, ["spreadsheet_id", "Sheet1!A1:C3"]
    
    result = @tool.call("read_sheet", "spreadsheet_id", "Sheet1!A1:C3")
    parsed = JSON.parse(result)
    
    assert_instance_of Array, parsed
    assert_equal 2, parsed.length
    
    assert_equal "Value1A", parsed[0]["Header1"]
    assert_equal "Value1B", parsed[0]["Header2"]
    assert_equal "Value1C", parsed[0]["Header3"]
    
    @mock_service.verify
  end

  def test_write_to_sheet
    # Mock response for update_spreadsheet_values
    mock_response = OpenStruct.new(
      updated_range: "Sheet1!A1:C3",
      updated_rows: 3,
      updated_columns: 3,
      updated_cells: 9
    )
    
    # Define the expected parameters
    spreadsheet_id = "spreadsheet_id"
    range = "Sheet1!A1:C3"
    values = [["Header1", "Header2", "Header3"], ["Value1A", "Value1B", "Value1C"], ["Value2A", "Value2B", "Value2C"]]
    
    # Expect the call with appropriate parameters
    @mock_service.expect :update_spreadsheet_values, mock_response, [
      spreadsheet_id,
      range,
      Google::Apis::SheetsV4::ValueRange.new(values: values),
      { value_input_option: "RAW" }
    ]
    
    result = @tool.call("write_to_sheet", spreadsheet_id, range, values)
    parsed = JSON.parse(result)
    
    assert_instance_of Hash, parsed
    assert_equal "spreadsheet_id", parsed["spreadsheet_id"]
    assert_equal "Sheet1!A1:C3", parsed["updated_range"]
    assert_equal 3, parsed["updated_rows"]
    assert_equal 3, parsed["updated_columns"]
    assert_equal 9, parsed["updated_cells"]
    
    @mock_service.verify
  end

  def test_error_handling
    # Test with invalid action
    assert_raises Regent::ToolError do
      @tool.call("invalid_action")
    end
  end
end
