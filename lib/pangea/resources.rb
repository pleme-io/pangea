# frozen_string_literal: true

# Provider gems (loaded via gem dependencies when available)
%w[pangea-aws pangea-cloudflare pangea-hcloud].each do |gem_name|
  begin
    require gem_name
  rescue LoadError
    # Provider gem not available; resource types from this provider won't be loaded
  end
end

module Pangea
  module Resources
    def self.included(base)
      base.include(AWS) if defined?(AWS)
      base.include(Cloudflare) if defined?(Cloudflare)
      base.include(Hetzner) if defined?(Hetzner)
    end
  end
end
