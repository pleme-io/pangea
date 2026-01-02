# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 website error document configuration
        class WebsiteErrorDocument < Dry::Struct
          attribute :key, Resources::Types::String

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.key.start_with?('/')
              raise Dry::Struct::Error, "Error document key should not start with '/': #{attrs.key}"
            end

            unless attrs.key.match?(/\.(html|htm)$/i) || attrs.key == 'error.html' || attrs.key.include?('error')
              warn "Error document key '#{attrs.key}' doesn't appear to be an HTML file. Consider using .html extension."
            end

            attrs
          end

          def html_file? = key.match?(/\.(html|htm)$/i)
          def in_subdirectory? = key.include?('/')
          def filename = key.split('/').last
          def directory
            parts = key.split('/')
            parts.length > 1 ? parts[0..-2].join('/') : ''
          end
        end

        # S3 website index document configuration
        class WebsiteIndexDocument < Dry::Struct
          attribute :suffix, Resources::Types::String

          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.suffix.start_with?('/')
              raise Dry::Struct::Error, "Index document suffix should not start with '/': #{attrs.suffix}"
            end

            unless %w[index.html index.htm default.html default.htm].include?(attrs.suffix.downcase)
              warn "Index document suffix '#{attrs.suffix}' is not a common index file name. Consider 'index.html'."
            end

            attrs
          end

          def html_file? = suffix.match?(/\.(html|htm)$/i)
          def common_index_file? = %w[index.html index.htm default.html default.htm].include?(suffix.downcase)
          def filename = suffix.split('/').last
        end
      end
    end
  end
end
