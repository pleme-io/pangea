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
require 'pangea/resources/aws_media_live_input/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaLive Input with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] MediaLive input attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_media_live_input(name, attributes = {})
        # Validate attributes using dry-struct
        input_attrs = Types::MediaLiveInputAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_medialive_input, name) do
          # Basic configuration
          name input_attrs.name
          type input_attrs.type
          input_class input_attrs.input_class
          
          # Destinations for push inputs
          if input_attrs.push_input? && input_attrs.destinations.any?
            input_attrs.destinations.each do |destination|
              destinations do
                stream_name destination[:stream_name] if destination[:stream_name]
                url destination[:url] if destination[:url]
              end
            end
          end
          
          # Input devices for hardware inputs
          if input_attrs.device_input? && input_attrs.input_devices.any?
            input_attrs.input_devices.each do |device|
              input_devices do
                id device[:id]
                
                if device[:settings]
                  settings do
                    # Audio channel pairs
                    if device[:settings][:audio_channel_pairs]
                      device[:settings][:audio_channel_pairs].each do |pair|
                        audio_channel_pairs do
                          id pair[:id]
                          profile pair[:profile] if pair[:profile]
                        end
                      end
                    end
                    
                    codec device[:settings][:codec] if device[:settings][:codec]
                    max_bitrate device[:settings][:max_bitrate] if device[:settings][:max_bitrate]
                    resolution device[:settings][:resolution] if device[:settings][:resolution]
                    scan_type device[:settings][:scan_type] if device[:settings][:scan_type]
                  end
                end
              end
            end
          end
          
          # MediaConnect flows
          if input_attrs.mediaconnect_input? && input_attrs.media_connect_flows.any?
            input_attrs.media_connect_flows.each do |flow|
              media_connect_flows do
                flow_arn flow[:flow_arn]
              end
            end
          end
          
          # Input security groups
          if input_attrs.input_security_groups.any?
            input_security_groups input_attrs.input_security_groups
          end
          
          # Role ARN if provided
          role_arn input_attrs.role_arn if input_attrs.role_arn
          
          # Sources for pull inputs
          if (input_attrs.pull_input? || input_attrs.file_input?) && input_attrs.sources.any?
            input_attrs.sources.each do |source|
              sources do
                password_param source[:password_param] if source[:password_param]
                url source[:url]
                username source[:username] if source[:username]
              end
            end
          end
          
          # VPC configuration
          if input_attrs.has_vpc_config?
            vpc do
              security_group_ids input_attrs.vpc[:security_group_ids] if input_attrs.vpc[:security_group_ids]
              subnet_ids input_attrs.vpc[:subnet_ids] if input_attrs.vpc[:subnet_ids]
            end
          end
          
          # Apply tags
          if input_attrs.tags.any?
            tags do
              input_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_medialive_input',
          name: name,
          resource_attributes: input_attrs.to_h,
          outputs: {
            arn: "${aws_medialive_input.#{name}.arn}",
            attached_channels: "${aws_medialive_input.#{name}.attached_channels}",
            id: "${aws_medialive_input.#{name}.id}",
            input_class: "${aws_medialive_input.#{name}.input_class}",
            input_devices: "${aws_medialive_input.#{name}.input_devices}",
            input_partner_ids: "${aws_medialive_input.#{name}.input_partner_ids}",
            input_source_type: "${aws_medialive_input.#{name}.input_source_type}",
            media_connect_flows: "${aws_medialive_input.#{name}.media_connect_flows}",
            security_groups: "${aws_medialive_input.#{name}.security_groups}",
            sources: "${aws_medialive_input.#{name}.sources}"
          },
          computed: {
            push_input: input_attrs.push_input?,
            pull_input: input_attrs.pull_input?,
            file_input: input_attrs.file_input?,
            device_input: input_attrs.device_input?,
            mediaconnect_input: input_attrs.mediaconnect_input?,
            cdi_input: input_attrs.cdi_input?,
            single_pipeline: input_attrs.single_pipeline?,
            standard_input: input_attrs.standard_input?,
            has_redundancy: input_attrs.has_redundancy?,
            destination_count: input_attrs.destination_count,
            source_count: input_attrs.source_count,
            device_count: input_attrs.device_count,
            mediaconnect_flow_count: input_attrs.mediaconnect_flow_count,
            has_vpc_config: input_attrs.has_vpc_config?,
            has_security_groups: input_attrs.has_security_groups?,
            requires_role: input_attrs.requires_role?,
            supports_failover: input_attrs.supports_failover?,
            is_live_input: input_attrs.is_live_input?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)