# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Service binding for Pages deployment
        class PagesServiceBinding < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Dry::Types['strict.string']
          attribute :service, Dry::Types['strict.string']
          attribute :environment, Dry::Types['strict.string'].optional.default(nil)
          attribute :entrypoint, Dry::Types['strict.string'].optional.default(nil)
        end

        # R2 bucket binding
        class PagesR2Binding < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Dry::Types['strict.string']
          attribute :bucket_name, Dry::Types['strict.string']
          attribute :jurisdiction, Dry::Types['strict.string'].optional.default(nil)
        end

        # Environment variable configuration
        class PagesEnvVar < Dry::Struct
          transform_keys(&:to_sym)

          attribute :type, Dry::Types['strict.string'].enum('plain_text', 'secret_text')
          attribute :value, Dry::Types['strict.string']
        end
      end
    end
  end
end
