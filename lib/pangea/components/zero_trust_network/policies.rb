# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module ZeroTrustNetwork
      # Policy generation for Zero Trust Network
      module Policies
        def generate_default_policy(attrs)
          policy = {
            version: '2012-10-17',
            statement: [
              {
                effect: 'Allow',
                principal: {
                  federated: attrs.identity_provider[:identity_provider_arn] ||
                    "arn:aws:iam::#{aws_account_id}:saml-provider/#{attrs.identity_provider[:issuer]}"
                },
                action: 'sts:AssumeRoleWithWebIdentity',
                condition: {}
              }
            ]
          }

          add_mfa_condition(policy, attrs)
          add_session_duration_condition(policy, attrs)

          JSON.pretty_generate(policy)
        end

        def generate_endpoint_policy(endpoint, _attrs)
          policy = {
            version: '2012-10-17',
            statement: [
              {
                effect: 'Allow',
                action: ['verified-access:*'],
                resource: '*',
                condition: {
                  'StringEquals' => {
                    'verified-access:endpoint-type' => endpoint[:type]
                  }
                }
              }
            ]
          }

          JSON.pretty_generate(policy)
        end

        private

        def add_mfa_condition(policy, attrs)
          return unless attrs.verification_settings[:require_mfa]

          policy[:statement][0][:condition]['Bool'] = {
            'aws:MultiFactorAuthPresent' => 'true'
          }
        end

        def add_session_duration_condition(policy, attrs)
          policy[:statement][0][:condition]['NumericLessThanEquals'] = {
            'aws:TokenIssueTime' => attrs.verification_settings[:session_duration]
          }
        end
      end
    end
  end
end
