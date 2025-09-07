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
        # Transit Gateway Route Table Association resource attributes with validation
        class TransitGatewayRouteTableAssociationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :transit_gateway_attachment_id, Resources::Types::String
          attribute :transit_gateway_route_table_id, Resources::Types::String
          attribute? :replace_existing_association, Resources::Types::Bool.default(false)
          
          # Custom validation for association configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate attachment ID format
            if attrs[:transit_gateway_attachment_id] && !attrs[:transit_gateway_attachment_id].match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{attrs[:transit_gateway_attachment_id]}. Expected format: tgw-attach-xxxxxxxx"
            end
            
            # Validate route table ID format
            if attrs[:transit_gateway_route_table_id] && !attrs[:transit_gateway_route_table_id].match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{attrs[:transit_gateway_route_table_id]}. Expected format: tgw-rtb-xxxxxxxx"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def association_purpose
            # Associations control which route table an attachment uses for outbound traffic
            "Associates attachment #{transit_gateway_attachment_id} with route table #{transit_gateway_route_table_id} for outbound routing"
          end
          
          def replaces_default_association?
            replace_existing_association == true
          end
          
          def routing_implications
            implications = {
              outbound_routing: "Attachment will use associated route table for outbound traffic routing",
              route_evaluation: "Routes in the associated route table will be evaluated for traffic from this attachment",
              override_behavior: replace_existing_association? ? "Will replace existing association" : "Will fail if association already exists"
            }
            
            if replace_existing_association?
              implications[:warning] = "Replacing existing association may cause temporary traffic disruption"
            end
            
            implications
          end
          
          def security_considerations
            considerations = []
            
            considerations << "Route table association controls outbound traffic flow from the attachment"
            considerations << "Attachments can only be associated with one route table at a time"
            considerations << "Association determines which routes are available for outbound traffic"
            
            if replace_existing_association?
              considerations << "Replacing existing association may change traffic flows - ensure new routes are configured"
              considerations << "Consider testing route changes in non-production environments first"
            else
              considerations << "Association will fail if attachment is already associated with another route table"
              considerations << "Use replace_existing_association: true to override existing associations"
            end
            
            considerations
          end
          
          def operational_insights
            insights = {
              association_model: "one_to_one", # One attachment to one route table
              traffic_direction: "outbound_only", # Association only affects outbound traffic
              conflict_resolution: replace_existing_association? ? "replace_existing" : "fail_on_conflict"
            }
            
            # Add guidance based on configuration
            if replace_existing_association?
              insights[:change_management] = "Association change will be immediate - plan for potential traffic impact"
            else
              insights[:change_management] = "New association only - existing associations will cause failure"
            end
            
            insights[:best_practice] = "Document which attachments are associated with which route tables for troubleshooting"
            
            insights
          end
          
          def troubleshooting_guide
            guide = {
              common_issues: [
                "Association already exists: Use replace_existing_association: true or remove existing association first",
                "Invalid resource IDs: Verify attachment and route table exist and IDs are correct",
                "Permission errors: Ensure proper IAM permissions for Transit Gateway management"
              ],
              verification_steps: [
                "Check attachment state is 'available' before associating",
                "Verify route table belongs to the same Transit Gateway as attachment",
                "Confirm no conflicting associations exist if replace_existing_association is false"
              ],
              monitoring: [
                "Monitor CloudWatch metrics for route table utilization",
                "Track attachment association changes through CloudTrail",
                "Use VPC Flow Logs to verify traffic is following expected routes"
              ]
            }
            
            if replace_existing_association?
              guide[:replacement_specific] = [
                "Previous association will be removed atomically",
                "Brief traffic disruption may occur during association change",
                "New routes take effect immediately after association"
              ]
            end
            
            guide
          end
          
          def estimated_change_impact
            impact = {
              scope: "attachment_outbound_routing",
              severity: replace_existing_association? ? "medium" : "low",
              duration: "immediate", # Association changes take effect immediately
              rollback_complexity: "low" # Can reassociate to previous route table
            }
            
            if replace_existing_association?
              impact[:warnings] = [
                "Traffic flows from attachment will change immediately",
                "Ensure new route table has appropriate routes configured",
                "Consider gradual migration for production workloads"
              ]
            else
              impact[:warnings] = [
                "New association only - no impact on existing traffic flows",
                "Will fail if attachment already has an association"
              ]
            end
            
            impact
          end
        end
      end
    end
  end
end