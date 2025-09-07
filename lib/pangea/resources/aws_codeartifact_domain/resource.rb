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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_codeartifact_domain/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeArtifact Domain with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeArtifact Domain attributes
      # @option attributes [String] :domain The name of the domain
      # @option attributes [String] :encryption_key KMS key for encryption
      # @option attributes [Hash] :tags Tags to apply to the domain
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic CodeArtifact domain
      #   artifact_domain = aws_codeartifact_domain(:artifacts, {
      #     domain: "my-company-artifacts",
      #     tags: {
      #       Environment: "production",
      #       Team: "platform"
      #     }
      #   })
      #
      # @example Domain with custom KMS encryption
      #   secure_domain = aws_codeartifact_domain(:secure_artifacts, {
      #     domain: "secure-artifacts",
      #     encryption_key: kms_key.arn,
      #     tags: {
      #       Security: "high",
      #       Environment: "production"
      #     }
      #   })
      #
      # @example Domain with KMS alias
      #   alias_domain = aws_codeartifact_domain(:alias_artifacts, {
      #     domain: "company-packages", 
      #     encryption_key: "alias/codeartifact-key",
      #     tags: {
      #       CostCenter: "engineering",
      #       Environment: "production"
      #     }
      #   })
      #
      # @example Multi-team domain
      #   shared_domain = aws_codeartifact_domain(:shared, {
      #     domain: "shared-packages",
      #     tags: {
      #       Usage: "shared",
      #       ManagedBy: "platform-team"
      #     }
      #   })
      def aws_codeartifact_domain(name, attributes = {})
        # Validate attributes using dry-struct
        domain_attrs = Types::Types::CodeArtifactDomainAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codeartifact_domain, name) do
          # Domain name
          domain domain_attrs.domain
          
          # Encryption key if specified
          encryption_key domain_attrs.encryption_key if domain_attrs.encryption_key
          
          # Apply tags if present
          if domain_attrs.tags.any?
            tags do
              domain_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codeartifact_domain',
          name: name,
          resource_attributes: domain_attrs.to_h,
          outputs: {
            arn: "${aws_codeartifact_domain.#{name}.arn}",
            domain: "${aws_codeartifact_domain.#{name}.domain}",
            encryption_key: "${aws_codeartifact_domain.#{name}.encryption_key}",
            owner: "${aws_codeartifact_domain.#{name}.owner}",
            repository_count: "${aws_codeartifact_domain.#{name}.repository_count}",
            asset_size_bytes: "${aws_codeartifact_domain.#{name}.asset_size_bytes}",
            created_time: "${aws_codeartifact_domain.#{name}.created_time}",
            s3_bucket_arn: "${aws_codeartifact_domain.#{name}.s3_bucket_arn}",
            tags_all: "${aws_codeartifact_domain.#{name}.tags_all}"
          },
          computed_properties: {
            domain_owner_template: domain_attrs.domain_owner_template % { name: name },
            domain_url_template: domain_attrs.domain_url_template,
            uses_custom_encryption: domain_attrs.uses_custom_encryption?,
            uses_default_encryption: domain_attrs.uses_default_encryption?,
            is_kms_arn: domain_attrs.is_kms_arn?,
            is_kms_alias: domain_attrs.is_kms_alias?,
            estimated_monthly_base_cost: domain_attrs.estimated_monthly_base_cost,
            supports_package_formats: domain_attrs.supports_package_formats
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)