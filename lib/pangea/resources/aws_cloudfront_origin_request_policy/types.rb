# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class CloudFrontOriginRequestPolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Resources::Types::String
        attribute :comment, Resources::Types::String.default('')
        attribute :headers_config, Resources::Types::Hash.schema(
          header_behavior: Resources::Types::String.enum('none', 'whitelist', 'allViewer', 'allViewerAndWhitelistCloudFront').default('none'),
          headers?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ header_behavior: 'none' })
        attribute :query_strings_config, Resources::Types::Hash.schema(
          query_string_behavior: Resources::Types::String.enum('none', 'whitelist', 'all').default('none'),
          query_strings?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ query_string_behavior: 'none' })
        attribute :cookies_config, Resources::Types::Hash.schema(
          cookie_behavior: Resources::Types::String.enum('none', 'whitelist', 'all').default('none'),
          cookies?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ cookie_behavior: 'none' })
      end
    end
  end
end