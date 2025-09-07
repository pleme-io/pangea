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
require 'pangea/resources/aws_braket_job_queue/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Braket Job Queue for managing quantum job execution
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Braket job queue attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_job_queue(name, attributes = {})
        # Validate attributes using dry-struct
        queue_attrs = Types::BraketJobQueueAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_braket_job_queue, name) do
          # Set queue name
          queue_name queue_attrs.queue_name
          
          # Set device ARN
          device_arn queue_attrs.device_arn
          
          # Set priority
          priority queue_attrs.priority
          
          # Set state
          state queue_attrs.state
          
          # Set compute environment order
          queue_attrs.compute_environment_order.each_with_index do |compute_env, index|
            compute_environment_order do
              order compute_env[:order]
              compute_environment compute_env[:compute_environment]
            end
          end
          
          # Set job timeout if provided
          if queue_attrs.job_timeout_in_seconds
            job_timeout_in_seconds queue_attrs.job_timeout_in_seconds
          end
          
          # Set service role
          if queue_attrs.service_role
            service_role queue_attrs.service_role
          end
          
          # Set scheduling policy ARN if provided
          if queue_attrs.scheduling_policy_arn
            scheduling_policy_arn queue_attrs.scheduling_policy_arn
          end
          
          # Set tags
          if queue_attrs.tags && !queue_attrs.tags.empty?
            tags queue_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_job_queue',
          name: name,
          resource_attributes: queue_attrs.to_h,
          outputs: {
            arn: "${aws_braket_job_queue.#{name}.arn}",
            queue_name: "${aws_braket_job_queue.#{name}.queue_name}",
            state: "${aws_braket_job_queue.#{name}.state}",
            status: "${aws_braket_job_queue.#{name}.status}",
            status_reason: "${aws_braket_job_queue.#{name}.status_reason}",
            priority: "${aws_braket_job_queue.#{name}.priority}",
            device_arn: "${aws_braket_job_queue.#{name}.device_arn}"
          },
          computed: {
            is_quantum_device: queue_attrs.is_quantum_device?,
            is_simulator: queue_attrs.is_simulator?,
            is_enabled: queue_attrs.is_enabled?,
            is_disabled: queue_attrs.is_disabled?,
            has_timeout: queue_attrs.has_timeout?,
            device_provider: queue_attrs.device_provider,
            device_type: queue_attrs.device_type,
            timeout_hours: queue_attrs.timeout_hours,
            compute_environment_count: queue_attrs.compute_environment_count,
            has_scheduling_policy: queue_attrs.has_scheduling_policy?,
            estimated_cost_factor: queue_attrs.estimated_cost_factor
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)