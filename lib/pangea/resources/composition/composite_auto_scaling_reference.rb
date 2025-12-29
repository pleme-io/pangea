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

module Pangea
  module Resources
    # Composite reference for auto scaling web tier
    class CompositeAutoScalingReference
      attr_accessor :security_group, :launch_template, :auto_scaling_group, :target_group,
                    :asg_attachment, :scale_up_policy, :scale_down_policy,
                    :cpu_high_alarm, :cpu_low_alarm
      attr_reader :name

      def initialize(name)
        @name = name
      end

      # Convenience methods
      def min_instances
        @auto_scaling_group&.resource_attributes[:min_size]
      end

      def max_instances
        @auto_scaling_group&.resource_attributes[:max_size]
      end

      def desired_instances
        @auto_scaling_group&.resource_attributes[:desired_capacity]
      end

      def instance_type
        @launch_template&.resource_attributes[:instance_type]
      end

      # Get all resources for tracking
      def all_resources
        resources = []
        resources << @security_group if @security_group
        resources << @launch_template if @launch_template
        resources << @auto_scaling_group if @auto_scaling_group
        resources << @target_group if @target_group
        resources << @asg_attachment if @asg_attachment
        resources << @scale_up_policy if @scale_up_policy
        resources << @scale_down_policy if @scale_down_policy
        resources << @cpu_high_alarm if @cpu_high_alarm
        resources << @cpu_low_alarm if @cpu_low_alarm
        resources
      end
    end
  end
end
