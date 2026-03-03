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

require 'pangea/errors'
require 'pangea/logging'

module Pangea
  module Execution
    # Handles retry logic for Terraform operations
    module TerraformRetry
      # Retryable error patterns
      RETRYABLE_ERROR_PATTERNS = [
        /timeout/i,
        /connection.*timed out/i,
        /connection.*refused/i,
        /rate limit/i,
        /throttl/i,
        /temporary failure/i,
        /network.*unreachable/i,
        /could not connect/i,
        /connection reset/i,
        /RequestLimitExceeded/,
        /ServiceUnavailable/
      ].freeze
      
      # Wrapper for operations that should be retried on transient failures
      def with_retries(max_retries: @max_retries || 3, retry_delay: @retry_delay || 2)
        retries = 0
        
        begin
          yield
        rescue StandardError => e
          if retries < max_retries && (retryable_error?(e) || retryable_output?(e.message, ''))
            retries += 1
            delay = retry_delay ** retries
            
            log_retry_attempt(e, retries, max_retries, delay)
            
            sleep(delay)
            retry
          else
            log_retry_failure(e, retries)
            raise
          end
        end
      end
      
      # Check if an error is retryable based on patterns
      def retryable_error?(error)
        error_message = error.message.to_s
        
        RETRYABLE_ERROR_PATTERNS.any? do |pattern|
          error_message.match?(pattern)
        end
      end
      
      # Check if command output indicates a retryable error
      def retryable_output?(output, error)
        combined_output = "#{output} #{error}"
        
        RETRYABLE_ERROR_PATTERNS.any? do |pattern|
          combined_output.match?(pattern)
        end
      end
      
      private
      
      def log_retry_attempt(error, retries, max_retries, delay)
        logger = @logger || Logging.logger
        logger.warn "Retryable error encountered",
                    error: error.message,
                    error_type: error.class.name,
                    retry_attempt: retries,
                    max_retries: max_retries,
                    delay_seconds: delay
      end
      
      def log_retry_failure(error, retries)
        logger = @logger || Logging.logger
        logger.error "Operation failed after retries",
                     error: error.message,
                     error_type: error.class.name,
                     retries: retries
      end
    end
  end
end