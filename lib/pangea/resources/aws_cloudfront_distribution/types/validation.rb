# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module CloudFrontDistributionValidation
          def self.validate_origin_references(attrs)
            origin_ids = attrs.origin.map { |o| o[:origin_id] }
            raise Dry::Struct::Error, "Default cache behavior references non-existent origin: #{attrs.default_cache_behavior[:target_origin_id]}" unless origin_ids.include?(attrs.default_cache_behavior[:target_origin_id])
            attrs.ordered_cache_behavior.each_with_index do |behavior, index|
              raise Dry::Struct::Error, "Ordered cache behavior #{index} references non-existent origin: #{behavior[:target_origin_id]}" unless origin_ids.include?(behavior[:target_origin_id])
            end
            raise Dry::Struct::Error, 'Origin IDs must be unique' unless origin_ids.size == origin_ids.uniq.size
          end

          def self.validate_ssl_configuration(viewer_cert, aliases)
            cert_sources = [
              !viewer_cert[:acm_certificate_arn].nil? && !viewer_cert[:acm_certificate_arn].empty?,
              !viewer_cert[:iam_certificate_id].nil? && !viewer_cert[:iam_certificate_id].empty?,
              viewer_cert[:cloudfront_default_certificate] == true
            ]
            active_sources = cert_sources.count(true)
            raise Dry::Struct::Error, 'Only one SSL certificate source can be specified' if active_sources > 1
            raise Dry::Struct::Error, 'Custom aliases require a custom SSL certificate (ACM or IAM)' if aliases.any? && active_sources.zero?
            raise Dry::Struct::Error, 'Cannot use CloudFront default certificate with custom aliases' if viewer_cert[:cloudfront_default_certificate] && aliases.any?
          end

          def self.validate_geo_restrictions(geo_restriction)
            raise Dry::Struct::Error, "Geographic restrictions require location codes when type is not 'none'" if geo_restriction[:restriction_type] != 'none' && geo_restriction[:locations].empty?
          end

          def self.validate_custom_error_responses(custom_errors)
            error_codes = custom_errors.map { |e| e[:error_code] }
            raise Dry::Struct::Error, 'Custom error response codes must be unique' unless error_codes.size == error_codes.uniq.size
          end

          def self.validate_function_associations(attrs)
            all_behaviors = [attrs.default_cache_behavior] + attrs.ordered_cache_behavior
            all_behaviors.each_with_index do |behavior, index|
              behavior[:lambda_function_association]&.each do |assoc|
                unless assoc[:lambda_arn].match?(/^arn:aws:lambda:us-east-1:\d{12}:function:.+:\d+$/)
                  behavior_type = index.zero? ? 'default' : "ordered[#{index - 1}]"
                  raise Dry::Struct::Error, "Lambda@Edge function ARN must be from us-east-1 and include version: #{behavior_type} behavior"
                end
              end
            end
          end
        end
      end
    end
  end
end
