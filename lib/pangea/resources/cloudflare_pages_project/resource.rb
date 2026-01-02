# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resource_registry'
require_relative 'resource/main'
require_relative 'resource/deployment_config'

module Pangea
  module Resources
    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflarePagesProject
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
