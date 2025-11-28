# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_stream_audio_track/resource'

RSpec.describe 'cloudflare_stream_audio_track synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_stream_audio_track(:test, { account_id: "f037e56e89293a057740de681ac9abbe" })
    end
  end
end
