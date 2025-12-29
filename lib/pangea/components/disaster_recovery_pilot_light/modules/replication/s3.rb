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
  module Components
    module DisasterRecoveryPilotLight
      module Replication
        # S3 bucket replication resources
        module S3
          def create_s3_replication(name, attrs, tags)
            s3_replication = {}

            attrs.critical_data.s3_buckets.each_with_index do |bucket_name, index|
              bucket_resources = create_s3_bucket_replication(
                name, attrs, bucket_name, index, tags
              )
              s3_replication.merge!(bucket_resources)
            end

            s3_replication
          end

          private

          def create_s3_bucket_replication(name, attrs, bucket_name, index, tags)
            dr_bucket_ref = create_dr_bucket(name, attrs, bucket_name, index, tags)
            versioning_ref = create_bucket_versioning(name, dr_bucket_ref, index)
            replication_ref = create_s3_replication_config(
              name, attrs, bucket_name, dr_bucket_ref, index
            )

            {
              "bucket_#{index}".to_sym => dr_bucket_ref,
              "versioning_#{index}".to_sym => versioning_ref,
              "replication_#{index}".to_sym => replication_ref
            }
          end

          def create_dr_bucket(name, attrs, bucket_name, index, tags)
            aws_s3_bucket(
              component_resource_name(name, :dr_s3_bucket, "bucket#{index}".to_sym),
              {
                bucket: "#{bucket_name}-dr-#{attrs.dr_region.region}",
                tags: tags.merge(
                  Region: attrs.dr_region.region,
                  State: "PilotLight",
                  SourceBucket: bucket_name
                )
              }
            )
          end

          def create_bucket_versioning(name, dr_bucket_ref, index)
            aws_s3_bucket_versioning(
              component_resource_name(name, :dr_s3_versioning, "bucket#{index}".to_sym),
              {
                bucket: dr_bucket_ref.id,
                versioning_configuration: { status: "Enabled" }
              }
            )
          end

          def create_s3_replication_config(name, attrs, bucket_name, dr_bucket_ref, index)
            aws_s3_bucket_replication_configuration(
              component_resource_name(name, :s3_replication, "bucket#{index}".to_sym),
              build_s3_replication_params(attrs, bucket_name, dr_bucket_ref)
            )
          end

          def build_s3_replication_params(attrs, bucket_name, dr_bucket_ref)
            {
              bucket: bucket_name,
              role: "arn:aws:iam::ACCOUNT:role/s3-replication-role",
              rule: [{
                id: "ReplicateToDR",
                priority: 1,
                status: "Enabled",
                filter: {},
                destination: build_s3_destination(attrs, dr_bucket_ref),
                delete_marker_replication: { status: "Enabled" }
              }]
            }.compact
          end

          def build_s3_destination(attrs, dr_bucket_ref)
            dest = {
              bucket: dr_bucket_ref.arn,
              storage_class: "STANDARD_IA",
              metrics: {
                status: "Enabled",
                event_threshold: { minutes: 15 }
              }
            }

            if attrs.compliance.rpo_hours <= 1
              dest[:replication_time] = {
                status: "Enabled",
                time: { minutes: 15 }
              }
            end

            dest
          end
        end
      end
    end
  end
end
