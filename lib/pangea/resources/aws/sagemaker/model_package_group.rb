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
      module SageMaker
        # AWS SageMaker Model Package Group resource
        # This resource manages model package groups in Amazon SageMaker Model Registry.
        # Model package groups contain multiple versions of a model, enabling model versioning,
        # approval workflows, and deployment tracking for machine learning models.
        #
        # @see https://docs.aws.amazon.com/sagemaker/latest/dg/model-registry.html
        module ModelPackageGroup
          # Creates an AWS SageMaker Model Package Group
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the model package group
          # @option attributes [String] :model_package_group_name The name of the model package group (required)
          # @option attributes [String] :model_package_group_description A description of the model package group
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic model package group for fraud detection models
          #   aws_sagemaker_model_package_group(:fraud_detection_models, {
          #     model_package_group_name: "fraud-detection-models",
          #     model_package_group_description: "Model versions for credit card fraud detection"
          #   })
          #
          # @example Production model registry with tags
          #   aws_sagemaker_model_package_group(:customer_churn_models, {
          #     model_package_group_name: "customer-churn-prediction",
          #     model_package_group_description: "XGBoost and neural network models for predicting customer churn",
          #     tags: {
          #       Team: "DataScience",
          #       Project: "CustomerRetention",
          #       ModelType: "Classification",
          #       BusinessUnit: "Marketing"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created model package group
          def aws_sagemaker_model_package_group(name, attributes = {})
            resource = resource(:aws_sagemaker_model_package_group, name) do
              model_package_group_name attributes[:model_package_group_name] if attributes[:model_package_group_name]
              model_package_group_description attributes[:model_package_group_description] if attributes[:model_package_group_description]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_sagemaker_model_package_group',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_sagemaker_model_package_group.#{name}.id}",
                arn: "${aws_sagemaker_model_package_group.#{name}.arn}",
                model_package_group_name: "${aws_sagemaker_model_package_group.#{name}.model_package_group_name}",
                creation_time: "${aws_sagemaker_model_package_group.#{name}.creation_time}",
                model_package_group_status: "${aws_sagemaker_model_package_group.#{name}.model_package_group_status}"
              }
            )
          end
        end
      end
    end
  end
end