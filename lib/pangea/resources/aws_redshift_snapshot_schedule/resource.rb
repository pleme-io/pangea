# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_redshift_snapshot_schedule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Redshift Snapshot Schedule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Redshift Snapshot Schedule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_redshift_snapshot_schedule(name, attributes = {})
        # Validate attributes using dry-struct
        schedule_attrs = Types::RedshiftSnapshotScheduleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_redshift_snapshot_schedule, name) do
          # Required attributes
          identifier schedule_attrs.identifier
          definitions schedule_attrs.definitions
          
          # Optional description
          description schedule_attrs.generated_description
          
          # Force destroy
          force_destroy schedule_attrs.force_destroy
          
          # Apply tags if present
          if schedule_attrs.tags.any?
            tags do
              schedule_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_redshift_snapshot_schedule',
          name: name,
          resource_attributes: schedule_attrs.to_h,
          outputs: {
            id: "${aws_redshift_snapshot_schedule.#{name}.id}",
            arn: "${aws_redshift_snapshot_schedule.#{name}.arn}",
            definitions: "${aws_redshift_snapshot_schedule.#{name}.definitions}"
          },
          computed_properties: {
            has_rate_schedules: schedule_attrs.has_rate_schedules?,
            has_cron_schedules: schedule_attrs.has_cron_schedules?,
            minimum_interval_hours: schedule_attrs.minimum_interval_hours,
            maximum_interval_hours: schedule_attrs.maximum_interval_hours,
            estimated_snapshots_per_day: schedule_attrs.estimated_snapshots_per_day,
            high_frequency: schedule_attrs.high_frequency?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)