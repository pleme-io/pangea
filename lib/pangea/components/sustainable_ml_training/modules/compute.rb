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

require "base64"

module Pangea
  module Components
    module SustainableMLTraining
      # Compute resources: Instance profile, spot fleet
      module Compute
        def create_instance_profile(input, role)
          aws_iam_instance_profile(:"#{input.name}-instance-profile", {
            role: role.name,
            tags: input.tags
          })
        end

        def create_spot_fleet(input, instance_profile)
          aws_spot_fleet_request(:"#{input.name}-training-fleet", {
            iam_fleet_role: ref(:aws_iam_role, :"#{input.name}-fleet-role", :arn),
            target_capacity: 1, # Typically 1 for ML training
            valid_until: (Time.now + 7 * 24 * 60 * 60).iso8601,
            terminate_instances_with_expiration: true,
            instance_interruption_behavior: input.spot_interruption_behavior,
            launch_specification: build_launch_specifications(input, instance_profile),
            spot_price: calculate_spot_price(input),
            allocation_strategy: "lowestPrice"
          })
        end

        private

        def build_launch_specifications(input, instance_profile)
          input.preferred_instance_types.map do |instance_type|
            {
              instance_type: instance_type,
              image_id: get_ml_ami(instance_type),
              iam_instance_profile: {
                arn: instance_profile.arn
              },
              user_data: Base64.encode64(generate_training_user_data(input)),
              block_device_mappings: [{
                device_name: "/dev/xvda",
                ebs: {
                  volume_size: 500,
                  volume_type: "gp3",
                  delete_on_termination: true
                }
              }]
            }
          end
        end

        def generate_training_user_data(input)
          <<~BASH
            #!/bin/bash
            # Install monitoring tools
            pip install codecarbon tensorboard wandb

            # Configure carbon tracking
            export CODECARBON_COUNTRY=USA
            export CODECARBON_REGION=oregon

            # Enable mixed precision if configured
            if [ "#{input.enable_automatic_mixed_precision}" = "true" ]; then
              export TF_ENABLE_AUTO_MIXED_PRECISION=1
              export TORCH_AUTOCAST=1
            fi

            # Set up efficient data loading
            export NUM_WORKERS=#{input.num_data_loader_workers}
            export PREFETCH_FACTOR=2

            # Configure model caching
            export MODEL_CACHE_DIR=/opt/ml/model_cache
            export TRANSFORMERS_CACHE=$MODEL_CACHE_DIR
            export HF_HOME=$MODEL_CACHE_DIR

            # Start carbon monitoring
            codecarbon monitor --project "#{input.name}" --output /opt/ml/output/carbon_report.csv &
          BASH
        end
      end
    end
  end
end
