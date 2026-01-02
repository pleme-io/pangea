# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 website redirect all requests configuration
        class WebsiteRedirectAllRequestsTo < Dry::Struct
          attribute :host_name, Resources::Types::String
          attribute :protocol, Resources::Types::String.enum("http", "https").optional

          def self.new(attributes = {})
            attrs = super(attributes)

            unless attrs.host_name.match?(/^[a-zA-Z0-9][a-zA-Z0-9\-\.]*[a-zA-Z0-9]$/)
              raise Dry::Struct::Error, "Invalid hostname format: #{attrs.host_name}"
            end

            if attrs.protocol == "http" && !attrs.host_name.match?(/^(localhost|127\.0\.0\.1|.*\.local|.*\.dev)/)
              warn "Using HTTP protocol for production hostname '#{attrs.host_name}' may be insecure. Consider HTTPS."
            end

            attrs
          end

          def uses_https? = protocol == "https"
          def uses_http? = protocol == "http"
          def same_protocol? = protocol.nil?
          def localhost? = host_name.match?(/^(localhost|127\.0\.0\.1|.*\.local|.*\.dev)/)

          def target_url(path = "")
            protocol_part = protocol ? "#{protocol}://" : "//"
            "#{protocol_part}#{host_name}#{path}"
          end
        end
      end
    end
  end
end
