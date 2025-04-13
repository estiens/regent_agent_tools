# frozen_string_literal: true
require_relative '../regent_tool'
require 'json'

module Regent
  # Docker tool for Regent - provides Docker container management capabilities
  class DockerTool < Regent::Tool
    def initialize(name: "docker", description: "Manage Docker containers and images", **options)
      super(name: name, description: description)
    end

    def call(*arguments)
      # Parse arguments based on the action requested
      action = arguments[0]
      
      response = case action
      when "list_containers"
        list_containers(arguments[1] || false)
      when "list_images"
        list_images
      when "run_container"
        run_container(arguments[1], arguments[2], arguments[3])
      when "stop_container"
        stop_container(arguments[1])
      when "remove_container"
        remove_container(arguments[1])
      when "container_logs"
        container_logs(arguments[1])
      else
        raise ToolError, "Unknown Docker action: #{action}"
      end
      
      begin
        parsed = JSON.parse(response)
        return parsed
      rescue JSON::ParserError
        return response
      end
    rescue StandardError => e
      raise ToolError, "Docker tool error: #{e.message}"
    end

    private

    def list_containers(all = false)
      begin
        command = ["docker", "ps"]
        command << "-a" if all
        
        output = `#{command.join(' ')}`
        
        # Parse the output to extract container information
        lines = output.split("\n")
        headers = lines.shift.split(/\s{2,}/).map(&:strip)
        
        containers = []
        lines.each do |line|
          # This is a simplified parsing approach
          parts = line.split(/\s{2,}/)
          container = {}
          
          headers.each_with_index do |header, index|
            container[header.downcase.gsub(/\s+/, '_')] = parts[index]&.strip
          end
          
          containers << container
        end
        
        JSON.generate(containers)
      rescue => e
        raise ToolError, "Error listing containers: #{e.message}"
      end
    end

    def list_images
      begin
        output = `docker images`
        
        # Parse the output to extract image information
        lines = output.split("\n")
        headers = lines.shift.split(/\s{2,}/).map(&:strip)
        
        images = []
        lines.each do |line|
          # This is a simplified parsing approach
          parts = line.split(/\s{2,}/)
          image = {}
          
          headers.each_with_index do |header, index|
            image[header.downcase.gsub(/\s+/, '_')] = parts[index]&.strip
          end
          
          images << image
        end
        
        JSON.generate(images)
      rescue => e
        raise ToolError, "Error listing images: #{e.message}"
      end
    end

    def run_container(image, name = nil, ports = nil)
      begin
        command = ["docker", "run", "-d"]
        
        command << "--name=#{name}" if name
        
        if ports
          if ports.is_a?(Array)
            ports.each do |port|
              command << "-p #{port}"
            end
          else
            command << "-p #{ports}"
          end
        end
        
        command << image
        
        output = `#{command.join(' ')}`
        
        if output.strip.empty?
          raise ToolError, "Failed to run container"
        end
        
        container_id = output.strip
        
        # Get container details
        container_info = `docker inspect #{container_id}`
        container_json = JSON.parse(container_info)
        
        result = {
          id: container_id,
          name: container_json[0]["Name"],
          image: container_json[0]["Config"]["Image"],
          status: container_json[0]["State"]["Status"],
          ports: container_json[0]["NetworkSettings"]["Ports"]
        }
        
        JSON.generate(result)
      rescue => e
        raise ToolError, "Error running container: #{e.message}"
      end
    end

    def stop_container(container_id)
      begin
        output = `docker stop #{container_id}`
        
        if output.strip != container_id
          raise ToolError, "Failed to stop container: #{container_id}"
        end
        
        JSON.generate({
          status: "success",
          container_id: container_id
        })
      rescue => e
        raise ToolError, "Error stopping container: #{e.message}"
      end
    end

    def remove_container(container_id)
      begin
        output = `docker rm #{container_id}`
        
        if output.strip != container_id
          raise ToolError, "Failed to remove container: #{container_id}"
        end
        
        JSON.generate({
          status: "success",
          container_id: container_id
        })
      rescue => e
        raise ToolError, "Error removing container: #{e.message}"
      end
    end

    def container_logs(container_id)
      begin
        output = `docker logs #{container_id}`
        
        JSON.generate({
          container_id: container_id,
          logs: output
        })
      rescue => e
        raise ToolError, "Error getting container logs: #{e.message}"
      end
    end
  end
end
