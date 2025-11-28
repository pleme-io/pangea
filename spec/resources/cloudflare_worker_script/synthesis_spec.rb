# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_worker_script/resource'

RSpec.describe 'cloudflare_worker_script synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    synthesizer = TerraformSynthesizer.new
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_worker_script(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        name: "my-worker",
        content: "export default { async fetch(request) { return new Response('Hello World'); } }"
      })
    end

    result = synthesizer.synthesis
    worker = result[:resource][:cloudflare_worker_script][:test]

    expect(worker[:account_id]).to eq("f037e56e89293a057740de681ac9abbe")
    expect(worker[:name]).to eq("my-worker")
    expect(worker[:content]).to include("Hello World")
  end
end
