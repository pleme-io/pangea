# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module SnowFamily
        # Create a Snowball job for data transfer
        def aws_snowball_job(name, attributes = {})
          required_attrs = %i[job_type resources]
          optional_attrs = {
            description: nil,
            role_arn: nil,
            shipping_details: {},
            snowball_capacity_preference: "T100",
            snowball_type: "STANDARD"
          }

          job_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
          end

          resource(:aws_snowball_job, name) do
            job_type job_attrs[:job_type]
            resources job_attrs[:resources]
            description job_attrs[:description] if job_attrs[:description]
            role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
            snowball_capacity_preference job_attrs[:snowball_capacity_preference]
            snowball_type job_attrs[:snowball_type]

            if job_attrs[:shipping_details].any?
              shipping_details job_attrs[:shipping_details]
            end
          end

          ResourceReference.new(
            type: 'aws_snowball_job',
            name: name,
            resource_attributes: job_attrs,
            outputs: {
              id: "${aws_snowball_job.#{name}.id}",
              arn: "${aws_snowball_job.#{name}.arn}",
              job_state: "${aws_snowball_job.#{name}.job_state}",
              creation_date: "${aws_snowball_job.#{name}.creation_date}"
            }
          )
        end

        # Create a Snowball cluster for large-scale data transfers
        def aws_snowball_cluster(name, attributes = {})
          required_attrs = %i[job_type resources]
          optional_attrs = {
            description: nil,
            role_arn: nil,
            shipping_details: {},
            snowball_type: "EDGE"
          }

          cluster_attrs = optional_attrs.merge(attributes)

          required_attrs.each do |attr|
            raise ArgumentError, "Missing required attribute: #{attr}" unless cluster_attrs.key?(attr)
          end

          resource(:aws_snowball_cluster, name) do
            job_type cluster_attrs[:job_type]
            resources cluster_attrs[:resources]
            description cluster_attrs[:description] if cluster_attrs[:description]
            role_arn cluster_attrs[:role_arn] if cluster_attrs[:role_arn]
            snowball_type cluster_attrs[:snowball_type]

            if cluster_attrs[:shipping_details].any?
              shipping_details cluster_attrs[:shipping_details]
            end
          end

          ResourceReference.new(
            type: 'aws_snowball_cluster',
            name: name,
            resource_attributes: cluster_attrs,
            outputs: {
              id: "${aws_snowball_cluster.#{name}.id}",
              arn: "${aws_snowball_cluster.#{name}.arn}",
              cluster_state: "${aws_snowball_cluster.#{name}.cluster_state}",
              creation_date: "${aws_snowball_cluster.#{name}.creation_date}"
            }
          )
        end
      end
    end
  end
end
