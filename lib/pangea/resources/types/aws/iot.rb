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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # IoT Thing name validation
      IotThingName = String.constrained(format: /\A[a-zA-Z0-9:_-]{1,128}\z/).constructor { |value|
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Thing name cannot start with ':', '$', or '#'"
        end
        value
      }

      # IoT Thing Type name validation
      IotThingTypeName = String.constrained(format: /\A[a-zA-Z0-9:_-]{1,128}\z/).constructor { |value|
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Thing Type name cannot start with ':', '$', or '#'"
        end
        value
      }

      IotCertificateStatus = String.enum('ACTIVE', 'INACTIVE', 'REVOKED', 'PENDING_TRANSFER', 'REGISTER_INACTIVE', 'PENDING_ACTIVATION')
      IotCertificateFormat = String.enum('PEM')

      IotPolicyName = String.constrained(format: /\A[a-zA-Z0-9:_-]{1,128}\z/).constructor { |value|
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Policy name cannot start with ':', '$', or '#'"
        end
        value
      }

      IotPolicyDocument = String.constructor { |value|
        begin
          parsed = JSON.parse(value)
          unless parsed.is_a?(Hash) && parsed['Version'] && parsed['Statement']
            raise Dry::Types::ConstraintError, "IoT Policy document must have 'Version' and 'Statement' fields"
          end
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "IoT Policy document must be valid JSON"
        end
      }

      IotTopicRuleName = String.constrained(format: /\A[a-zA-Z0-9_]{1,128}\z/).constructor { |value|
        unless value.match?(/\A[a-zA-Z_]/)
          raise Dry::Types::ConstraintError, "IoT Topic Rule name must start with a letter or underscore"
        end
        value
      }

      IotSqlQuery = String.constructor { |value|
        unless value.strip.upcase.start_with?('SELECT')
          raise Dry::Types::ConstraintError, "IoT SQL query must start with SELECT"
        end
        unless value.upcase.include?('FROM')
          raise Dry::Types::ConstraintError, "IoT SQL query must include FROM clause"
        end
        value
      }

      IotTopicRuleDestinationStatus = String.enum('ENABLED', 'DISABLED', 'IN_PROGRESS', 'ERROR')
      IotTopicRuleDestinationType = String.enum('VPC')

      IotSecurityProfileName = String.constrained(format: /\A[a-zA-Z0-9:_-]{1,128}\z/).constructor { |value|
        if value.start_with?(':', '$', '#')
          raise Dry::Types::ConstraintError, "IoT Security Profile name cannot start with ':', '$', or '#'"
        end
        value
      }

      IotBehaviorCriteriaType = String.enum('consecutive-datapoints-to-alarm', 'consecutive-datapoints-to-clear', 'statistical-threshold', 'ml-detection-config')

      IotMetricType = String.enum(
        'ip-count', 'tcp-port-count', 'udp-port-count', 'source-ip-count',
        'authorization-failure-count', 'connection-attempt-count', 'disconnection-count',
        'data-size-in-bytes', 'message-count', 'number-of-authorization-failures'
      )

      IotStatisticalThreshold = Hash.schema(statistic?: String.optional)
      IotMlDetectionConfig = Hash.schema(confidence_level: String.enum('LOW', 'MEDIUM', 'HIGH'))

      IotMqttTopic = String.constructor { |value|
        raise Dry::Types::ConstraintError, "MQTT topic cannot exceed 256 characters" if value.length > 256
        raise Dry::Types::ConstraintError, "MQTT topic cannot contain null character" if value.include?("\0")
        if value.include?('+') || value.include?('#')
          if value.include?('+') && !value.match?(/\A([^+]*\+[^+]*\/)*[^+]*\+?[^+]*\z/)
            raise Dry::Types::ConstraintError, "MQTT topic wildcard '+' must be at topic level boundaries"
          end
          if value.include?('#') && !value.end_with?('#') && !value.end_with?('/#')
            raise Dry::Types::ConstraintError, "MQTT topic wildcard '#' must be at the end of topic"
          end
        end
        value
      }

      IotThingAttributes = Hash.map(
        String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
        String.constrained(max_size: 800)
      ).constructor { |value|
        raise Dry::Types::ConstraintError, "IoT Thing cannot have more than 50 attributes" if value.keys.length > 50
        reserved_names = %w[thingName thingId thingTypeName]
        reserved_found = value.keys.map(&:to_s) & reserved_names
        unless reserved_found.empty?
          raise Dry::Types::ConstraintError, "IoT Thing attributes cannot use reserved names: #{reserved_found.join(', ')}"
        end
        value
      }

      IotThingTypeProperties = Hash.schema(
        description?: String.constrained(max_size: 2028).optional,
        searchable_attributes?: Array.of(String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)).constrained(max_size: 3).optional
      )

      IotCertificateArn = String.constrained(format: /\Aarn:aws:iot:[a-z0-9-]+:\d{12}:cert\/[a-f0-9]{64}\z/)

      IotPrincipalArn = String.constructor { |value|
        cert_pattern = /\Aarn:aws:iot:[a-z0-9-]+:\d{12}:cert\/[a-f0-9]{64}\z/
        cognito_pattern = /\Aarn:aws:cognito-identity:[a-z0-9-]+:\d{12}:identitypool\/[a-z0-9-]+:[a-f0-9-]+\z/
        unless value.match?(cert_pattern) || value.match?(cognito_pattern)
          raise Dry::Types::ConstraintError, "IoT Principal ARN must be a valid certificate or Cognito identity ARN"
        end
        value
      }

      IotJobExecutionStatus = String.enum('QUEUED', 'IN_PROGRESS', 'SUCCEEDED', 'FAILED', 'TIMED_OUT', 'REJECTED', 'REMOVED', 'CANCELED')
      IotJobTargetSelection = String.enum('CONTINUOUS', 'SNAPSHOT')
      IotOtaUpdateStatus = String.enum('CREATE_PENDING', 'CREATE_IN_PROGRESS', 'CREATE_COMPLETE', 'CREATE_FAILED', 'DELETE_IN_PROGRESS', 'DELETE_FAILED')

      IotIndexingConfiguration = Hash.schema(
        thing_indexing_mode?: String.enum('OFF', 'REGISTRY', 'REGISTRY_AND_SHADOW').optional,
        thing_connectivity_indexing_mode?: String.enum('OFF', 'STATUS').optional
      )

      IotLogsLevel = String.enum('DEBUG', 'INFO', 'ERROR', 'WARN', 'DISABLED')
      IotLogsTargetType = String.enum('DEFAULT', 'THING_GROUP')
      IotEndpointType = String.enum('iot:Data', 'iot:Data-ATS', 'iot:CredentialProvider', 'iot:Jobs')

      IotShadowDocument = String.constructor { |value|
        begin
          parsed = JSON.parse(value)
          raise Dry::Types::ConstraintError, "IoT Shadow document must be a JSON object" unless parsed.is_a?(Hash)
          raise Dry::Types::ConstraintError, "IoT Shadow document cannot exceed 8KB" if value.bytesize > 8192
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "IoT Shadow document must be valid JSON"
        end
      }

      IotAlertTargetType = String.enum('SNS')
      IotAlertTarget = Hash.schema(
        alert_target_arn: String.constrained(format: /\Aarn:aws:sns:/),
        role_arn: String.constrained(format: /\Aarn:aws:iam::\d{12}:role\//)
      )

      IotBillingGroupProperties = Hash.schema(billing_group_description?: String.constrained(max_size: 2028).optional)

      IotDynamicGroupQueryString = String.constructor { |value|
        raise Dry::Types::ConstraintError, "IoT Dynamic group query string cannot exceed 500 characters" if value.length > 500
        unless value.include?('attributes.') || value.include?('connectivity.') || value.include?('registry.')
          raise Dry::Types::ConstraintError, "IoT Dynamic group query must reference searchable attributes"
        end
        value
      }
    end
  end
end
