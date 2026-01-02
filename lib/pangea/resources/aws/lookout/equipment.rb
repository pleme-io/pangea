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

require_relative 'equipment/dataset'
require_relative 'equipment/model'
require_relative 'equipment/inference_scheduler'

module Pangea
  module Resources
    module AWS
      module Lookout
        # AWS Lookout for Equipment resources for predictive maintenance
        # These resources manage industrial equipment monitoring and anomaly detection
        # to predict equipment failures and optimize maintenance schedules.
        #
        # @see https://docs.aws.amazon.com/lookout-for-equipment/
        module Equipment
          include Dataset
          include Model
          include InferenceScheduler
        end
      end
    end
  end
end
