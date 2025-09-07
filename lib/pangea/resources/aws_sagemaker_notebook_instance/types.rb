# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Notebook Instance types
        SageMakerNotebookInstanceType = String.enum(
          'ml.t2.medium', 'ml.t2.large', 'ml.t2.xlarge', 'ml.t2.2xlarge',
          'ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge',
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.8xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5d.xlarge', 'ml.c5d.2xlarge', 'ml.c5d.4xlarge', 'ml.c5d.9xlarge', 'ml.c5d.18xlarge',
          'ml.r4.xlarge', 'ml.r4.2xlarge', 'ml.r4.4xlarge', 'ml.r4.8xlarge', 'ml.r4.16xlarge',
          'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.8xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge'
        )
        
        # SageMaker Notebook Instance volume types
        SageMakerNotebookVolumeType = String.enum('gp2', 'gp3', 'io1', 'io2')
        
        # SageMaker Notebook Instance platform identifier
        SageMakerNotebookPlatformIdentifier = String.enum('notebook-al1-v1', 'notebook-al2-v1', 'notebook-al2-v2')
        
        # SageMaker Notebook Instance root access
        SageMakerNotebookRootAccess = String.enum('Enabled', 'Disabled').default('Enabled')
        
        # SageMaker Notebook Instance status
        SageMakerNotebookInstanceStatus = String.enum('Pending', 'InService', 'Stopping', 'Stopped', 'Failed', 'Deleting', 'Updating')
        
        # SageMaker Notebook Instance attributes with comprehensive validation
        class SageMakerNotebookInstanceAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :instance_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :instance_type, SageMakerNotebookInstanceType
          attribute :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          )
          
          # Optional attributes
          attribute :subnet_id, Resources::Types::String.optional
          attribute :security_group_ids, Resources::Types::Array.of(String).optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :lifecycle_config_name, Resources::Types::String.optional
          attribute :direct_internet_access, String.enum('Enabled', 'Disabled').default('Enabled')
          attribute :volume_size_in_gb, Integer.constrained(gteq: 5, lteq: 16384).default(20)
          attribute :volume_type, SageMakerNotebookVolumeType.default('gp2')
          attribute :accelerator_types, Resources::Types::Array.of(String.enum('ml.eia1.medium', 'ml.eia1.large', 'ml.eia1.xlarge', 'ml.eia2.medium', 'ml.eia2.large', 'ml.eia2.xlarge')).optional
          attribute :default_code_repository, Resources::Types::String.optional
          attribute :additional_code_repositories, Resources::Types::Array.of(String).optional
          attribute :root_access, SageMakerNotebookRootAccess
          attribute :platform_identifier, SageMakerNotebookPlatformIdentifier.optional
          attribute :instance_metadata_service_configuration, Resources::Types::Hash.schema(
            minimum_instance_metadata_service_version: String.enum('1', '2').default('1')
          ).optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker Notebook Instance
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate instance name doesn't conflict with reserved names
            if attrs[:instance_name]
              reserved_names = ['sagemaker', 'aws', 'amazon']
              if reserved_names.any? { |reserved| attrs[:instance_name].downcase.include?(reserved) }
                raise Dry::Struct::Error, "Instance name cannot contain reserved words: #{reserved_names.join(', ')}"
              end
            end
            
            # Validate VPC configuration consistency
            subnet_id = attrs[:subnet_id]
            direct_internet_access = attrs[:direct_internet_access]
            
            if subnet_id && direct_internet_access == 'Enabled'
              # Warn but don't fail - user might have configured NAT gateway
              # In production, you might want to validate the subnet has internet access
            end
            
            if subnet_id.nil? && direct_internet_access == 'Disabled'
              raise Dry::Struct::Error, "direct_internet_access cannot be Disabled without specifying subnet_id"
            end
            
            # Validate security groups are only allowed with VPC
            if attrs[:security_group_ids] && attrs[:security_group_ids].any? && subnet_id.nil?
              raise Dry::Struct::Error, "security_group_ids can only be specified when subnet_id is provided"
            end
            
            # Validate KMS key format
            if attrs[:kms_key_id]
              unless attrs[:kms_key_id] =~ /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/
                raise Dry::Struct::Error, "kms_key_id must be a valid KMS key ARN, alias, or key ID"
              end
            end
            
            # Validate accelerator types are compatible with instance type
            if attrs[:accelerator_types] && attrs[:accelerator_types].any?
              instance_type = attrs[:instance_type]
              if instance_type&.start_with?('ml.t') || instance_type&.start_with?('ml.m4') || instance_type&.start_with?('ml.c4')
                raise Dry::Struct::Error, "Elastic Inference accelerators are not compatible with #{instance_type}"
              end
            end
            
            # Validate code repository URLs
            all_repos = []
            all_repos << attrs[:default_code_repository] if attrs[:default_code_repository]
            all_repos.concat(attrs[:additional_code_repositories] || [])
            
            all_repos.each do |repo|
              unless repo =~ /\A(https:\/\/github\.com\/|https:\/\/git-codecommit\.[a-z0-9-]+\.amazonaws\.com\/|arn:aws:sagemaker:)/
                raise Dry::Struct::Error, "Code repository must be a GitHub URL, CodeCommit URL, or SageMaker Git repo ARN"
              end
            end
            
            # Validate volume configuration
            if attrs[:volume_type] == 'io1' || attrs[:volume_type] == 'io2'
              # For IOPS volumes, validate size makes sense
              volume_size = attrs[:volume_size_in_gb] || 20
              if volume_size < 10
                raise Dry::Struct::Error, "Volume size must be at least 10GB for #{attrs[:volume_type]} volume type"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def estimated_monthly_cost
            instance_cost = get_instance_cost_per_hour * 24 * 30
            storage_cost = volume_size_in_gb * 0.10 # $0.10 per GB per month
            accelerator_cost = get_accelerator_cost_per_hour * 24 * 30
            
            instance_cost + storage_cost + accelerator_cost
          end
          
          def get_instance_cost_per_hour
            # Simplified pricing - real implementation would use AWS pricing API
            case instance_type
            when /^ml\.t/
              case instance_type
              when 'ml.t2.medium' then 0.0464
              when 'ml.t2.large' then 0.0928
              when 'ml.t2.xlarge' then 0.1856
              when 'ml.t2.2xlarge' then 0.3712
              when 'ml.t3.medium' then 0.0548
              when 'ml.t3.large' then 0.1096
              when 'ml.t3.xlarge' then 0.2192
              when 'ml.t3.2xlarge' then 0.4384
              else 0.1
              end
            when /^ml\.m/
              case instance_type
              when /xl/ then instance_type.include?('2xl') ? 0.8 : 0.4
              when /4xl/ then 1.6
              when /8xl/ then 3.2
              else 0.2
              end
            when /^ml\.c/
              case instance_type
              when /xl/ then instance_type.include?('2xl') ? 0.6 : 0.3
              when /4xl/ then 1.2
              when /8xl/ then 2.4
              else 0.15
              end
            when /^ml\.r/
              case instance_type
              when /xl/ then instance_type.include?('2xl') ? 1.0 : 0.5
              when /4xl/ then 2.0
              when /8xl/ then 4.0
              else 0.25
              end
            when /^ml\.p/
              case instance_type
              when 'ml.p2.xlarge' then 0.9
              when 'ml.p2.8xlarge' then 7.2
              when 'ml.p2.16xlarge' then 14.4
              when 'ml.p3.2xlarge' then 3.06
              when 'ml.p3.8xlarge' then 12.24
              when 'ml.p3.16xlarge' then 24.48
              else 1.0
              end
            else
              0.1
            end
          end
          
          def get_accelerator_cost_per_hour
            return 0.0 unless accelerator_types && accelerator_types.any?
            
            accelerator_types.sum do |accelerator|
              case accelerator
              when 'ml.eia1.medium' then 0.13
              when 'ml.eia1.large' then 0.26
              when 'ml.eia1.xlarge' then 0.52
              when 'ml.eia2.medium' then 0.14
              when 'ml.eia2.large' then 0.28
              when 'ml.eia2.xlarge' then 0.56
              else 0.0
              end
            end
          end
          
          def is_gpu_instance?
            instance_type.start_with?('ml.p')
          end
          
          def is_compute_optimized?
            instance_type.start_with?('ml.c')
          end
          
          def is_memory_optimized?
            instance_type.start_with?('ml.r')
          end
          
          def is_burstable?
            instance_type.start_with?('ml.t')
          end
          
          def has_vpc_configuration?
            !subnet_id.nil?
          end
          
          def has_internet_access?
            direct_internet_access == 'Enabled'
          end
          
          def has_accelerators?
            accelerator_types && accelerator_types.any?
          end
          
          def uses_custom_kms_key?
            !kms_key_id.nil?
          end
          
          def has_lifecycle_config?
            !lifecycle_config_name.nil?
          end
          
          def has_code_repositories?
            !default_code_repository.nil? || (additional_code_repositories && additional_code_repositories.any?)
          end
          
          def total_code_repositories
            count = 0
            count += 1 if default_code_repository
            count += additional_code_repositories.size if additional_code_repositories
            count
          end
          
          # Security assessment
          def security_score
            score = 0
            score += 20 if has_vpc_configuration? && !has_internet_access?
            score += 15 if uses_custom_kms_key?
            score += 10 if root_access == 'Disabled'
            score += 10 if has_lifecycle_config?
            score += 10 if platform_identifier == 'notebook-al2-v2' # Latest platform
            score += 15 if instance_metadata_service_configuration&.dig(:minimum_instance_metadata_service_version) == '2'
            score += 5 if security_group_ids && security_group_ids.any?
            
            [score, 100].min
          end
          
          def compliance_status
            issues = []
            issues << "Notebook has direct internet access" if has_internet_access? && has_vpc_configuration?
            issues << "No custom KMS key for encryption" unless uses_custom_kms_key?
            issues << "Root access is enabled" if root_access == 'Enabled'
            issues << "No lifecycle configuration specified" unless has_lifecycle_config?
            issues << "Using older platform identifier" if platform_identifier && platform_identifier != 'notebook-al2-v2'
            issues << "Instance metadata service v1 allowed" unless instance_metadata_service_configuration&.dig(:minimum_instance_metadata_service_version) == '2'
            
            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
          
          # Instance capability summary
          def instance_capabilities
            {
              instance_type: instance_type,
              gpu_enabled: is_gpu_instance?,
              compute_optimized: is_compute_optimized?,
              memory_optimized: is_memory_optimized?,
              burstable: is_burstable?,
              accelerators: accelerator_types || [],
              storage_gb: volume_size_in_gb,
              estimated_monthly_cost: estimated_monthly_cost
            }
          end
        end
      end
    end
  end
end