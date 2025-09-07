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
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module OpenSearch
        # OpenSearch VPC endpoint for private connectivity
        class VpcEndpointAttributes < Dry::Struct
          attribute :domain_arn, Types::String
          attribute :vpc_options do
            attribute :subnet_ids, Types::Array.of(Types::String)
            attribute :security_group_ids, Types::Array.of(Types::String)
          end
        end

        # OpenSearch VPC endpoint reference
        class VpcEndpointReference < ::Pangea::Resources::ResourceReference
          property :id
          property :endpoint
          property :domain_arn

          def vpc_options
            get_attribute(:vpc_options)
          end

          def subnet_ids
            vpc_options&.subnet_ids || []
          end

          def security_group_ids
            vpc_options&.security_group_ids || []
          end

          def endpoint_url(path = '')
            "https://#{endpoint}#{path}" if endpoint
          end

          def multi_az?
            subnet_ids.length > 1
          end
        end

        module VpcEndpoint
          # Creates a VPC endpoint for private OpenSearch domain access
          #
          # @param name [Symbol] The VPC endpoint name
          # @param attributes [Hash] VPC endpoint configuration
          # @return [VpcEndpointReference] Reference to the VPC endpoint
          def aws_opensearch_vpc_endpoint(name, attributes = {})
            endpoint_attrs = VpcEndpointAttributes.new(attributes)
            
            synthesizer.resource :aws_opensearch_vpc_endpoint, name do
              domain_arn endpoint_attrs.domain_arn

              vpc_options do
                subnet_ids endpoint_attrs.vpc_options.subnet_ids
                security_group_ids endpoint_attrs.vpc_options.security_group_ids
              end
            end

            VpcEndpointReference.new(name, :aws_opensearch_vpc_endpoint, synthesizer, endpoint_attrs)
          end
        end
      end
    end
  end
end