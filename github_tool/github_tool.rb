# frozen_string_literal: true

module Regent
  # GitHub tool for Regent - provides integration with GitHub repositories
  class GitHubTool < Regent::Tool
    def initialize(name: "github", description: "Interact with GitHub repositories", **options)
      super(name: name, description: description)
      @access_token = options[:access_token] || ENV['GITHUB_ACCESS_TOKEN']
      
      # Initialize GitHub client if token is available
      setup_client if @access_token
    end

    def call(*arguments)
      # Ensure we have a valid client
      raise ToolError, "GitHub access token is required" unless @client
      
      # Parse arguments based on the action requested
      action = arguments[0]
      
      case action
      when "search_repositories"
        search_repositories(arguments[1], 
                           sort: arguments[2] || "stars", 
                           order: arguments[3] || "desc", 
                           page: arguments[4] || 1, 
                           per_page: arguments[5] || 30)
      when "list_repositories"
        list_repositories
      when "get_repository"
        get_repository(arguments[1])
      when "list_pull_requests"
        list_pull_requests(arguments[1])
      when "get_pull_request"
        get_pull_request(arguments[1], arguments[2])
      when "create_issue"
        create_issue(arguments[1], arguments[2], arguments[3])
      else
        raise ToolError, "Unknown GitHub action: #{action}"
      end
    rescue StandardError => e
      raise ToolError, "GitHub tool error: #{e.message}"
    end

    private

    def setup_client
      require 'octokit'
      @client = Octokit::Client.new(access_token: @access_token)
    end

    def search_repositories(query, sort: "stars", order: "desc", page: 1, per_page: 30)
      # Ensure per_page doesn't exceed GitHub's max of 100
      per_page = [per_page, 100].min
      
      repositories = @client.search_repositories(query, sort: sort, order: order, page: page, per_page: per_page)
      
      repo_list = repositories.items.map do |repo|
        {
          full_name: repo.full_name,
          description: repo.description,
          url: repo.html_url,
          stars: repo.stargazers_count,
          forks: repo.forks_count,
          language: repo.language
        }
      end
      
      JSON.generate(repo_list)
    end

    def list_repositories
      repos = @client.repositories
      repo_names = repos.map(&:full_name)
      JSON.generate(repo_names)
    end

    def get_repository(repo_name)
      repo = @client.repository(repo_name)
      repo_info = {
        full_name: repo.full_name,
        description: repo.description,
        url: repo.html_url,
        stars: repo.stargazers_count,
        forks: repo.forks_count,
        language: repo.language,
        open_issues: repo.open_issues_count,
        default_branch: repo.default_branch
      }
      JSON.generate(repo_info)
    end

    def list_pull_requests(repo_name)
      pull_requests = @client.pull_requests(repo_name)
      pr_list = pull_requests.map do |pr|
        {
          number: pr.number,
          title: pr.title,
          state: pr.state,
          user: pr.user.login,
          created_at: pr.created_at,
          updated_at: pr.updated_at,
          url: pr.html_url
        }
      end
      JSON.generate(pr_list)
    end

    def get_pull_request(repo_name, number)
      pr = @client.pull_request(repo_name, number)
      pr_info = {
        number: pr.number,
        title: pr.title,
        state: pr.state,
        user: pr.user.login,
        body: pr.body,
        created_at: pr.created_at,
        updated_at: pr.updated_at,
        merged_at: pr.merged_at,
        url: pr.html_url
      }
      JSON.generate(pr_info)
    end

    def create_issue(repo_name, title, body)
      issue = @client.create_issue(repo_name, title, body)
      issue_info = {
        number: issue.number,
        title: issue.title,
        state: issue.state,
        url: issue.html_url
      }
      JSON.generate(issue_info)
    end
  end
end
