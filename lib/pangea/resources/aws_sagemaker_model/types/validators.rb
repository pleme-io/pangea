# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SageMakerModelAttributes
          module Validators
            extend self

            def validate_model_name(attrs)
              name = attrs[:model_name]
              return unless name
              reserved = ['aws', 'sagemaker', 'amazon']
              return unless reserved.any? { |p| name.downcase.start_with?(p) }
              raise Dry::Struct::Error, "Model name cannot start with reserved prefixes"
            end

            def validate_containers(attrs)
              primary = attrs[:primary_container]
              containers = attrs[:containers]
              raise Dry::Struct::Error, "Cannot specify both primary_container and containers" if primary && containers
              raise Dry::Struct::Error, "Must specify primary_container or containers" unless primary || containers&.any?
              validate_multi_container(containers) if containers&.size&.> 1
              validate_all_containers(primary, containers)
            end

            def validate_multi_container(containers)
              hostnames = containers.filter_map { |c| c[:container_hostname] }
              raise Dry::Struct::Error, "All containers must have unique container_hostname" if hostnames.size != containers.size
              raise Dry::Struct::Error, "Container hostnames must be unique" if hostnames.uniq.size != hostnames.size
            end

            def validate_all_containers(primary, containers)
              all = [primary, *(containers || [])].compact
              all.each_with_index { |c, i| validate_container(c, i) }
            end

            def validate_container(container, index)
              if container[:model_data_url] && container[:model_data_url] !~ /\As3:\/\/[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]\//
                raise Dry::Struct::Error, "Container #{index}: model_data_url must be valid S3 URL"
              end
              if container[:model_package_name] && container[:model_data_url]
                raise Dry::Struct::Error, "Container #{index}: Cannot specify both model_package_name and model_data_url"
              end
              container[:environment]&.each do |k, v|
                raise Dry::Struct::Error, "Container #{index}: Invalid env var name" unless k =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
                raise Dry::Struct::Error, "Container #{index}: Env var value too long" if v.length > 2048
              end
            end

            def validate_vpc_isolation(attrs)
              return unless attrs[:enable_network_isolation] && attrs[:vpc_config]
              raise Dry::Struct::Error, "vpc_config cannot be specified with network isolation"
            end

            def validate_inference_mode(attrs)
              containers = attrs[:containers]
              return unless containers&.size&.> 1 && attrs[:inference_execution_config]
              return unless attrs[:inference_execution_config][:mode] == 'Serial' && containers.size > 5
              raise Dry::Struct::Error, "Serial mode supports max 5 containers"
            end
          end
        end
      end
    end
  end
end
