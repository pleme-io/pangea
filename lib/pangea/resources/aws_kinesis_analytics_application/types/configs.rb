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
      module Types
        class KinesisAnalyticsApplicationAttributes
          # Configuration type definitions for Kinesis Analytics Application
          module Configs
            S3ContentLocation = Hash.schema(
              bucket_arn: String,
              file_key: String,
              object_version?: String.optional
            )

            CodeContent = Hash.schema(
              text_content?: String.optional,
              zip_file_content?: String.optional,
              s3_content_location?: S3ContentLocation.optional
            )

            ApplicationCodeConfiguration = Hash.schema(
              code_content: CodeContent,
              code_content_type: String.enum('PLAINTEXT', 'ZIPFILE')
            )

            CheckpointConfiguration = Hash.schema(
              configuration_type: String.enum('DEFAULT', 'CUSTOM'),
              checkpointing_enabled?: Bool.optional,
              checkpoint_interval?: Integer.constrained(gteq: 1000, lteq: 300_000).optional,
              min_pause_between_checkpoints?: Integer.constrained(gteq: 0, lteq: 300_000).optional
            )

            MonitoringConfiguration = Hash.schema(
              configuration_type: String.enum('DEFAULT', 'CUSTOM'),
              log_level?: String.enum('INFO', 'WARN', 'ERROR', 'DEBUG').optional,
              metrics_level?: String.enum('APPLICATION', 'TASK', 'OPERATOR', 'PARALLELISM').optional
            )

            ParallelismConfiguration = Hash.schema(
              configuration_type: String.enum('DEFAULT', 'CUSTOM'),
              parallelism?: Integer.constrained(gteq: 1, lteq: 1000).optional,
              parallelism_per_kpu?: Integer.constrained(gteq: 1, lteq: 4).optional,
              auto_scaling_enabled?: Bool.optional
            )

            FlinkApplicationConfiguration = Hash.schema(
              checkpoint_configuration?: CheckpointConfiguration.optional,
              monitoring_configuration?: MonitoringConfiguration.optional,
              parallelism_configuration?: ParallelismConfiguration.optional
            )

            EnvironmentProperties = Hash.schema(
              property_groups: Array.of(Hash.schema(
                property_group_id: String.constrained(min_size: 1, max_size: 50),
                property_map: Hash.map(
                  String.constrained(min_size: 1, max_size: 2048),
                  String.constrained(min_size: 1, max_size: 2048)
                )
              ))
            )

            VpcConfiguration = Hash.schema(
              subnet_ids: Array.of(String).constrained(min_size: 2, max_size: 16),
              security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5)
            )
          end
        end
      end
    end
  end
end
