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
        # Lambda permission attributes with validation
        class LambdaPermissionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :action, Pangea::Resources::Types::LambdaPermissionAction
          attribute :function_name, Pangea::Resources::Types::String
          attribute :principal, Pangea::Resources::Types::String
          
          # Optional attributes
          attribute :statement_id, Pangea::Resources::Types::String.optional.default { "AllowExecutionFrom#{Time.now.to_i}" }
          attribute :qualifier, Pangea::Resources::Types::String.optional
          attribute :source_arn, Pangea::Resources::Types::String.optional
          attribute :source_account, Pangea::Resources::Types::String.optional
          attribute :event_source_token, Pangea::Resources::Types::String.optional
          attribute :principal_org_id, Pangea::Resources::Types::String.optional
          attribute :function_url_auth_type, Pangea::Resources::Types::String.constrained(included_in: ['AWS_IAM', 'NONE']).optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate principal format
            if attrs[:principal]
              principal = attrs[:principal]
              
              # Check for service principals
              if principal.include?('.amazonaws.com')
                valid_services = %w[
                  apigateway events s3 sns sqs logs 
                  cognito-idp elasticloadbalancing 
                  iot lex states kafka config
                  backup datasync mediaconvert
                ]
                
                service = principal.split('.').first
                unless valid_services.include?(service)
                  raise Dry::Struct::Error, "Unknown AWS service principal: #{principal}"
                end
              elsif !principal.match?(/\A\d{12}\z/) && !principal.match?(/\Aarn:aws:iam::\d{12}:/)
                raise Dry::Struct::Error, "Principal must be an AWS service, account ID, or IAM ARN"
              end
            end
            
            # Validate source ARN format if provided
            if attrs[:source_arn]
              unless attrs[:source_arn].start_with?('arn:aws:')
                raise Dry::Struct::Error, "source_arn must be a valid AWS ARN"
              end
            end
            
            # Validate statement_id format
            if attrs[:statement_id]
              unless attrs[:statement_id].match?(/\A[a-zA-Z0-9_-]+\z/)
                raise Dry::Struct::Error, "statement_id must contain only alphanumeric characters, hyphens, and underscores"
              end
            end
            
            # Function URL auth type requires specific principal
            if attrs[:function_url_auth_type] && attrs[:principal] != 'lambda.alb.amazonaws.com'
              raise Dry::Struct::Error, "function_url_auth_type can only be used with ALB principal"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_service_principal?
            principal.include?('.amazonaws.com')
          end
          
          def service_name
            return nil unless is_service_principal?
            principal.split('.').first
          end
          
          def allows_all_actions?
            action == 'lambda:*'
          end
          
          def is_cross_account?
            return false if is_service_principal?
            principal.match?(/\A\d{12}\z/) || principal.match?(/\Aarn:aws:iam::\d{12}:/)
          end
          
          def requires_source_arn?
            # Some services require source ARN for security
            %w[s3 sns events config].include?(service_name)
          end
        end
      end
    end
  end
end