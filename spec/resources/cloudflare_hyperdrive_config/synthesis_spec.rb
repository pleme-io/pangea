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


require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_hyperdrive_config/resource'
require 'pangea/resources/cloudflare_hyperdrive_config/types'

RSpec.describe 'cloudflare_hyperdrive_config synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'basic configurations' do
    it 'synthesizes minimal PostgreSQL config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:postgres, {
          account_id: "a" * 32,
          name: "my-postgres",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:postgres]

      expect(config[:account_id]).to eq(account_id)
      expect(config[:name]).to eq("my-postgres")
      expect(config[:origin][:database]).to eq("mydb")
      expect(config[:origin][:host]).to eq("db.example.com")
      expect(config[:origin][:scheme]).to eq("postgres")
    end

    it 'synthesizes MySQL config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:mysql, {
          account_id: "a" * 32,
          name: "my-mysql",
          origin: {
            database: "mydb",
            host: "mysql.example.com",
            user: "root",
            password: "secret",
            scheme: "mysql",
            port: 3306
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:mysql]

      expect(config[:origin][:scheme]).to eq("mysql")
      expect(config[:origin][:port]).to eq(3306)
    end

    it 'synthesizes with custom port' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:custom_port, {
          account_id: "a" * 32,
          name: "custom",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres",
            port: 15432
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:custom_port]

      expect(config[:origin][:port]).to eq(15432)
    end
  end

  describe 'database schemes' do
    it 'accepts postgres scheme' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:postgres_scheme, {
          account_id: "a" * 32,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "postgres"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:postgres_scheme]

      expect(config[:origin][:scheme]).to eq("postgres")
    end

    it 'accepts postgresql scheme' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:postgresql_scheme, {
          account_id: "a" * 32,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "postgresql"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:postgresql_scheme]

      expect(config[:origin][:scheme]).to eq("postgresql")
    end

    it 'accepts mysql scheme' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:mysql_scheme, {
          account_id: "a" * 32,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "mysql"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:mysql_scheme]

      expect(config[:origin][:scheme]).to eq("mysql")
    end
  end

  describe 'caching configuration' do
    it 'synthesizes with caching enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:with_caching, {
          account_id: "a" * 32,
          name: "cached",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          caching: {
            max_age: 120,
            stale_while_revalidate: 30
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:with_caching]

      expect(config[:caching][:max_age]).to eq(120)
      expect(config[:caching][:stale_while_revalidate]).to eq(30)
    end

    it 'synthesizes with caching disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:no_cache, {
          account_id: "a" * 32,
          name: "no-cache",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          caching: {
            disabled: true
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:no_cache]

      expect(config[:caching][:disabled]).to be true
    end

    it 'synthesizes with default max_age' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:default_cache, {
          account_id: "a" * 32,
          name: "default",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          caching: {
            max_age: 60
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:default_cache]

      expect(config[:caching][:max_age]).to eq(60)
    end
  end

  describe 'Cloudflare Access integration' do
    it 'synthesizes with Access for private database' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:private_db, {
          account_id: "a" * 32,
          name: "private",
          origin: {
            database: "mydb",
            host: "internal-db.corp.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres",
            access_client_id: "abc123",
            access_client_secret: "def456"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:private_db]

      expect(config[:origin][:access_client_id]).to eq("abc123")
      expect(config[:origin][:access_client_secret]).to eq("def456")
    end
  end

  describe 'mTLS configuration' do
    it 'synthesizes with mTLS' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:with_mtls, {
          account_id: "a" * 32,
          name: "secure",
          origin: {
            database: "mydb",
            host: "secure-db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          mtls: {
            ca_certificate_id: "ca-cert-123",
            mtls_certificate_id: "client-cert-456",
            sslmode: "verify-full"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:with_mtls]

      expect(config[:mtls][:ca_certificate_id]).to eq("ca-cert-123")
      expect(config[:mtls][:mtls_certificate_id]).to eq("client-cert-456")
      expect(config[:mtls][:sslmode]).to eq("verify-full")
    end

    it 'synthesizes with verify-ca mode' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:verify_ca, {
          account_id: "a" * 32,
          name: "verify-ca",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          mtls: {
            ca_certificate_id: "ca-cert-123",
            sslmode: "verify-ca"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:verify_ca]

      expect(config[:mtls][:sslmode]).to eq("verify-ca")
    end

    it 'synthesizes with require mode' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:require_ssl, {
          account_id: "a" * 32,
          name: "require",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          mtls: {
            sslmode: "require"
          }
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:require_ssl]

      expect(config[:mtls][:sslmode]).to eq("require")
    end
  end

  describe 'connection limits' do
    it 'synthesizes with origin connection limit' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:with_limit, {
          account_id: "a" * 32,
          name: "limited",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          },
          origin_connection_limit: 50
        })
      end

      result = synthesizer.synthesis
      config = result[:resource][:cloudflare_hyperdrive_config][:with_limit]

      expect(config[:origin_connection_limit]).to eq(50)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_hyperdrive_config(:test, {
          account_id: "a" * 32,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "postgres",
            password: "secret",
            scheme: "postgres"
          }
        })
      end

      expect(ref.id).to eq("${cloudflare_hyperdrive_config.test.id}")
    end
  end

  describe 'validation' do
    it 'rejects invalid scheme' do
      expect {
        Cloudflare::Types::HyperdriveConfigAttributes.new(
          account_id: account_id,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "mongodb"
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid port' do
      expect {
        Cloudflare::Types::HyperdriveConfigAttributes.new(
          account_id: account_id,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "postgres",
            port: 99999
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid sslmode' do
      expect {
        Cloudflare::Types::HyperdriveConfigAttributes.new(
          account_id: account_id,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "postgres"
          },
          mtls: {
            sslmode: "invalid"
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'requires positive max_age' do
      expect {
        Cloudflare::Types::HyperdriveConfigAttributes.new(
          account_id: account_id,
          name: "test",
          origin: {
            database: "mydb",
            host: "db.example.com",
            user: "user",
            password: "pass",
            scheme: "postgres"
          },
          caching: {
            max_age: -1
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies PostgreSQL databases' do
      origin = Cloudflare::Types::HyperdriveOrigin.new(
        database: "mydb",
        host: "db.example.com",
        user: "postgres",
        password: "secret",
        scheme: "postgres"
      )

      expect(origin.postgres?).to be true
      expect(origin.mysql?).to be false
    end

    it 'identifies MySQL databases' do
      origin = Cloudflare::Types::HyperdriveOrigin.new(
        database: "mydb",
        host: "db.example.com",
        user: "root",
        password: "secret",
        scheme: "mysql"
      )

      expect(origin.mysql?).to be true
      expect(origin.postgres?).to be false
    end

    it 'detects Access configuration' do
      origin = Cloudflare::Types::HyperdriveOrigin.new(
        database: "mydb",
        host: "internal-db.example.com",
        user: "postgres",
        password: "secret",
        scheme: "postgres",
        access_client_id: "abc123",
        access_client_secret: "def456"
      )

      expect(origin.access_configured?).to be true
    end

    it 'provides default port' do
      postgres_origin = Cloudflare::Types::HyperdriveOrigin.new(
        database: "mydb",
        host: "db.example.com",
        user: "postgres",
        password: "secret",
        scheme: "postgres"
      )

      mysql_origin = Cloudflare::Types::HyperdriveOrigin.new(
        database: "mydb",
        host: "db.example.com",
        user: "root",
        password: "secret",
        scheme: "mysql"
      )

      expect(postgres_origin.default_port).to eq(5432)
      expect(mysql_origin.default_port).to eq(3306)
    end

    it 'identifies enabled caching' do
      caching = Cloudflare::Types::HyperdriveCaching.new(
        max_age: 120
      )

      expect(caching.enabled?).to be true
    end

    it 'identifies disabled caching' do
      caching = Cloudflare::Types::HyperdriveCaching.new(
        disabled: true
      )

      expect(caching.enabled?).to be false
    end

    it 'identifies full verification mode' do
      mtls = Cloudflare::Types::HyperdriveMtls.new(
        sslmode: "verify-full"
      )

      expect(mtls.full_verification?).to be true
    end

    it 'identifies CA configuration' do
      mtls = Cloudflare::Types::HyperdriveMtls.new(
        ca_certificate_id: "ca-cert-123"
      )

      expect(mtls.ca_configured?).to be true
    end

    it 'detects private database configuration' do
      attrs = Cloudflare::Types::HyperdriveConfigAttributes.new(
        account_id: account_id,
        name: "test",
        origin: {
          database: "mydb",
          host: "internal-db.example.com",
          user: "postgres",
          password: "secret",
          scheme: "postgres",
          access_client_id: "abc123",
          access_client_secret: "def456"
        }
      )

      expect(attrs.private_database?).to be true
    end

    it 'detects caching configuration' do
      attrs = Cloudflare::Types::HyperdriveConfigAttributes.new(
        account_id: account_id,
        name: "test",
        origin: {
          database: "mydb",
          host: "db.example.com",
          user: "postgres",
          password: "secret",
          scheme: "postgres"
        },
        caching: {
          max_age: 120
        }
      )

      expect(attrs.has_caching?).to be true
    end

    it 'detects mTLS configuration' do
      attrs = Cloudflare::Types::HyperdriveConfigAttributes.new(
        account_id: account_id,
        name: "test",
        origin: {
          database: "mydb",
          host: "db.example.com",
          user: "postgres",
          password: "secret",
          scheme: "postgres"
        },
        mtls: {
          sslmode: "require"
        }
      )

      expect(attrs.has_mtls?).to be true
    end

    it 'detects connection limit' do
      attrs = Cloudflare::Types::HyperdriveConfigAttributes.new(
        account_id: account_id,
        name: "test",
        origin: {
          database: "mydb",
          host: "db.example.com",
          user: "postgres",
          password: "secret",
          scheme: "postgres"
        },
        origin_connection_limit: 50
      )

      expect(attrs.has_connection_limit?).to be true
    end
  end
end
