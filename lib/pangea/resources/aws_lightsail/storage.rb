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
    module AWS
      module Lightsail
        # Storage resources for AWS Lightsail
        module Storage
          def aws_lightsail_disk(name, attributes = {})
            required_attrs = %i[availability_zone size_in_gb]
            optional_attrs = { disk_name: nil, tags: {} }

            disk_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, disk_attrs)

            resource(:aws_lightsail_disk, name) do
              availability_zone disk_attrs[:availability_zone]
              size_in_gb disk_attrs[:size_in_gb]
              disk_name disk_attrs[:disk_name] if disk_attrs[:disk_name]
              tags disk_attrs[:tags] if disk_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_disk',
              name: name,
              resource_attributes: disk_attrs,
              outputs: {
                id: "${aws_lightsail_disk.#{name}.id}",
                arn: "${aws_lightsail_disk.#{name}.arn}",
                name: "${aws_lightsail_disk.#{name}.name}",
                support_code: "${aws_lightsail_disk.#{name}.support_code}",
                availability_zone: "${aws_lightsail_disk.#{name}.availability_zone}",
                size_in_gb: "${aws_lightsail_disk.#{name}.size_in_gb}"
              }
            )
          end

          def aws_lightsail_disk_attachment(name, attributes = {})
            required_attrs = %i[disk_name instance_name disk_path]
            validate_required_attrs!(required_attrs, attributes)

            resource(:aws_lightsail_disk_attachment, name) do
              disk_name attributes[:disk_name]
              instance_name attributes[:instance_name]
              disk_path attributes[:disk_path]
            end

            ResourceReference.new(
              type: 'aws_lightsail_disk_attachment',
              name: name,
              resource_attributes: attributes,
              outputs: { id: "${aws_lightsail_disk_attachment.#{name}.id}" }
            )
          end

          def aws_lightsail_bucket(name, attributes = {})
            required_attrs = %i[bucket_name bundle_id]
            optional_attrs = { force_delete: false, tags: {} }

            bucket_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, bucket_attrs)

            resource(:aws_lightsail_bucket, name) do
              bucket_name bucket_attrs[:bucket_name]
              bundle_id bucket_attrs[:bundle_id]
              force_delete bucket_attrs[:force_delete]
              tags bucket_attrs[:tags] if bucket_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_bucket',
              name: name,
              resource_attributes: bucket_attrs,
              outputs: {
                id: "${aws_lightsail_bucket.#{name}.id}",
                arn: "${aws_lightsail_bucket.#{name}.arn}",
                availability_zone: "${aws_lightsail_bucket.#{name}.availability_zone}",
                region: "${aws_lightsail_bucket.#{name}.region}",
                url: "${aws_lightsail_bucket.#{name}.url}"
              }
            )
          end
        end
      end
    end
  end
end
