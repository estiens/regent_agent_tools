# Regent Tools Collection

This repository contains 15 high-impact tools ported from the Agno framework to Regent, a Ruby framework for building agents and tools.

## Overview

These tools provide a wide range of capabilities for Regent agents, from interacting with GitHub repositories to analyzing financial data, searching scientific papers, and manipulating CSV files.

Each tool follows Regent's design patterns and provides equivalent functionality to its Agno counterpart, while leveraging Ruby-specific features and libraries.

## Installation

Add this to your application's Gemfile:

```ruby
gem 'regent'
# Add any additional dependencies required by specific tools
```

And then execute:

```bash
$ bundle install
```

## Available Tools

Each tool is in its own subdirectory with its own documentation. See the README.md in each tool's directory for details. Most tools are tested reasonably well, should likely use VCR and make specs complete golden and error paths.

## Usage Example

```ruby
require 'regent'
require_relative 'path/to/github_tool'

# Initialize the agent with tools
agent = Regent::Agent.new(
  tools: [
    Regent::GitHubTool.new(access_token: ENV['GITHUB_ACCESS_TOKEN']),
    Regent::ArXivTool.new
  ]
)

# Use the agent
response = agent.run("Find GitHub repositories about quantum computing and related ArXiv papers")
```

## Documentation

For detailed documentation on each tool, please see [documentation.md](documentation.md).

## Testing

To run tests.... `bx rspec spec....`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspiration for some tools from the [Agno framework](https://github.com/agno-agi/agno)

- [Regent framework](https://github.com/alchaplinsky/regent/) for the Ruby agent architecture
