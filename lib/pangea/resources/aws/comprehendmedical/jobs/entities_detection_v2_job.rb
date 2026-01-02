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
      module ComprehendMedical
        module Jobs
          # AWS Comprehend Medical Entities Detection V2 Job resource
          module EntitiesDetectionV2Job
            # Creates an AWS Comprehend Medical Entities Detection V2 Job
            #
            # @param name [Symbol] The unique name for this resource instance
            # @param attributes [Hash] The configuration options
            # @option attributes [String] :job_name The name of the job
            # @option attributes [Hash] :input_data_config Input data configuration
            # @option attributes [Hash] :output_data_config Output data configuration
            # @option attributes [String] :data_access_role_arn IAM role ARN for data access
            # @option attributes [String] :language_code The language of input documents
            # @option attributes [String] :client_request_token Client token for idempotency
            # @option attributes [String] :kms_key The KMS key ARN for encryption
            #
            # @example Medical entities detection for clinical notes
            #   aws_comprehendmedical_entities_detection_v2_job(:clinical_notes, {
            #     job_name: "clinical-notes-entities-extraction",
            #     input_data_config: { s3_bucket: "clinical-documents", s3_key: "notes/" },
            #     output_data_config: { s3_bucket: "results", s3_key: "entities/" },
            #     data_access_role_arn: ref(:aws_iam_role, :comprehend_role, :arn),
            #     language_code: "en"
            #   })
            #
            # @return [ResourceReference] Reference to the created job
            def aws_comprehendmedical_entities_detection_v2_job(name, attributes = {})
              build_comprehendmedical_job(
                :aws_comprehendmedical_entities_detection_v2_job,
                name,
                attributes
              )
            end
          end
        end
      end
    end
  end
end
