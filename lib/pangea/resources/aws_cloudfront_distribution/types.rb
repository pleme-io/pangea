# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CloudFront Distribution resources
        class CloudFrontDistributionAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Origin configuration for the distribution
          attribute :origin, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              domain_name: Pangea::Resources::Types::String,
              origin_id: Pangea::Resources::Types::String,
              origin_path?: Pangea::Resources::Types::String.optional,
              connection_attempts?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 3).optional,
              connection_timeout?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 10).optional,
              
              # S3 origin configuration
              s3_origin_config?: Pangea::Resources::Types::Hash.schema(
                origin_access_identity?: Pangea::Resources::Types::String.optional,
                origin_access_control_id?: Pangea::Resources::Types::String.optional
              ).optional,
              
              # Custom origin configuration
              custom_origin_config?: Pangea::Resources::Types::Hash.schema(
                http_port?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).default(80),
                https_port?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).default(443),
                origin_protocol_policy: Pangea::Resources::Types::String.constrained(included_in: ['http-only', 'https-only', 'match-viewer']),
                origin_ssl_protocols?: Pangea::Resources::Types::Array.of(
                  Pangea::Resources::Types::String.constrained(included_in: ['SSLv3', 'TLSv1', 'TLSv1.1', 'TLSv1.2'])
                ).default(['TLSv1.2']),
                origin_keepalive_timeout?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 60).default(5),
                origin_read_timeout?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 60).default(30)
              ).optional,
              
              # Origin shield configuration
              origin_shield?: Pangea::Resources::Types::Hash.schema(
                enabled: Pangea::Resources::Types::Bool.default(false),
                origin_shield_region?: Pangea::Resources::Types::String.optional
              ).optional,
              
              # Custom headers to send to origin
              custom_header?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::Hash.schema(
                  name: Pangea::Resources::Types::String,
                  value: Pangea::Resources::Types::String
                )
              ).default([])
            )
          ).constrained(min_size: 1)

          # Default cache behavior
          attribute :default_cache_behavior, Pangea::Resources::Types::Hash.schema(
            target_origin_id: Pangea::Resources::Types::String,
            viewer_protocol_policy: Pangea::Resources::Types::String.constrained(included_in: [
              'allow-all', 'redirect-to-https', 'https-only'
            ]).default('redirect-to-https'),
            allowed_methods?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::String.constrained(included_in: ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT'])
            ).default(['GET', 'HEAD']),
            cached_methods?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::String.constrained(included_in: ['GET', 'HEAD', 'OPTIONS'])
            ).default(['GET', 'HEAD']),
            cache_policy_id?: Pangea::Resources::Types::String.optional,
            origin_request_policy_id?: Pangea::Resources::Types::String.optional,
            response_headers_policy_id?: Pangea::Resources::Types::String.optional,
            realtime_log_config_arn?: Pangea::Resources::Types::String.optional,
            smooth_streaming?: Pangea::Resources::Types::Bool.default(false),
            trusted_signers?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([]),
            trusted_key_groups?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([]),
            compress?: Pangea::Resources::Types::Bool.default(false),
            field_level_encryption_id?: Pangea::Resources::Types::String.optional,
            
            # Function associations
            function_association?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                event_type: Pangea::Resources::Types::String.constrained(included_in: [
                  'viewer-request', 'viewer-response', 'origin-request', 'origin-response'
                ]),
                function_arn: Pangea::Resources::Types::String
              )
            ).default([]),
            
            # Lambda@Edge associations
            lambda_function_association?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(
                event_type: Pangea::Resources::Types::String.constrained(included_in: [
                  'viewer-request', 'viewer-response', 'origin-request', 'origin-response'
                ]),
                lambda_arn: Pangea::Resources::Types::String,
                include_body?: Pangea::Resources::Types::Bool.default(false)
              )
            ).default([])
          )

          # Additional cache behaviors (ordered)
          attribute :ordered_cache_behavior, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              path_pattern: Pangea::Resources::Types::String,
              target_origin_id: Pangea::Resources::Types::String,
              viewer_protocol_policy: Pangea::Resources::Types::String.constrained(included_in: [
                'allow-all', 'redirect-to-https', 'https-only'
              ]).default('redirect-to-https'),
              allowed_methods?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::String.constrained(included_in: ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT'])
              ).default(['GET', 'HEAD']),
              cached_methods?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::String.constrained(included_in: ['GET', 'HEAD', 'OPTIONS'])
              ).default(['GET', 'HEAD']),
              cache_policy_id?: Pangea::Resources::Types::String.optional,
              origin_request_policy_id?: Pangea::Resources::Types::String.optional,
              response_headers_policy_id?: Pangea::Resources::Types::String.optional,
              smooth_streaming?: Pangea::Resources::Types::Bool.default(false),
              trusted_signers?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([]),
              trusted_key_groups?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([]),
              compress?: Pangea::Resources::Types::Bool.default(false),
              field_level_encryption_id?: Pangea::Resources::Types::String.optional,
              function_association?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::Hash.schema(
                  event_type: Pangea::Resources::Types::String.constrained(included_in: [
                    'viewer-request', 'viewer-response', 'origin-request', 'origin-response'
                  ]),
                  function_arn: Pangea::Resources::Types::String
                )
              ).default([]),
              lambda_function_association?: Pangea::Resources::Types::Array.of(
                Pangea::Resources::Types::Hash.schema(
                  event_type: Pangea::Resources::Types::String.constrained(included_in: [
                    'viewer-request', 'viewer-response', 'origin-request', 'origin-response'
                  ]),
                  lambda_arn: Pangea::Resources::Types::String,
                  include_body?: Pangea::Resources::Types::Bool.default(false)
                )
              ).default([])
            )
          ).default([])

          # Comment for the distribution
          attribute :comment, Pangea::Resources::Types::String.default('')

          # Default root object
          attribute? :default_root_object, Pangea::Resources::Types::String.optional

          # Distribution enabled status
          attribute :enabled, Pangea::Resources::Types::Bool.default(true)

          # HTTP version support
          attribute :http_version, Pangea::Resources::Types::String.constrained(included_in: ['http1.1', 'http2']).default('http2')

          # IPv6 support
          attribute :is_ipv6_enabled, Pangea::Resources::Types::Bool.default(true)

          # Price class for edge locations
          attribute :price_class, Pangea::Resources::Types::String.constrained(included_in: [
            'PriceClass_All', 'PriceClass_200', 'PriceClass_100'
          ]).default('PriceClass_All')

          # Custom error responses
          attribute :custom_error_response, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              error_code: Pangea::Resources::Types::Integer.constrained(gteq: 400, lteq: 599),
              response_code?: Pangea::Resources::Types::Integer.constrained(gteq: 200, lteq: 599).optional,
              response_page_path?: Pangea::Resources::Types::String.optional,
              error_caching_min_ttl?: Pangea::Resources::Types::Integer.constrained(gteq: 0).optional
            )
          ).default([])

          # Geographic restrictions
          attribute :restrictions, Pangea::Resources::Types::Hash.schema(
            geo_restriction: Pangea::Resources::Types::Hash.schema(
              restriction_type: Pangea::Resources::Types::String.constrained(included_in: ['blacklist', 'whitelist', 'none']).default('none'),
              locations?: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([])
            ).default({ restriction_type: 'none', locations: [] })
          ).default({ geo_restriction: { restriction_type: 'none', locations: [] } })

          # SSL/TLS certificate configuration
          attribute :viewer_certificate, Pangea::Resources::Types::Hash.schema(
            acm_certificate_arn?: Pangea::Resources::Types::String.optional,
            iam_certificate_id?: Pangea::Resources::Types::String.optional,
            cloudfront_default_certificate?: Pangea::Resources::Types::Bool.optional,
            ssl_support_method?: Pangea::Resources::Types::String.constrained(included_in: ['sni-only', 'vip']).optional,
            minimum_protocol_version?: Pangea::Resources::Types::String.constrained(included_in: [
              'SSLv3', 'TLSv1', 'TLSv1_2016', 'TLSv1.1_2016', 'TLSv1.2_2018', 'TLSv1.2_2019', 'TLSv1.2_2021'
            ]).optional,
            certificate_source?: Pangea::Resources::Types::String.constrained(included_in: ['cloudfront', 'acm', 'iam']).optional
          ).default({})

          # Aliases/CNAMEs for the distribution
          attribute :aliases, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([])

          # Web ACL association
          attribute? :web_acl_id, Pangea::Resources::Types::String.optional

          # Retain on delete
          attribute :retain_on_delete, Pangea::Resources::Types::Bool.default(false)

          # Wait for deployment
          attribute :wait_for_deployment, Pangea::Resources::Types::Bool.default(true)

          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags.default({})

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate origins and behaviors reference consistency
            validate_origin_references(attrs)

            # Validate SSL certificate configuration
            validate_ssl_configuration(attrs.viewer_certificate, attrs.aliases)

            # Validate geographic restrictions
            validate_geo_restrictions(attrs.restrictions[:geo_restriction])

            # Validate custom error responses
            validate_custom_error_responses(attrs.custom_error_response)

            # Validate function and Lambda@Edge associations
            validate_function_associations(attrs)

            attrs
          end

          private

          def self.validate_origin_references(attrs)
            origin_ids = attrs.origin.map { |o| o[:origin_id] }
            
            # Check default cache behavior
            unless origin_ids.include?(attrs.default_cache_behavior[:target_origin_id])
              raise Dry::Struct::Error, "Default cache behavior references non-existent origin: #{attrs.default_cache_behavior[:target_origin_id]}"
            end

            # Check ordered cache behaviors
            attrs.ordered_cache_behavior.each_with_index do |behavior, index|
              unless origin_ids.include?(behavior[:target_origin_id])
                raise Dry::Struct::Error, "Ordered cache behavior #{index} references non-existent origin: #{behavior[:target_origin_id]}"
              end
            end

            # Validate origin IDs are unique
            unless origin_ids.size == origin_ids.uniq.size
              raise Dry::Struct::Error, "Origin IDs must be unique"
            end
          end

          def self.validate_ssl_configuration(viewer_cert, aliases)
            cert_sources = [
              !viewer_cert[:acm_certificate_arn].nil? && !viewer_cert[:acm_certificate_arn].empty?,
              !viewer_cert[:iam_certificate_id].nil? && !viewer_cert[:iam_certificate_id].empty?, 
              viewer_cert[:cloudfront_default_certificate] == true
            ]

            active_sources = cert_sources.count(true)
            
            if active_sources > 1
              raise Dry::Struct::Error, "Only one SSL certificate source can be specified"
            end

            if aliases.any? && active_sources == 0
              raise Dry::Struct::Error, "Custom aliases require a custom SSL certificate (ACM or IAM)"
            end

            if viewer_cert[:cloudfront_default_certificate] && aliases.any?
              raise Dry::Struct::Error, "Cannot use CloudFront default certificate with custom aliases"
            end
          end

          def self.validate_geo_restrictions(geo_restriction)
            if geo_restriction[:restriction_type] != 'none' && geo_restriction[:locations].empty?
              raise Dry::Struct::Error, "Geographic restrictions require location codes when type is not 'none'"
            end
          end

          def self.validate_custom_error_responses(custom_errors)
            error_codes = custom_errors.map { |e| e[:error_code] }
            unless error_codes.size == error_codes.uniq.size
              raise Dry::Struct::Error, "Custom error response codes must be unique"
            end
          end

          def self.validate_function_associations(attrs)
            # Validate Lambda@Edge function ARNs
            all_behaviors = [attrs.default_cache_behavior] + attrs.ordered_cache_behavior
            
            all_behaviors.each_with_index do |behavior, index|
              behavior[:lambda_function_association]&.each do |assoc|
                unless assoc[:lambda_arn].match?(/^arn:aws:lambda:us-east-1:\d{12}:function:.+:\d+$/)
                  behavior_type = index == 0 ? "default" : "ordered[#{index-1}]"
                  raise Dry::Struct::Error, "Lambda@Edge function ARN must be from us-east-1 and include version: #{behavior_type} behavior"
                end
              end
            end
          end

          # Helper methods
          def total_origins_count
            origin.size
          end

          def total_behaviors_count
            1 + ordered_cache_behavior.size # default + ordered
          end

          def has_custom_ssl?
            viewer_certificate[:acm_certificate_arn].present? || viewer_certificate[:iam_certificate_id].present?
          end

          def uses_cloudfront_ssl?
            viewer_certificate[:cloudfront_default_certificate] == true
          end

          def has_custom_domain?
            aliases.any?
          end

          def has_geographic_restrictions?
            restrictions.dig(:geo_restriction, :restriction_type) != 'none'
          end

          def has_custom_error_pages?
            custom_error_response.any?
          end

          def has_origin_shield?
            origin.any? { |o| o[:origin_shield]&.dig(:enabled) == true }
          end

          def has_lambda_at_edge?
            all_behaviors = [default_cache_behavior] + ordered_cache_behavior
            all_behaviors.any? { |b| b[:lambda_function_association]&.any? }
          end

          def has_cloudfront_functions?
            all_behaviors = [default_cache_behavior] + ordered_cache_behavior
            all_behaviors.any? { |b| b[:function_association]&.any? }
          end

          def supports_http2?
            http_version == 'http2'
          end

          def ipv6_enabled?
            is_ipv6_enabled
          end

          def estimated_cost_tier
            case price_class
            when 'PriceClass_100'
              'low'
            when 'PriceClass_200'
              'medium'
            else
              'high'
            end
          end

          def s3_origins_count
            origin.count { |o| o[:s3_origin_config].present? }
          end

          def custom_origins_count
            origin.count { |o| o[:custom_origin_config].present? }
          end

          def primary_domain
            if has_custom_domain?
              aliases.first
            else
              # CloudFront generates domain like d1234567890.cloudfront.net
              "generated.cloudfront.net"
            end
          end

          def security_profile
            factors = []
            factors << "https_only" if default_cache_behavior[:viewer_protocol_policy] == 'https-only'
            factors << "custom_ssl" if has_custom_ssl?
            factors << "waf_enabled" if web_acl_id.present?
            factors << "geo_restricted" if has_geographic_restrictions?
            
            case factors.size
            when 0..1
              'basic'
            when 2..3
              'enhanced'
            else
              'maximum'
            end
          end
        end
      end
    end
  end
end