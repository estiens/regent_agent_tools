require "rspec"
require_relative "../docker_tool/docker_tool"

RSpec.describe Regent::DockerTool do
  let(:tool) { described_class.new }

  it "can be initialized" do
    expect(tool).to be_a(Regent::DockerTool)
  end

  it "lists containers (returns an array, may be empty if no containers running)" do
    result = tool.call("list_containers")
    expect(result).to be_a(Array)
  end

  it "lists images (returns an array, may be empty if no images present)" do
    result = tool.call("list_images")
    expect(result).to be_a(Array)
  end

  it "raises error for unknown action" do
    expect { tool.call("not_a_real_action") }.to raise_error(StandardError)
  end
end
