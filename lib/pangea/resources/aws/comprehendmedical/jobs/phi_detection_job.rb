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
          # AWS Comprehend Medical PHI Detection Job resource
          module PhiDetectionJob
            # Creates an AWS Comprehend Medical PHI Detection Job
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
            # @example PHI detection for HIPAA compliance
            #   aws_comprehendmedical_phi_detection_job(:hipaa_phi_detection, {
            #     job_name: "hipaa-phi-detection-clinical-notes",
            #     input_data_config: { s3_bucket: "clinical-raw", s3_key: "patient-records/" },
            #     output_data_config: { s3_bucket: "phi-results", s3_key: "detected-phi/" },
            #     data_access_role_arn: ref(:aws_iam_role, :phi_detection_role, :arn),
            #     language_code: "en"
            #   })
            #
            # @return [ResourceReference] Reference to the created job
            def aws_comprehendmedical_phi_detection_job(name, attributes = {})
              build_comprehendmedical_job(
                :aws_comprehendmedical_phi_detection_job,
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
