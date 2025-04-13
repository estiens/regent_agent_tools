# frozen_string_literal: true

module Regent
  # Jira tool for Regent - provides integration with Atlassian Jira
  class JiraTool < Regent::Tool
    def initialize(name: "jira", description: "Interact with Jira issues and projects", **options)
      super(name: name, description: description)
      @server_url = options[:server_url] || ENV['JIRA_SERVER_URL']
      @username = options[:username] || ENV['JIRA_USERNAME']
      @password = options[:password] || ENV['JIRA_PASSWORD']
      @token = options[:token] || ENV['JIRA_TOKEN']
      
      raise ToolError, "JIRA server URL not provided" unless @server_url
      
      # Initialize Jira client
      setup_client
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "get_issue"
        get_issue(arguments[1])
      when "create_issue"
        create_issue(arguments[1], arguments[2], arguments[3], arguments[4] || "Task")
      when "search_issues"
        search_issues(arguments[1], arguments[2] || 50)
      when "add_comment"
        add_comment(arguments[1], arguments[2])
      else
        raise ToolError, "Unknown Jira action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "Jira tool error: #{e.message}"
    end

    private

    def setup_client
      require 'jira-ruby'
      
      options = {
        site: @server_url,
        context_path: '',
        auth_type: :basic
      }
      
      if @token && @username
        options[:username] = @username
        options[:password] = @token
      elsif @username && @password
        options[:username] = @username
        options[:password] = @password
      end
      
      @client = JIRA::Client.new(options)
    end

    def get_issue(issue_key)
      issue = @client.Issue.find(issue_key)
      
      issue_details = {
        key: issue.key,
        project: issue.project.key,
        issuetype: issue.issuetype.name,
        reporter: issue.reporter ? issue.reporter.displayName : "N/A",
        summary: issue.summary,
        description: issue.description || ""
      }
      
      JSON.generate(issue_details)
    end

    def create_issue(project_key, summary, description, issuetype = "Task")
      issue_params = {
        fields: {
          project: { key: project_key },
          summary: summary,
          description: description,
          issuetype: { name: issuetype }
        }
      }
      
      issue = @client.Issue.build
      issue.save(issue_params)
      
      issue_url = "#{@server_url}/browse/#{issue.key}"
      
      JSON.generate({
        key: issue.key,
        url: issue_url
      })
    end

    def search_issues(jql_str, max_results = 50)
      issues = @client.Issue.jql(jql_str, max_results: max_results)
      
      results = issues.map do |issue|
        {
          key: issue.key,
          summary: issue.summary,
          status: issue.status.name,
          assignee: issue.assignee ? issue.assignee.displayName : "Unassigned"
        }
      end
      
      JSON.generate(results)
    end

    def add_comment(issue_key, comment)
      issue = @client.Issue.find(issue_key)
      issue.comments.build.save(body: comment)
      
      JSON.generate({
        status: "success",
        issue_key: issue_key
      })
    end
  end
end
