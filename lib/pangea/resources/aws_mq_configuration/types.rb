# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # MQ Configuration resource attributes
        class MqConfigurationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9_-]+\z/,
            size: 1..150
          )

          attribute :engine_type, MqEngineType
          
          attribute :engine_version, Resources::Types::String
          
          attribute :data, Resources::Types::String

          attribute? :authentication_strategy, MqAuthenticationStrategy.default('simple')
          
          attribute? :description, Resources::Types::String.constrained(size: 0..1024).optional

          attribute? :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate configuration data format
            if attrs[:data] && attrs[:engine_type]
              data = attrs[:data].strip
              
              case attrs[:engine_type]
              when 'ActiveMQ'
                # ActiveMQ configurations are typically XML
                unless data.start_with?('<?xml') || data.start_with?('<configuration')
                  raise Dry::Struct::Error, "ActiveMQ configuration data should be XML format"
                end
              when 'RabbitMQ'
                # RabbitMQ configurations are typically in Erlang format or JSON
                unless data.include?('[') || data.include?('{') || data.match(/^\w+\s*=/)
                  raise Dry::Struct::Error, "RabbitMQ configuration data should be in Erlang or JSON format"
                end
              end
            end

            super(attrs)
          end

          # Check if configuration is XML (typically ActiveMQ)
          def xml_configuration?
            data.strip.start_with?('<?xml') || data.strip.start_with?('<')
          end

          # Check if configuration is JSON
          def json_configuration?
            data.strip.start_with?('{') || data.strip.start_with?('[')
          end

          # Get configuration size in bytes
          def configuration_size_bytes
            data.bytesize
          end
        end
      end
    end
  end
end