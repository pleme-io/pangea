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
      # ACM Certificate types
      AcmValidationMethod = String.enum('DNS', 'EMAIL')
      AcmCertificateStatus = String.enum('PENDING_VALIDATION', 'ISSUED', 'INACTIVE', 'EXPIRED', 'VALIDATION_TIMED_OUT', 'REVOKED', 'FAILED')
      AcmKeyAlgorithm = String.enum('RSA-2048', 'RSA-1024', 'RSA-4096', 'EC-prime256v1', 'EC-secp384r1', 'EC-secp521r1')
      CertificateTransparencyLogging = String.default('ENABLED').enum('ENABLED', 'DISABLED')

      AcmValidationOption = Hash.schema(domain_name: DomainName, validation_domain?: DomainName.optional)
      AcmDomainValidationOption = Hash.schema(
        domain_name: DomainName,
        resource_record_name?: String.optional,
        resource_record_type?: String.enum('CNAME', 'A', 'AAAA', 'TXT').optional,
        resource_record_value?: String.optional
      )

      # KMS key types
      KmsKeyUsage = String.enum('SIGN_VERIFY', 'ENCRYPT_DECRYPT')
      KmsKeySpec = String.enum('SYMMETRIC_DEFAULT', 'RSA_2048', 'RSA_3072', 'RSA_4096', 'ECC_NIST_P256', 'ECC_NIST_P384', 'ECC_NIST_P521', 'ECC_SECG_P256K1')
      KmsOrigin = String.enum('AWS_KMS', 'EXTERNAL', 'AWS_CLOUDHSM')
      KmsMultiRegion = Bool.default(false)
      KmsEnableKeyRotation = Bool.constructor { |value, _attrs| value }

      KmsKeyPolicy = String.constrained(format: /\A\{.*\}\z/).constructor { |value|
        begin
          JSON.parse(value)
          value
        rescue JSON::ParserError
          raise Dry::Types::ConstraintError, "KMS key policy must be valid JSON"
        end
      }

      # Secrets Manager types
      SecretsManagerSecretType = String.enum('SecureString', 'String', 'StringList')
      SecretsManagerRecoveryWindowInDays = Integer.constrained(gteq: 7, lteq: 30).default(30)

      SecretName = String.constrained(format: /\A[a-zA-Z0-9\/_+=.@-]{1,512}\z/).constructor { |value|
        if value.start_with?('/') || value.end_with?('/')
          raise Dry::Types::ConstraintError, "Secret name cannot start or end with a slash"
        end
        if value.include?('//')
          raise Dry::Types::ConstraintError, "Secret name cannot contain consecutive slashes"
        end
        value
      }

      SecretArn = String.constrained(format: /\Aarn:aws:secretsmanager:[a-z0-9-]+:\d{12}:secret:[a-zA-Z0-9\/_+=.@-]+-[a-zA-Z0-9]{6}\z/)
      SecretVersionStage = String.enum('AWSCURRENT', 'AWSPENDING').constructor { |value|
        if !['AWSCURRENT', 'AWSPENDING'].include?(value)
          unless value.match?(/\A[a-zA-Z0-9_]{1,256}\z/)
            raise Dry::Types::ConstraintError, "Custom version stage must be alphanumeric with underscores, max 256 characters"
          end
        end
        value
      }

      SecretsManagerReplicaRegion = Hash.schema(region: AwsRegion, kms_key_id?: String.optional)
      SecretValue = String | Hash.map(String, String)
      SecretBinary = String.constructor { |value|
        unless value.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
          raise Dry::Types::ConstraintError, "Secret binary must be base64 encoded"
        end
        begin
          Base64.decode64(value)
          value
        rescue ArgumentError
          raise Dry::Types::ConstraintError, "Secret binary must be valid base64"
        end
      }

      # WAF v2 types
      WafV2Scope = String.enum('REGIONAL', 'CLOUDFRONT')
      WafV2IpAddressVersion = String.enum('IPV4', 'IPV6')
      WafV2DefaultAction = String.enum('ALLOW', 'BLOCK')
      WafV2RuleActionType = String.enum('ALLOW', 'BLOCK', 'COUNT', 'CAPTCHA', 'CHALLENGE')
      WafV2ComparisonOperator = String.enum('EQ', 'NE', 'LE', 'LT', 'GE', 'GT')
      WafV2PositionalConstraint = String.enum('EXACTLY', 'STARTS_WITH', 'ENDS_WITH', 'CONTAINS', 'CONTAINS_WORD')
      WafV2CapacityUnits = Integer.constrained(gteq: 1, lteq: 1500)
      WafV2RateLimit = Integer.constrained(gteq: 100, lteq: 2000000000)

      WafV2StatementType = String.enum(
        'ByteMatchStatement', 'SqliMatchStatement', 'XssMatchStatement', 'SizeConstraintStatement',
        'GeoMatchStatement', 'RuleGroupReferenceStatement', 'IPSetReferenceStatement',
        'RegexPatternSetReferenceStatement', 'RateBasedStatement', 'AndStatement', 'OrStatement',
        'NotStatement', 'ManagedRuleGroupStatement', 'LabelMatchStatement'
      )

      WafV2TextTransformation = String.enum(
        'NONE', 'COMPRESS_WHITE_SPACE', 'HTML_ENTITY_DECODE', 'LOWERCASE', 'CMD_LINE',
        'URL_DECODE', 'BASE64_DECODE', 'HEX_DECODE', 'MD5', 'REPLACE_COMMENTS',
        'ESCAPE_SEQ_DECODE', 'SQL_HEX_DECODE', 'CSS_DECODE', 'JS_DECODE', 'NORMALIZE_PATH',
        'NORMALIZE_PATH_WIN', 'REMOVE_NULLS', 'REPLACE_NULLS', 'BASE64_DECODE_EXT',
        'URL_DECODE_UNI', 'UTF8_TO_UNICODE'
      )

      WafV2FieldToMatch = String.enum(
        'URI', 'QUERY_STRING', 'HEADER', 'METHOD', 'BODY', 'SINGLE_HEADER',
        'SINGLE_QUERY_ARGUMENT', 'ALL_QUERY_ARGUMENTS', 'URI_PATH', 'JSON_BODY',
        'HEADERS', 'COOKIES'
      )

      WafV2JsonBodyMatchPattern = Hash.schema(
        all?: Hash.schema({}).optional,
        included_paths?: Array.of(String).optional
      ).constructor { |value|
        has_all = value.key?(:all)
        has_paths = value.key?(:included_paths) && value[:included_paths]&.any?
        if has_all && has_paths
          raise Dry::Types::ConstraintError, "WAF v2 JSON body match pattern cannot specify both 'all' and 'included_paths'"
        end
        if !has_all && !has_paths
          raise Dry::Types::ConstraintError, "WAF v2 JSON body match pattern must specify either 'all' or 'included_paths'"
        end
        value
      }

      WafV2WebAclArn = String.constrained(format: /\Aarn:aws:wafv2:[a-z0-9-]+:\d{12}:(global|regional)\/webacl\/[a-zA-Z0-9_-]+\/[a-f0-9-]{36}\z/)
    end
  end
end
