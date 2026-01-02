# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module SnowFamily
        # Create a Snowmobile job for exabyte-scale data transfer
        def aws_snowmobile_job(name, attributes = {})
          required_attrs = %i[resources]
          optional_attrs = {
            description: nil,
            role_arn: nil,
            shipping_details: {}
          }

          job_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
          end

          resource(:aws_snowmobile_job, name) do
            job_type "EXPORT"  # Snowmobile is typically for export jobs
            resources job_attrs[:resources]
            description job_attrs[:description] if job_attrs[:description]
            role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
            snowball_type "SNOWMOBILE"

            if job_attrs[:shipping_details].any?
              shipping_details job_attrs[:shipping_details]
            end
          end

          ResourceReference.new(
            type: 'aws_snowmobile_job',
            name: name,
            resource_attributes: job_attrs,
            outputs: {
              id: "${aws_snowmobile_job.#{name}.id}",
              arn: "${aws_snowmobile_job.#{name}.arn}",
              job_state: "${aws_snowmobile_job.#{name}.job_state}",
              capacity: "${aws_snowmobile_job.#{name}.capacity}"
            }
          )
        end
      end
    end
  end
end
