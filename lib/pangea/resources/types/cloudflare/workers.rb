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

require_relative '../core'

module Pangea
  module Resources
    module Types
      # Cloudflare Worker script format
      CloudflareWorkerScriptFormat = String.enum('service-worker', 'modules')

      # Cloudflare Worker route pattern validation
      CloudflareWorkerRoutePattern = String.constructor { |value|
        unless value.match?(/\A[a-z0-9\-\.\*]+\/.*\z/i)
          raise Dry::Types::ConstraintError, "Worker route pattern must include hostname and path (e.g., 'example.com/*')"
        end
        if value.include?('**')
          raise Dry::Types::ConstraintError, "Worker route pattern cannot contain consecutive asterisks"
        end
        value
      }

      # Cloudflare Spectrum application protocol
      CloudflareSpectrumProtocol = String.enum('tcp/22', 'tcp/80', 'tcp/443', 'tcp/3389', 'tcp/8080', 'udp/53')

      # Cloudflare Spectrum edge IP connectivity
      CloudflareSpectrumEdgeIpConnectivity = String.enum('all', 'ipv4', 'ipv6')

      # Cloudflare Spectrum TLS mode
      CloudflareSpectrumTls = String.enum('off', 'flexible', 'full', 'strict')

      # Cloudflare Custom Hostname SSL method
      CloudflareCustomHostnameSslMethod = String.enum('http', 'txt', 'email')

      # Cloudflare Custom Hostname SSL type
      CloudflareCustomHostnameSslType = String.enum('dv')

      # Cloudflare Custom Hostname SSL settings
      CloudflareCustomHostnameSslSettings = Hash.schema(
        http2?: String.enum('on', 'off').optional,
        http3?: String.enum('on', 'off').optional,
        tls_1_3?: String.enum('on', 'off').optional,
        min_tls_version?: String.enum('1.0', '1.1', '1.2', '1.3').optional,
        ciphers?: Array.of(String).optional
      )
    end
  end
end
