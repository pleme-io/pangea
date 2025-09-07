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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ecr_replication_configuration/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECR Replication Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECR Replication Configuration attributes
      # @option attributes [Hash] :replication_configuration The replication configuration
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Cross-region replication
      #   cross_region = aws_ecr_replication_configuration(:cross_region, {
      #     replication_configuration: {
      #       rule: [
      #         {
      #           destination: [
      #             {
      #               region: "us-west-2"
      #             },
      #             {
      #               region: "eu-west-1"
      #             }
      #           ]
      #         }
      #       ]
      #     }
      #   })
      #
      # @example Cross-account replication
      #   cross_account = aws_ecr_replication_configuration(:cross_account, {
      #     replication_configuration: {
      #       rule: [
      #         {
      #           destination: [
      #             {
      #               region: "us-east-1",
      #               registry_id: "123456789012"
      #             },
      #             {
      #               region: "us-west-2", 
      #               registry_id: "987654321098"
      #             }
      #           ]
      #         }
      #       ]
      #     }
      #   })
      #
      # @example Multi-rule replication
      #   multi_rule = aws_ecr_replication_configuration(:multi_rule, {
      #     replication_configuration: {
      #       rule: [
      #         # Production images to multiple regions
      #         {
      #           destination: [
      #             {
      #               region: "us-west-2"
      #             },
      #             {
      #               region: "eu-central-1"
      #             }
      #           ]
      #         },
      #         # DR account replication
      #         {
      #           destination: [
      #             {
      #               region: "us-east-2",
      #               registry_id: disaster_recovery_account_id
      #             }
      #           ]
      #         }
      #       ]
      #     }
      #   })
      def aws_ecr_replication_configuration(name, attributes = {})
        # Validate attributes using dry-struct
        replication_attrs = Types::Types::ECRReplicationConfigurationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecr_replication_configuration, name) do
          replication_configuration do
            # Process each rule
            replication_attrs.replication_configuration[:rule].each do |rule_config|
              rule do
                # Process each destination
                rule_config[:destination].each do |dest_config|
                  destination do
                    region dest_config[:region]
                    registry_id dest_config[:registry_id] if dest_config[:registry_id]
                  end
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ecr_replication_configuration',
          name: name,
          resource_attributes: replication_attrs.to_h,
          outputs: {
            registry_id: "${aws_ecr_replication_configuration.#{name}.registry_id}",
            replication_configuration: "${aws_ecr_replication_configuration.#{name}.replication_configuration}"
          },
          computed_properties: {
            rule_count: replication_attrs.rule_count,
            destination_count: replication_attrs.destination_count,
            destination_regions: replication_attrs.destination_regions,
            destination_accounts: replication_attrs.destination_accounts,
            has_cross_account_replication: replication_attrs.has_cross_account_replication?,
            has_cross_region_replication: replication_attrs.has_cross_region_replication?,
            is_same_account_replication: replication_attrs.is_same_account_replication?,
            all_destinations_have_registry_id: replication_attrs.all_destinations_have_registry_id?,
            replication_scope: replication_attrs.replication_scope,
            estimated_monthly_cost_multiplier: replication_attrs.estimated_monthly_cost_multiplier
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)