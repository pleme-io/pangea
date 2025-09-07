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
        # Auto Scaling Attachment resource attributes with validation
        class AutoScalingAttachmentAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required: Auto Scaling Group name or ID
          attribute :autoscaling_group_name, Resources::Types::String
          
          # One of these is required (mutually exclusive)
          attribute :elb, Resources::Types::String.optional.default(nil)
          attribute :lb_target_group_arn, Resources::Types::String.optional.default(nil)
          attribute :alb_target_group_arn, Resources::Types::String.optional.default(nil)  # Deprecated alias
          
          # Validate that exactly one target is specified
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Count how many attachment targets are specified
            targets = [
              attrs[:elb],
              attrs[:lb_target_group_arn],
              attrs[:alb_target_group_arn]
            ].compact
            
            if targets.empty?
              raise Dry::Struct::Error, "Auto Scaling attachment must specify one of: elb, lb_target_group_arn, or alb_target_group_arn"
            end
            
            if targets.size > 1
              raise Dry::Struct::Error, "Auto Scaling attachment can only specify one target type"
            end
            
            # Handle deprecated alb_target_group_arn
            if attrs[:alb_target_group_arn] && !attrs[:lb_target_group_arn]
              attrs[:lb_target_group_arn] = attrs[:alb_target_group_arn]
              attrs.delete(:alb_target_group_arn)
            end
            
            super(attrs)
          end
          
          # Computed properties
          def attachment_type
            return :classic_lb if elb
            return :target_group if lb_target_group_arn
            :unknown
          end
          
          def target_arn
            lb_target_group_arn || elb
          end
          
          def to_h
            {
              autoscaling_group_name: autoscaling_group_name,
              elb: elb,
              lb_target_group_arn: lb_target_group_arn
            }.compact
          end
        end
      end
    end
  end
end