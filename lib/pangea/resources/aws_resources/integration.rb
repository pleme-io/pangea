# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Integration resources - API Gateway, SQS, SNS, EventBridge, Step Functions
require 'pangea/resources/aws_api_gateway_rest_api/resource'
require 'pangea/resources/aws_api_gateway_resource/resource'
require 'pangea/resources/aws_api_gateway_method/resource'
require 'pangea/resources/aws_api_gateway_deployment/resource'
require 'pangea/resources/aws_api_gateway_stage/resource'
require 'pangea/resources/aws_sqs_queue/resource'
require 'pangea/resources/aws_sqs_queue_policy/resource'
require 'pangea/resources/aws_sns_topic/resource'
require 'pangea/resources/aws_sns_subscription/resource'
require 'pangea/resources/aws_eventbridge_bus/resource'
require 'pangea/resources/aws_eventbridge_rule/resource'
require 'pangea/resources/aws_eventbridge_target/resource'
require 'pangea/resources/aws_sfn_state_machine/resource'
require 'pangea/resources/aws_sfn_activity/resource'
require 'pangea/resources/aws_appsync_graphql_api/resource'
require 'pangea/resources/aws_appsync_datasource/resource'
require 'pangea/resources/aws_appsync_resolver/resource'
require 'pangea/resources/aws_mq_broker/resource'
require 'pangea/resources/aws_mq_configuration/resource'
