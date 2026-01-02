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
      # Load balancer types
      LoadBalancerType = String.default('application').enum('application', 'network', 'gateway')
      AlbTargetType = String.enum('instance', 'ip', 'lambda', 'alb')
      HealthCheckProtocol = String.enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
      ListenerProtocol = String.enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
      ListenerPort = Integer.constrained(gteq: 1, lteq: 65535)
      TargetAttachmentType = String.enum('instance', 'ip', 'lambda', 'alb')
      TargetAvailabilityZone = AwsAvailabilityZone.optional

      # SSL policies
      SslPolicy = String.enum(
        'ELBSecurityPolicy-TLS-1-0-2015-04', 'ELBSecurityPolicy-TLS-1-1-2017-01',
        'ELBSecurityPolicy-TLS-1-2-2017-01', 'ELBSecurityPolicy-TLS-1-2-Ext-2018-06',
        'ELBSecurityPolicy-FS-2018-06', 'ELBSecurityPolicy-FS-1-1-2019-08',
        'ELBSecurityPolicy-FS-1-2-2019-08', 'ELBSecurityPolicy-FS-1-2-Res-2019-08',
        'ELBSecurityPolicy-FS-1-2-Res-2020-10', 'ELBSecurityPolicy-2016-08'
      )

      ListenerActionType = String.enum('forward', 'redirect', 'fixed-response', 'authenticate-cognito', 'authenticate-oidc')
      ListenerConditionType = String.enum('host-header', 'path-pattern', 'http-method', 'query-string', 'http-header', 'source-ip')
      HttpMethod = String.enum('GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH')

      ListenerForwardAction = Hash.schema(
        target_groups: Array.of(Hash.schema(
          arn: String,
          weight?: Integer.constrained(gteq: 0, lteq: 999).default(100)
        )).constrained(min_size: 1),
        stickiness?: Hash.schema(enabled: Bool, duration?: Integer.constrained(gteq: 1, lteq: 604800).optional).optional
      )

      ListenerRedirectAction = Hash.schema(
        protocol?: String.enum('HTTP', 'HTTPS', '#{protocol}').optional,
        port?: String.optional,
        host?: String.optional,
        path?: String.optional,
        query?: String.optional,
        status_code: String.enum('HTTP_301', 'HTTP_302')
      )

      ListenerFixedResponseAction = Hash.schema(
        content_type?: String.enum('text/plain', 'text/css', 'text/html', 'application/javascript', 'application/json').optional,
        message_body?: String.optional,
        status_code: String.constrained(format: /\A[1-5][0-9]{2}\z/)
      )

      ListenerAuthenticateCognitoAction = Hash.schema(
        user_pool_arn: String.constrained(format: /\Aarn:aws:cognito-idp:/),
        user_pool_client_id: String,
        user_pool_domain: String,
        authentication_request_extra_params?: Hash.map(String, String).optional,
        on_unauthenticated_request?: String.enum('deny', 'allow', 'authenticate').optional,
        scope?: String.optional,
        session_cookie_name?: String.optional,
        session_timeout?: Integer.constrained(gteq: 1, lteq: 604800).optional
      )

      ListenerAuthenticateOidcAction = Hash.schema(
        authorization_endpoint: String,
        client_id: String,
        client_secret: String,
        issuer: String,
        token_endpoint: String,
        user_info_endpoint: String,
        authentication_request_extra_params?: Hash.map(String, String).optional,
        on_unauthenticated_request?: String.enum('deny', 'allow', 'authenticate').optional,
        scope?: String.optional,
        session_cookie_name?: String.optional,
        session_timeout?: Integer.constrained(gteq: 1, lteq: 604800).optional
      )

      ListenerConditionHostHeader = Hash.schema(values: Array.of(String).constrained(min_size: 1))
      ListenerConditionPathPattern = Hash.schema(values: Array.of(String).constrained(min_size: 1))
      ListenerConditionHttpMethod = Hash.schema(values: Array.of(HttpMethod).constrained(min_size: 1))
      ListenerConditionQueryString = Hash.schema(values: Array.of(Hash.schema(key?: String.optional, value: String)).constrained(min_size: 1))
      ListenerConditionHttpHeader = Hash.schema(http_header_name: String, values: Array.of(String).constrained(min_size: 1))
      ListenerConditionSourceIp = Hash.schema(values: Array.of(CidrBlock).constrained(min_size: 1))
    end
  end
end
