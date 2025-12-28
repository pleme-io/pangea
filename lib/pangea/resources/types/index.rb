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

# Core types (must be loaded first)
require_relative 'core'

# AWS types
require_relative 'aws/core'
require_relative 'aws/compute'
require_relative 'aws/networking'
require_relative 'aws/storage'
require_relative 'aws/database'
require_relative 'aws/security'
require_relative 'aws/monitoring'
require_relative 'aws/load_balancer'
require_relative 'aws/iot'
require_relative 'aws/iot_analytics'

# Cloudflare types
require_relative 'cloudflare/core'
require_relative 'cloudflare/workers'
require_relative 'cloudflare/security'
require_relative 'cloudflare/load_balancing'

# Hetzner types
require_relative 'hetzner/core'
