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
      module Types
        class BlockchainQueryAttributes < Dry::Struct
          def is_scheduled_query?
            !schedule_configuration.nil?
          end

          def query_type
            sql = query_string.strip.downcase

            case sql
            when /select.*from.*transaction/ then 'transaction_analysis'
            when /select.*from.*block/ then 'block_analysis'
            when /select.*from.*token/ then 'token_analysis'
            when /select.*from.*contract/ then 'contract_analysis'
            when /select.*balance/ then 'balance_query'
            when /select.*count/ then 'aggregate_query'
            when /select.*sum|avg|min|max/ then 'statistical_query'
            else 'custom_query'
            end
          end

          def blockchain_protocol
            case blockchain_network
            when /ETHEREUM/ then 'ethereum'
            when /BITCOIN/ then 'bitcoin'
            when /POLYGON/ then 'polygon'
            else 'unknown'
            end
          end

          def estimated_cost_per_execution
            network_costs = {
              'ETHEREUM_MAINNET' => 0.50,
              'ETHEREUM_GOERLI_TESTNET' => 0.05,
              'BITCOIN_MAINNET' => 0.40,
              'BITCOIN_TESTNET' => 0.04,
              'POLYGON_MAINNET' => 0.20,
              'POLYGON_MUMBAI_TESTNET' => 0.02
            }

            base_cost = network_costs[blockchain_network] || 0.30
            complexity_multiplier = calculate_complexity_multiplier

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
            when /rate\((\d+) minute/ then "every_#{::Regexp.last_match(1)}_minutes"
            when /rate\((\d+) hour/ then "every_#{::Regexp.last_match(1)}_hours"
            when /rate\((\d+) day/ then "every_#{::Regexp.last_match(1)}_days"
            when /cron\(/ then 'custom_cron'
            else 'unknown'
            end
          end

          def query_complexity_score
            sql = query_string.downcase
            score = 10 # Base complexity

            score += sql.scan(/join/).length * 15
            score += sql.scan(/\(\s*select/).length * 20
            score += sql.scan(/where/).length * 5
            score += sql.scan(/group by/).length * 10
            score += sql.scan(/order by/).length * 5
            score += sql.scan(/count|sum|avg|min|max/).length * 8
            score += sql.scan(/distinct/).length * 10
            score += sql.scan(/over\s*\(/).length * 25

            score
          end

          def estimated_data_size_mb
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

          def parameter_count
            return 0 unless has_parameters?

            parameters.size
          end

          def is_read_only?
            sql = query_string.strip.downcase
            read_only_patterns = %w[select with show describe explain]
            read_only_patterns.any? { |pattern| sql.start_with?(pattern) }
          end

          def security_score
            score = 100

            score -= 50 unless is_read_only?
            score += 15 if data_encryption_enabled?
            score += 5 if uses_kms_encryption?
            score += 10 if is_testnet_query?
            score -= (query_complexity_score / 10).to_i

            [score, 0].max
          end

          private

          def calculate_complexity_multiplier
            case query_complexity_score
            when 0..30 then 1.0
            when 31..60 then 2.0
            when 61..80 then 4.0
            else 6.0
            end
          end
        end
      end
    end
  end
end
