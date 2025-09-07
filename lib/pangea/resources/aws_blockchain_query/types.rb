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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Blockchain Query resources
      class BlockchainQueryAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Query name (required)
        attribute :query_name, Resources::Types::String

        # Blockchain network (required)
        attribute :blockchain_network, Resources::Types::String.enum(
          'ETHEREUM_MAINNET',
          'ETHEREUM_GOERLI_TESTNET',
          'BITCOIN_MAINNET',
          'BITCOIN_TESTNET',
          'POLYGON_MAINNET',
          'POLYGON_MUMBAI_TESTNET'
        )

        # Query string (required)
        attribute :query_string, Resources::Types::String

        # Output configuration (required)
        attribute :output_configuration, Resources::Types::Hash.schema(
          s3_configuration: Resources::Types::Hash.schema(
            bucket_name: Resources::Types::String,
            key_prefix: Resources::Types::String,
            encryption_configuration?: Resources::Types::Hash.schema(
              encryption_option: Resources::Types::String.enum('SSE_S3', 'SSE_KMS'),
              kms_key?: Resources::Types::String.optional
            ).optional
          )
        )

        # Query parameters (optional)
        attribute? :parameters, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Schedule configuration (optional)
        attribute? :schedule_configuration, Resources::Types::Hash.schema(
          schedule_expression: Resources::Types::String,
          timezone?: Resources::Types::String.optional
        ).optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate query name
          unless attrs.query_name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
            raise Dry::Struct::Error, "query_name must be 1-128 characters long and contain only alphanumeric characters, hyphens, and underscores"
          end

          # Validate SQL query
          sql = attrs.query_string.strip.downcase
          unless sql.start_with?('select')
            raise Dry::Struct::Error, "query_string must be a SELECT statement"
          end

          # Basic SQL injection prevention
          dangerous_keywords = ['drop', 'delete', 'update', 'insert', 'alter', 'create', 'truncate']
          if dangerous_keywords.any? { |keyword| sql.include?(keyword) }
            raise Dry::Struct::Error, "query_string contains potentially dangerous SQL keywords"
          end

          # Validate S3 bucket name
          bucket_name = attrs.output_configuration[:s3_configuration][:bucket_name]
          unless bucket_name.match?(/\A[a-z0-9\-\.]{3,63}\z/)
            raise Dry::Struct::Error, "bucket_name must be a valid S3 bucket name"
          end

          # Validate KMS key if encryption is KMS
          encryption_config = attrs.output_configuration[:s3_configuration][:encryption_configuration]
          if encryption_config && encryption_config[:encryption_option] == 'SSE_KMS'
            unless encryption_config[:kms_key]
              raise Dry::Struct::Error, "kms_key is required when encryption_option is SSE_KMS"
            end
            
            unless encryption_config[:kms_key].match?(/\A(arn:aws:kms:[a-z0-9\-]+:\d{12}:key\/[a-f0-9\-]+|alias\/[a-zA-Z0-9\-_\/]+)\z/)
              raise Dry::Struct::Error, "kms_key must be a valid KMS key ARN or alias"
            end
          end

          # Validate schedule expression if provided
          if attrs.schedule_configuration
            schedule_expr = attrs.schedule_configuration[:schedule_expression]
            unless schedule_expr.match?(/\A(rate\([0-9]+ (minute|minutes|hour|hours|day|days)\)|cron\(.+\))\z/)
              raise Dry::Struct::Error, "schedule_expression must be a valid AWS EventBridge schedule expression"
            end
          end

          attrs
        end

        # Helper methods
        def is_scheduled_query?
          !schedule_configuration.nil?
        end

        def query_type
          sql = query_string.strip.downcase
          
          case sql
          when /select.*from.*transaction/
            'transaction_analysis'
          when /select.*from.*block/
            'block_analysis'
          when /select.*from.*token/
            'token_analysis'
          when /select.*from.*contract/
            'contract_analysis'
          when /select.*balance/
            'balance_query'
          when /select.*count/
            'aggregate_query'
          when /select.*sum|avg|min|max/
            'statistical_query'
          else
            'custom_query'
          end
        end

        def blockchain_protocol
          case blockchain_network
          when /ETHEREUM/
            'ethereum'
          when /BITCOIN/
            'bitcoin'
          when /POLYGON/
            'polygon'
          else
            'unknown'
          end
        end

        def estimated_cost_per_execution
          # Base cost estimates per blockchain network (USD)
          network_costs = {
            'ETHEREUM_MAINNET' => 0.50,
            'ETHEREUM_GOERLI_TESTNET' => 0.05,
            'BITCOIN_MAINNET' => 0.40,
            'BITCOIN_TESTNET' => 0.04,
            'POLYGON_MAINNET' => 0.20,
            'POLYGON_MUMBAI_TESTNET' => 0.02
          }

          base_cost = network_costs[blockchain_network] || 0.30

          # Complexity multiplier based on query
          complexity_multiplier = case query_complexity_score
          when 0..30
            1.0
          when 31..60
            2.0
          when 61..80
            4.0
          else
            6.0
          end

          base_cost * complexity_multiplier
        end

        def data_encryption_enabled?
          encryption_config = output_configuration[:s3_configuration][:encryption_configuration]
          !encryption_config.nil?
        end

        def has_parameters?
          parameters && !parameters.empty?
        end

        def schedule_frequency
          return 'none' unless is_scheduled_query?
          
          schedule_expr = schedule_configuration[:schedule_expression]
          
          case schedule_expr
          when /rate\((\d+) minute/
            minutes = $1.to_i
            "every_#{minutes}_minutes"
          when /rate\((\d+) hour/
            hours = $1.to_i
            "every_#{hours}_hours"
          when /rate\((\d+) day/
            days = $1.to_i
            "every_#{days}_days"
          when /cron\(/
            'custom_cron'
          else
            'unknown'
          end
        end

        def query_complexity_score
          sql = query_string.downcase
          score = 0
          
          # Base complexity
          score += 10
          
          # JOIN operations
          score += sql.scan(/join/).length * 15
          
          # Subqueries
          score += sql.scan(/\(\s*select/).length * 20
          
          # WHERE conditions
          score += sql.scan(/where/).length * 5
          
          # GROUP BY
          score += sql.scan(/group by/).length * 10
          
          # ORDER BY
          score += sql.scan(/order by/).length * 5
          
          # Aggregate functions
          score += sql.scan(/count|sum|avg|min|max/).length * 8
          
          # DISTINCT
          score += sql.scan(/distinct/).length * 10
          
          # Window functions
          score += sql.scan(/over\s*\(/).length * 25
          
          score
        end

        def estimated_data_size_mb
          # Estimate based on blockchain network and query type
          base_sizes = {
            'transaction_analysis' => 50.0,
            'block_analysis' => 20.0,
            'token_analysis' => 30.0,
            'contract_analysis' => 100.0,
            'balance_query' => 5.0,
            'aggregate_query' => 1.0,
            'statistical_query' => 10.0,
            'custom_query' => 25.0
          }

          base_size = base_sizes[query_type] || 25.0

          # Network multiplier (mainnet has more data)
          network_multiplier = blockchain_network.include?('MAINNET') ? 3.0 : 1.0

          base_size * network_multiplier
        end

        def is_mainnet_query?
          blockchain_network.include?('MAINNET')
        end

        def is_testnet_query?
          !is_mainnet_query?
        end

        def encryption_type
          return 'none' unless data_encryption_enabled?
          output_configuration[:s3_configuration][:encryption_configuration][:encryption_option]
        end

        def uses_kms_encryption?
          encryption_type == 'SSE_KMS'
        end

        def result_bucket
          output_configuration[:s3_configuration][:bucket_name]
        end

        def result_key_prefix
          output_configuration[:s3_configuration][:key_prefix]
        end

        # Get parameter count
        def parameter_count
          return 0 unless has_parameters?
          parameters.size
        end

        # Check if query is read-only (security check)
        def is_read_only?
          sql = query_string.strip.downcase
          read_only_patterns = ['select', 'with', 'show', 'describe', 'explain']
          read_only_patterns.any? { |pattern| sql.start_with?(pattern) }
        end

        # Calculate security score
        def security_score
          score = 100
          
          # Penalize if not read-only
          score -= 50 unless is_read_only?
          
          # Bonus for encryption
          score += 15 if data_encryption_enabled?
          score += 5 if uses_kms_encryption?
          
          # Bonus for testnet (less sensitive data)
          score += 10 if is_testnet_query?
          
          # Penalty for high complexity (attack surface)
          score -= (query_complexity_score / 10).to_i
          
          [score, 0].max
        end
      end
    end
      end
    end
  end
end