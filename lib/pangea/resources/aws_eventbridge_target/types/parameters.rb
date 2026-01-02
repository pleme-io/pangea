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
        # Input transformation validation
        InputTransformer = Types::Hash.schema(input_paths?: Types::Hash.map(String, String).optional, input_template: Types::String)
          .constructor { |value|
            template = value[:input_template]
            raise Dry::Types::ConstraintError, 'Input template must contain substitution patterns or be empty JSON object' unless template.match?(/\{.*\}/) || template == '"{}"'
            value
          }

        RetryPolicy = Types::Hash.schema(maximum_retry_attempts?: Types::Integer.optional.constrained(gteq: 0, lteq: 185),
                                         maximum_event_age_in_seconds?: Types::Integer.optional.constrained(gteq: 60, lteq: 86_400))
        DeadLetterConfig = Types::Hash.schema(arn?: Types::String.optional.constrained(format: /\Aarn:aws:sqs:/))
        HttpParameters = Types::Hash.schema(path_parameter_values?: Types::Hash.map(String, String).optional,
                                            header_parameters?: Types::Hash.map(String, String).optional,
                                            query_string_parameters?: Types::Hash.map(String, String).optional)
        KinesisParameters = Types::Hash.schema(partition_key_path?: Types::String.optional)
        SqsParameters = Types::Hash.schema(message_group_id?: Types::String.optional)

        EcsParameters = Types::Hash.schema(
          task_definition_arn: Types::String.constrained(format: /\Aarn:aws:ecs:/),
          task_count?: Types::Integer.optional.constrained(gteq: 1, lteq: 10),
          launch_type?: Types::String.enum('EC2', 'FARGATE', 'EXTERNAL').optional,
          network_configuration?: Types::Hash.schema(awsvpc_configuration?: Types::Hash.optional).optional,
          platform_version?: Types::String.optional, group?: Types::String.optional,
          capacity_provider_strategy?: Types::Array.of(Types::Hash).optional,
          placement_constraint?: Types::Array.of(Types::Hash).optional,
          placement_strategy?: Types::Array.of(Types::Hash).optional,
          tags?: Types::AwsTags.optional
        )

        BatchParameters = Types::Hash.schema(
          job_definition: Types::String, job_name: Types::String,
          array_properties?: Types::Hash.schema(size?: Types::Integer.optional.constrained(gteq: 2, lteq: 10_000)).optional,
          retry_strategy?: Types::Hash.schema(attempts?: Types::Integer.optional.constrained(gteq: 1, lteq: 10)).optional
        )
      end
    end
  end
end
