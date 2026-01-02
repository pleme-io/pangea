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
    module SustainableMLTraining
      # Shared helper methods for sustainable ML training components
      module Helpers
        def calculate_fsx_capacity(dataset_size_gb)
          # FSx Lustre requires minimum 1.2TB
          # Add 20% overhead for working space
          required_gb = (dataset_size_gb * 1.2).to_i
          # Round up to nearest 1.2TB increment
          ((required_gb / 1200.0).ceil * 1200).clamp(1200, 432_000)
        end

        def calculate_spot_price(input)
          # Calculate max spot price based on percentage
          on_demand_price = 10.0 # Example price
          max_price = on_demand_price * (input.max_spot_price_percentage / 100.0)
          max_price.round(4).to_s
        end

        def get_ml_ami(instance_type)
          # Return appropriate Deep Learning AMI
          if instance_type.include?("trn1")
            "ami-neuron-latest"
          elsif instance_type.include?("p4")
            "ami-nvidia-cuda-12"
          else
            "ami-deep-learning-base"
          end
        end

        def get_training_image(input)
          case input.model_type
          when "computer_vision"
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/pytorch-training:1.13.1-gpu-py39"
          when "natural_language"
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/huggingface-pytorch-training:1.13.1-transformers4.26.0-gpu-py39"
          when "tabular_data"
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/xgboost:latest"
          else
            "763104351884.dkr.ecr.us-west-2.amazonaws.com/tensorflow-training:2.11.0-gpu-py39"
          end
        end

        def select_optimal_instance(input)
          # Select based on priority and availability
          case input.instance_priority
          when "gpu_efficient"
            "ml.p4d.24xlarge" # A100 GPUs
          when "cost_optimized"
            "ml.g4dn.12xlarge" # T4 GPUs
          when "carbon_optimized"
            "ml.trn1.32xlarge" # AWS Trainium
          else
            "ml.p3.8xlarge" # V100 GPUs
          end
        end

        def generate_hyperparameters(input)
          params = {
            "epochs" => "100",
            "batch_size" => "64",
            "learning_rate" => "0.001",
            "checkpoint_frequency" => input.checkpoint_frequency_minutes.to_s
          }

          # Add optimization-specific parameters
          case input.compute_optimization
          when "mixed_precision"
            params["amp"] = "true"
            params["loss_scale"] = "dynamic"
          when "quantization"
            params["quantization_aware"] = "true"
            params["bits"] = "8"
          when "pruning"
            params["pruning_schedule"] = "polynomial"
            params["target_sparsity"] = "0.5"
          end

          params
        end
      end
    end
  end
end
