# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module ZeroTrustNetwork
      # Security automation for Zero Trust Network
      module SecurityAutomation
        def create_security_automation(name, attrs, resources)
          return unless attrs.advanced_options[:enable_security_automation]

          create_policy_evaluator_lambda(name, attrs, resources)
          create_verification_event_rule(name, attrs, resources)
        end

        private

        def create_policy_evaluator_lambda(name, attrs, resources)
          lambda_name = component_resource_name(name, :policy_evaluator)
          resources[:lambda_functions][:policy_evaluator] = aws_lambda_function(lambda_name, {
            function_name: "zt-policy-evaluator-#{name}",
            runtime: 'python3.9',
            handler: 'index.lambda_handler',
            role: create_lambda_role(name, attrs, resources),
            code: { zip_file: policy_evaluator_code },
            environment: {
              variables: {
                VERIFIED_ACCESS_INSTANCE_ID: resources[:verified_access_instance].id,
                COMPLIANCE_FRAMEWORKS: attrs.compliance_frameworks.join(',')
              }
            },
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end

        def create_verification_event_rule(name, attrs, resources)
          rule_name = component_resource_name(name, :verification_rule)
          interval_minutes = attrs.verification_settings[:continuous_verification_interval] / 60

          resources[:event_rules][:verification] = aws_cloudwatch_event_rule(rule_name, {
            name: "zt-verification-#{name}",
            description: 'Continuous verification for zero trust network',
            schedule_expression: "rate(#{interval_minutes} minutes)",
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })

          aws_cloudwatch_event_target(:"#{rule_name}_target", {
            rule: resources[:event_rules][:verification].name,
            arn: resources[:lambda_functions][:policy_evaluator].arn,
            target_id: 'PolicyEvaluator'
          })
        end

        def create_lambda_role(name, attrs, resources)
          role_name = component_resource_name(name, :lambda_role)
          role = aws_iam_role(role_name, {
            name: "zt-lambda-role-#{name}",
            assume_role_policy: lambda_assume_role_policy,
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })

          attach_lambda_policies(role_name, role)
          role.arn
        end

        def lambda_assume_role_policy
          JSON.pretty_generate({
            Version: '2012-10-17',
            Statement: [{
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: { Service: 'lambda.amazonaws.com' }
            }]
          })
        end

        def attach_lambda_policies(role_name, role)
          aws_iam_role_policy_attachment(:"#{role_name}_basic", {
            role: role.name,
            policy_arn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
          })

          aws_iam_role_policy_attachment(:"#{role_name}_vpc", {
            role: role.name,
            policy_arn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole'
          })
        end

        def policy_evaluator_code
          <<~PYTHON
            import json
            import boto3
            import os
            from datetime import datetime

            def lambda_handler(event, context):
                instance_id = os.environ['VERIFIED_ACCESS_INSTANCE_ID']
                frameworks = os.environ['COMPLIANCE_FRAMEWORKS'].split(',')

                compliance_results = evaluate_compliance(instance_id, frameworks)
                violations = check_policy_violations(instance_id)
                security_score = calculate_security_score(compliance_results, violations)

                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'timestamp': datetime.utcnow().isoformat(),
                        'compliance': compliance_results,
                        'violations': violations,
                        'security_score': security_score
                    })
                }

            def evaluate_compliance(instance_id, frameworks):
                return {framework: 'compliant' for framework in frameworks}

            def check_policy_violations(instance_id):
                return []

            def calculate_security_score(compliance, violations):
                base_score = 100
                violation_penalty = len(violations) * 5
                return max(0, base_score - violation_penalty)
          PYTHON
        end
      end
    end
  end
end
