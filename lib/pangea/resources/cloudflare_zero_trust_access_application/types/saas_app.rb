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

module Pangea
  module Resources
    module Cloudflare
      module Types
        # SaaS application configuration
        class ZeroTrustAccessSaasApp < Dry::Struct
          transform_keys(&:to_sym)

          attribute :auth_type, Dry::Types['strict.string'].enum('saml', 'oidc').optional.default(nil)
          attribute :client_id, Dry::Types['strict.string'].optional.default(nil)
          attribute :client_secret, Dry::Types['strict.string'].optional.default(nil)
          attribute :redirect_uris, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :grant_types, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :scopes, Dry::Types['strict.array'].of(Dry::Types['strict.string']).optional.default(nil)
          attribute :sp_entity_id, Dry::Types['strict.string'].optional.default(nil)
          attribute :idp_entity_id, Dry::Types['strict.string'].optional.default(nil)
          attribute :sso_endpoint, Dry::Types['strict.string'].optional.default(nil)
          attribute :public_key, Dry::Types['strict.string'].optional.default(nil)
          attribute :name_id_format, Dry::Types['strict.string'].optional.default(nil)
          attribute :name_id_transform_jsonata, Dry::Types['strict.string'].optional.default(nil)
          attribute :access_token_lifetime, Dry::Types['strict.string'].optional.default(nil)
          attribute :default_relay_state, Dry::Types['strict.string'].optional.default(nil)
          attribute :allow_pkce_without_client_secret, Dry::Types['strict.bool'].optional.default(nil)
        end
      end
    end
  end
end
