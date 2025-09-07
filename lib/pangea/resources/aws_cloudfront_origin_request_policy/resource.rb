# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudfront_origin_request_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_cloudfront_origin_request_policy(name, attributes = {})
        policy_attrs = Types::CloudFrontOriginRequestPolicyAttributes.new(attributes)
        
        resource(:aws_cloudfront_origin_request_policy, name) do
          name policy_attrs.name
          comment policy_attrs.comment if policy_attrs.comment.present?
          
          headers_config do
            header_behavior policy_attrs.headers_config[:header_behavior]
            if policy_attrs.headers_config[:headers]
              headers do
                items policy_attrs.headers_config[:headers][:items] if policy_attrs.headers_config[:headers][:items]
              end
            end
          end
          
          query_strings_config do
            query_string_behavior policy_attrs.query_strings_config[:query_string_behavior]
            if policy_attrs.query_strings_config[:query_strings]
              query_strings do
                items policy_attrs.query_strings_config[:query_strings][:items] if policy_attrs.query_strings_config[:query_strings][:items]
              end
            end
          end
          
          cookies_config do
            cookie_behavior policy_attrs.cookies_config[:cookie_behavior]
            if policy_attrs.cookies_config[:cookies]
              cookies do
                items policy_attrs.cookies_config[:cookies][:items] if policy_attrs.cookies_config[:cookies][:items]
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_cloudfront_origin_request_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_origin_request_policy.#{name}.id}",
            etag: "${aws_cloudfront_origin_request_policy.#{name}.etag}"
          },
          computed: {}
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)