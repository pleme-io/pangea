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


require_relative 'jobs/job_builder'
require_relative 'jobs/entities_detection_v2_job'
require_relative 'jobs/icd10_cm_inference_job'
require_relative 'jobs/phi_detection_job'
require_relative 'jobs/rx_norm_inference_job'
require_relative 'jobs/snomed_ct_inference_job'

module Pangea
  module Resources
    module AWS
      module ComprehendMedical
        # AWS Comprehend Medical resources for medical text analysis
        # These resources provide natural language processing capabilities
        # specifically designed for extracting medical information from clinical text.
        #
        # @see https://docs.aws.amazon.com/comprehend-medical/
        module Jobs
          include JobBuilder
          include EntitiesDetectionV2Job
          include Icd10CmInferenceJob
          include PhiDetectionJob
          include RxNormInferenceJob
          include SnomedCtInferenceJob
        end
      end
    end
  end
end
