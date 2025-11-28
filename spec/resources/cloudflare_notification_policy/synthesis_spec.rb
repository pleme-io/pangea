# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_notification_policy/resource'

RSpec.describe 'cloudflare_notification_policy synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_notification_policy(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        name: "My Notification",
        alert_type: "universal_ssl_event_type",
        enabled: true
      })
    end
  end
end
