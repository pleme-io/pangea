# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        SageMakerModelImage = String.constrained(
          format: /\A(\d{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com\/|763104351884\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com\/|public\.ecr\.aws\/)/
        )

        SageMakerModelExecutionRole = String.constrained(
          format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
        )

        SageMakerModelContainer = Hash.schema(
          image: SageMakerModelImage,
          model_data_url?: String.optional,
          container_hostname?: String.optional,
          environment?: Hash.map(String, String).optional,
          model_package_name?: String.optional,
          inference_specification_name?: String.optional,
          image_config?: Hash.optional,
          multi_model_config?: Hash.schema(model_cache_setting?: String.enum('Enabled', 'Disabled').optional).optional
        )

        SageMakerModelVpcConfig = Hash.schema(
          security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5),
          subnets: Array.of(String).constrained(min_size: 1, max_size: 16)
        )

        SageMakerModelInferenceExecutionConfig = Hash.schema(mode: String.enum('Serial', 'Direct'))

        class SageMakerModelAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :model_name, Resources::Types::String.constrained(min_size: 1, max_size: 63, format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/)
          attribute :execution_role_arn, SageMakerModelExecutionRole
          attribute :primary_container, SageMakerModelContainer.optional
          attribute :containers, Resources::Types::Array.of(SageMakerModelContainer).optional
          attribute :vpc_config, SageMakerModelVpcConfig.optional
          attribute :enable_network_isolation, Resources::Types::Bool.default(false)
          attribute :inference_execution_config, SageMakerModelInferenceExecutionConfig.optional
          attribute :tags, Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validators.validate_model_name(attrs)
            Validators.validate_containers(attrs)
            Validators.validate_vpc_isolation(attrs)
            Validators.validate_inference_mode(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
