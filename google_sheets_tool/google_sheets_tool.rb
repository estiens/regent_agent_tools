# frozen_string_literal: true

module Regent
  # Google Sheets tool for Regent - provides integration with Google Sheets
  class GoogleSheetsTool < Regent::Tool
    def initialize(name: "google_sheets", description: "Interact with Google Sheets", **options)
      super(name: name, description: description)
      @credentials_file = options[:credentials_file]
      @token_path = options[:token_path]
      @application_name = options[:application_name] || "Regent Google Sheets Tool"
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "read_sheet"
        read_sheet(arguments[1], arguments[2], arguments[3])
      when "write_to_sheet"
        write_to_sheet(arguments[1], arguments[2], arguments[3], arguments[4])
      when "create_sheet"
        create_sheet(arguments[1])
      when "add_sheet"
        add_sheet(arguments[1], arguments[2])
      else
        raise ToolError, "Unknown Google Sheets action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Google Sheets tool error: #{e.message}"
    end

    private

    def setup_client
      require 'google/apis/sheets_v4'
      require 'googleauth'
      require 'googleauth/stores/file_token_store'
      require 'fileutils'

      service = Google::Apis::SheetsV4::SheetsService.new
      service.client_options.application_name = @application_name
      service.authorization = authorize
      service
    end

    def authorize
      require 'google/apis/sheets_v4'
      require 'googleauth'
      require 'googleauth/stores/file_token_store'
      
      client_id = Google::Auth::ClientId.from_file(@credentials_file)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: @token_path)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS, token_store)
      user_id = 'default'
      credentials = authorizer.get_credentials(user_id)
      
      if credentials.nil?
        raise ToolError, "No credentials found. Please run the authorization flow."
      end
      
      credentials
    end

    def read_sheet(spreadsheet_id, range, include_headers = true)
      service = setup_client
      
      begin
        response = service.get_spreadsheet_values(spreadsheet_id, range)
        
        if response.values.nil? || response.values.empty?
          return JSON.generate([])
        end
        
        if include_headers
          headers = response.values.first
          rows = response.values[1..-1]
          
          result = rows.map do |row|
            row_data = {}
            headers.each_with_index do |header, index|
              row_data[header] = index < row.length ? row[index] : nil
            end
            row_data
          end
          
          JSON.generate(result)
        else
          JSON.generate(response.values)
        end
      rescue => e
        raise ToolError, "Error reading sheet: #{e.message}"
      end
    end

    def write_to_sheet(spreadsheet_id, range, values, value_input_option = "RAW")
      service = setup_client
      
      begin
        # Prepare the value range object
        value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)
        
        # Execute the request
        result = service.update_spreadsheet_values(
          spreadsheet_id,
          range,
          value_range,
          value_input_option: value_input_option
        )
        
        JSON.generate({
          spreadsheet_id: spreadsheet_id,
          updated_range: result.updated_range,
          updated_rows: result.updated_rows,
          updated_columns: result.updated_columns,
          updated_cells: result.updated_cells
        })
      rescue => e
        raise ToolError, "Error writing to sheet: #{e.message}"
      end
    end

    def create_sheet(title)
      service = setup_client
      
      begin
        # Create a new spreadsheet
        spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new(
          properties: Google::Apis::SheetsV4::SpreadsheetProperties.new(
            title: title
          )
        )
        
        # Execute the request
        result = service.create_spreadsheet(spreadsheet)
        
        JSON.generate({
          spreadsheet_id: result.spreadsheet_id,
          title: result.properties.title,
          url: result.spreadsheet_url,
          sheets: result.sheets.map { |sheet| sheet.properties.title }
        })
      rescue => e
        raise ToolError, "Error creating sheet: #{e.message}"
      end
    end

    def add_sheet(spreadsheet_id, title)
      service = setup_client
      
      begin
        # Create the add sheet request
        request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
          requests: [
            {
              add_sheet: {
                properties: {
                  title: title
                }
              }
            }
          ]
        )
        
        # Execute the request
        result = service.batch_update_spreadsheet(spreadsheet_id, request)
        
        # Get the new sheet's properties
        new_sheet = result.replies.first.add_sheet.properties
        
        JSON.generate({
          spreadsheet_id: spreadsheet_id,
          sheet_id: new_sheet.sheet_id,
          title: new_sheet.title
        })
      rescue => e
        raise ToolError, "Error adding sheet: #{e.message}"
      end
    end
  end
end
