# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module SnowFamily
        # Create a Snowcone job for edge computing and data transfer
        def aws_snowcone_job(name, attributes = {})
          required_attrs = %i[job_type resources]
          optional_attrs = {
            description: nil,
            role_arn: nil,
            shipping_details: {},
            device_configuration: {}
          }

          job_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
          end

          resource(:aws_snowcone_job, name) do
            job_type job_attrs[:job_type]
            resources job_attrs[:resources]
            description job_attrs[:description] if job_attrs[:description]
            role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
            snowball_type "SNC1_HDD"  # Snowcone device type

            if job_attrs[:shipping_details].any?
              shipping_details job_attrs[:shipping_details]
            end

            if job_attrs[:device_configuration].any?
              device_configuration job_attrs[:device_configuration]
            end
          end

          ResourceReference.new(
            type: 'aws_snowcone_job',
            name: name,
            resource_attributes: job_attrs,
            outputs: {
              id: "${aws_snowcone_job.#{name}.id}",
              arn: "${aws_snowcone_job.#{name}.arn}",
              job_state: "${aws_snowcone_job.#{name}.job_state}",
              device_id: "${aws_snowcone_job.#{name}.device_id}"
            }
          )
        end

        # Query Snowcone device information
        def aws_snowcone_device(name, attributes = {})
          optional_attrs = {
            device_id: nil,
            job_id: nil
          }

          device_attrs = optional_attrs.merge(attributes)

          data(:aws_snowball_job, name) do
            job_id device_attrs[:job_id] if device_attrs[:job_id]
          end

          ResourceReference.new(
            type: 'aws_snowball_job',
            name: name,
            resource_attributes: device_attrs,
            outputs: {
              id: "${data.aws_snowball_job.#{name}.id}",
              job_state: "${data.aws_snowball_job.#{name}.job_state}",
              snowball_type: "${data.aws_snowball_job.#{name}.snowball_type}",
              shipping_details: "${data.aws_snowball_job.#{name}.shipping_details}"
            }
          )
        end
      end
    end
  end
end
