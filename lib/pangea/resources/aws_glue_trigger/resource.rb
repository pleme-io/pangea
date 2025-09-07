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
require 'pangea/resources/aws_glue_trigger/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Glue Trigger with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Glue Trigger attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_glue_trigger(name, attributes = {})
        # Validate attributes using dry-struct
        trigger_attrs = Types::GlueTriggerAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_glue_trigger, name) do
          # Required attributes
          trigger_name = trigger_attrs.name
          type trigger_attrs.type
          
          # Description
          description trigger_attrs.description if trigger_attrs.description
          
          # Enable/disable
          enabled trigger_attrs.enabled
          
          # Schedule for SCHEDULED triggers
          if trigger_attrs.is_scheduled?
            schedule trigger_attrs.schedule
            start_on_creation trigger_attrs.start_on_creation unless trigger_attrs.start_on_creation.nil?
          end
          
          # Workflow name if specified
          workflow_name trigger_attrs.workflow_name if trigger_attrs.workflow_name
          
          # Actions
          trigger_attrs.actions.each do |action|
            actions do
              if action[:job_name]
                job_name action[:job_name]
                
                if action[:arguments]&.any?
                  arguments do
                    action[:arguments].each do |key, value|
                      public_send(key.gsub(/[^a-zA-Z0-9_]/, '_').downcase, value)
                    end
                  end
                end
                
                timeout action[:timeout] if action[:timeout]
                security_configuration action[:security_configuration] if action[:security_configuration]
                
                if action[:notification_property]
                  notification_property do
                    np = action[:notification_property]
                    notify_delay_after np[:notify_delay_after] if np[:notify_delay_after]
                  end
                end
              elsif action[:crawler_name]
                crawler_name action[:crawler_name]
              end
            end
          end
          
          # Predicate for CONDITIONAL triggers
          if trigger_attrs.is_conditional? && trigger_attrs.predicate
            predicate do
              pred = trigger_attrs.predicate
              logical pred[:logical] if pred[:logical]
              
              if pred[:conditions]&.any?
                pred[:conditions].each do |condition|
                  conditions do
                    logical_operator condition[:logical_operator] if condition[:logical_operator]
                    
                    if condition[:job_name]
                      job_name condition[:job_name]
                      state condition[:state] if condition[:state]
                    elsif condition[:crawler_name]
                      crawler_name condition[:crawler_name]
                      crawl_state condition[:crawl_state] if condition[:crawl_state]
                    end
                  end
                end
              end
            end
          end
          
          # Event batching condition
          if trigger_attrs.event_batching_condition
            event_batching_condition do
              ebc = trigger_attrs.event_batching_condition
              batch_size ebc[:batch_size]
              batch_window ebc[:batch_window] if ebc[:batch_window]
            end
          end
          
          # Apply tags if present
          if trigger_attrs.tags.any?
            tags do
              trigger_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_glue_trigger',
          name: name,
          resource_attributes: trigger_attrs.to_h,
          outputs: {
            id: "${aws_glue_trigger.#{name}.id}",
            name: "${aws_glue_trigger.#{name}.name}",
            arn: "${aws_glue_trigger.#{name}.arn}",
            state: "${aws_glue_trigger.#{name}.state}"
          },
          computed_properties: {
            is_scheduled: trigger_attrs.is_scheduled?,
            is_conditional: trigger_attrs.is_conditional?,
            is_on_demand: trigger_attrs.is_on_demand?,
            is_workflow_trigger: trigger_attrs.is_workflow_trigger?,
            total_actions: trigger_attrs.total_actions,
            job_actions_count: trigger_attrs.job_actions.size,
            crawler_actions_count: trigger_attrs.crawler_actions.size,
            condition_count: trigger_attrs.condition_count,
            schedule_frequency: trigger_attrs.schedule_frequency,
            estimated_executions_per_day: trigger_attrs.estimated_executions_per_day,
            configuration_warnings: trigger_attrs.configuration_warnings
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)