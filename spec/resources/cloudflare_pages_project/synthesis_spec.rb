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
require 'pangea/resources/cloudflare_pages_project/resource'
require 'pangea/resources/cloudflare_pages_project/types'

RSpec.describe 'cloudflare_pages_project synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'basic projects' do
    it 'synthesizes minimal project' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:basic, {
          account_id: "a" * 32,
          name: "my-site"
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:basic]

      expect(project[:account_id]).to eq(account_id)
      expect(project[:name]).to eq("my-site")
    end

    it 'synthesizes project with production branch' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_branch, {
          account_id: "a" * 32,
          name: "my-site",
          production_branch: "main"
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_branch]

      expect(project[:production_branch]).to eq("main")
    end
  end

  describe 'build configuration' do
    it 'synthesizes with build configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_build, {
          account_id: "a" * 32,
          name: "static-site",
          production_branch: "main",
          build_config: {
            build_command: "npm run build",
            destination_dir: "dist",
            root_dir: "/"
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_build]

      expect(project[:build_config][:build_command]).to eq("npm run build")
      expect(project[:build_config][:destination_dir]).to eq("dist")
      expect(project[:build_config][:root_dir]).to eq("/")
    end

    it 'synthesizes with build caching' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_caching, {
          account_id: "a" * 32,
          name: "cached-site",
          build_config: {
            build_command: "npm run build",
            destination_dir: "build",
            build_caching: true
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_caching]

      expect(project[:build_config][:build_caching]).to be true
    end

    it 'synthesizes with Web Analytics' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_analytics, {
          account_id: "a" * 32,
          name: "analytics-site",
          build_config: {
            build_command: "npm run build",
            destination_dir: "public",
            web_analytics_tag: "abc123",
            web_analytics_token: "token456"
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_analytics]

      expect(project[:build_config][:web_analytics_tag]).to eq("abc123")
      expect(project[:build_config][:web_analytics_token]).to eq("token456")
    end
  end

  describe 'GitHub source integration' do
    it 'synthesizes with GitHub source' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:github_project, {
          account_id: "a" * 32,
          name: "github-site",
          production_branch: "main",
          source: {
            type: "github",
            config: {
              owner: "myorg",
              repo_name: "myrepo",
              production_branch: "main",
              deployments_enabled: true
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:github_project]

      expect(project[:source][:type]).to eq("github")
      expect(project[:source][:config][:owner]).to eq("myorg")
      expect(project[:source][:config][:repo_name]).to eq("myrepo")
      expect(project[:source][:config][:deployments_enabled]).to be true
    end

    it 'synthesizes with PR comments enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:pr_comments, {
          account_id: "a" * 32,
          name: "pr-site",
          source: {
            type: "github",
            config: {
              owner: "myorg",
              repo_name: "myrepo",
              pr_comments_enabled: true
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:pr_comments]

      expect(project[:source][:config][:pr_comments_enabled]).to be true
    end

    it 'synthesizes with preview deployment settings' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:preview_deploys, {
          account_id: "a" * 32,
          name: "preview-site",
          source: {
            type: "github",
            config: {
              owner: "myorg",
              repo_name: "myrepo",
              preview_deployment_setting: "custom",
              preview_branch_includes: ["dev", "staging"],
              preview_branch_excludes: ["experimental"]
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:preview_deploys]

      expect(project[:source][:config][:preview_deployment_setting]).to eq("custom")
      expect(project[:source][:config][:preview_branch_includes]).to eq(["dev", "staging"])
      expect(project[:source][:config][:preview_branch_excludes]).to eq(["experimental"])
    end
  end

  describe 'GitLab source integration' do
    it 'synthesizes with GitLab source' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:gitlab_project, {
          account_id: "a" * 32,
          name: "gitlab-site",
          source: {
            type: "gitlab",
            config: {
              owner: "mygroup",
              repo_name: "myproject",
              production_branch: "main"
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:gitlab_project]

      expect(project[:source][:type]).to eq("gitlab")
    end
  end

  describe 'deployment configurations' do
    it 'synthesizes with production config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:prod_config, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              compatibility_date: "2025-01-01",
              compatibility_flags: ["nodejs_compat"],
              usage_model: "standard"
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:prod_config]

      production = project[:deployment_configs][:production]
      expect(production[:compatibility_date]).to eq("2025-01-01")
      expect(production[:compatibility_flags]).to eq(["nodejs_compat"])
      expect(production[:usage_model]).to eq("standard")
    end

    it 'synthesizes with preview config' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:preview_config, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            preview: {
              compatibility_date: "2025-01-01",
              always_use_latest_compatibility_date: true
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:preview_config]

      preview = project[:deployment_configs][:preview]
      expect(preview[:always_use_latest_compatibility_date]).to be true
    end

    it 'synthesizes with both production and preview configs' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:both_configs, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              compatibility_date: "2025-01-01",
              usage_model: "standard"
            },
            preview: {
              compatibility_date: "2025-01-15",
              usage_model: "standard"
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:both_configs]

      expect(project[:deployment_configs][:production]).to be_a(Hash)
      expect(project[:deployment_configs][:preview]).to be_a(Hash)
    end
  end

  describe 'environment variables' do
    it 'synthesizes with environment variables' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_env_vars, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              env_vars: {
                "API_KEY" => { type: "secret_text", value: "secret123" },
                "API_URL" => { type: "plain_text", value: "https://api.example.com" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_env_vars]

      env_vars = project[:deployment_configs][:production][:env_vars]
      expect(env_vars).to be_an(Array)
      expect(env_vars.length).to eq(2)
    end
  end

  describe 'Workers bindings' do
    it 'synthesizes with KV namespace binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_kv, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              kv_namespaces: {
                "MY_KV" => { namespace_id: "abc123" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_kv]

      kv = project[:deployment_configs][:production][:kv_namespaces]
      expect(kv).to be_an(Array)
    end

    it 'synthesizes with D1 database binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_d1, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              d1_databases: {
                "MY_DB" => { id: "def456" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_d1]

      d1 = project[:deployment_configs][:production][:d1_databases]
      expect(d1).to be_an(Array)
    end

    it 'synthesizes with R2 bucket binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_r2, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              r2_buckets: {
                "MY_BUCKET" => {
                  bucket_name: "my-bucket",
                  jurisdiction: "eu"
                }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_r2]

      r2 = project[:deployment_configs][:production][:r2_buckets]
      expect(r2).to be_an(Array)
    end

    it 'synthesizes with service binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_service, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              services: {
                "MY_SERVICE" => {
                  service: "my-worker",
                  environment: "production"
                }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_service]

      services = project[:deployment_configs][:production][:services]
      expect(services).to be_an(Array)
    end

    it 'synthesizes with Durable Object binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_do, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              durable_object_namespaces: {
                "MY_DO" => { namespace_id: "ghi789" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_do]

      dos = project[:deployment_configs][:production][:durable_object_namespaces]
      expect(dos).to be_an(Array)
    end

    it 'synthesizes with Queue binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_queue, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              queue_producers: {
                "MY_QUEUE" => { name: "my-queue" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_queue]

      queues = project[:deployment_configs][:production][:queue_producers]
      expect(queues).to be_an(Array)
    end

    it 'synthesizes with Hyperdrive binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_hyperdrive, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              hyperdrive_bindings: {
                "MY_HYPERDRIVE" => { id: "jkl012" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_hyperdrive]

      hyperdrive = project[:deployment_configs][:production][:hyperdrive_bindings]
      expect(hyperdrive).to be_an(Array)
    end

    it 'synthesizes with Vectorize binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_vectorize, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              vectorize_bindings: {
                "MY_INDEX" => { index_name: "my-index" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_vectorize]

      vectorize = project[:deployment_configs][:production][:vectorize_bindings]
      expect(vectorize).to be_an(Array)
    end

    it 'synthesizes with AI binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_ai, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              ai_bindings: {
                "AI" => { project_id: "mno345" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_ai]

      ai = project[:deployment_configs][:production][:ai_bindings]
      expect(ai).to be_an(Array)
    end

    it 'synthesizes with Browser binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_browser, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              browsers: {
                "BROWSER" => {}
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_browser]

      browsers = project[:deployment_configs][:production][:browsers]
      expect(browsers).to be_an(Array)
    end

    it 'synthesizes with Analytics Engine binding' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_analytics_engine, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              analytics_engine_datasets: {
                "ANALYTICS" => { dataset: "my-dataset" }
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_analytics_engine]

      analytics = project[:deployment_configs][:production][:analytics_engine_datasets]
      expect(analytics).to be_an(Array)
    end
  end

  describe 'resource limits and placement' do
    it 'synthesizes with CPU limits' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_limits, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              limits: {
                cpu_ms: 50
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_limits]

      limits = project[:deployment_configs][:production][:limits]
      expect(limits[:cpu_ms]).to eq(50)
    end

    it 'synthesizes with placement configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:with_placement, {
          account_id: "a" * 32,
          name: "app",
          deployment_configs: {
            production: {
              placement: {
                mode: "smart"
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      project = result[:resource][:cloudflare_pages_project][:with_placement]

      placement = project[:deployment_configs][:production][:placement]
      expect(placement[:mode]).to eq("smart")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_pages_project(:test, {
          account_id: "a" * 32,
          name: "my-site"
        })
      end

      expect(ref.id).to eq("${cloudflare_pages_project.test.id}")
      expect(ref.outputs[:subdomain]).to eq("${cloudflare_pages_project.test.subdomain}")
      expect(ref.outputs[:domains]).to eq("${cloudflare_pages_project.test.domains}")
    end
  end

  describe 'validation' do
    it 'requires valid compatibility_date format' do
      expect {
        Cloudflare::Types::PagesProjectAttributes.new(
          account_id: account_id,
          name: "test",
          deployment_configs: {
            production: {
              compatibility_date: "invalid-date"
            }
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid source type' do
      expect {
        Cloudflare::Types::PagesProjectAttributes.new(
          account_id: account_id,
          name: "test",
          source: {
            type: "bitbucket",
            config: {
              owner: "test",
              repo_name: "test"
            }
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid usage model' do
      expect {
        Cloudflare::Types::PagesProjectAttributes.new(
          account_id: account_id,
          name: "test",
          deployment_configs: {
            production: {
              usage_model: "invalid"
            }
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects invalid preview_deployment_setting' do
      expect {
        Cloudflare::Types::PagesProjectAttributes.new(
          account_id: account_id,
          name: "test",
          source: {
            type: "github",
            config: {
              owner: "test",
              repo_name: "test",
              preview_deployment_setting: "invalid"
            }
          }
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies projects with source' do
      attrs = Cloudflare::Types::PagesProjectAttributes.new(
        account_id: account_id,
        name: "test",
        source: {
          type: "github",
          config: {
            owner: "test",
            repo_name: "test"
          }
        }
      )

      expect(attrs.has_source?).to be true
      expect(attrs.github_source?).to be true
    end

    it 'identifies projects with build config' do
      attrs = Cloudflare::Types::PagesProjectAttributes.new(
        account_id: account_id,
        name: "test",
        build_config: {
          build_command: "npm run build",
          destination_dir: "dist"
        }
      )

      expect(attrs.has_build_config?).to be true
    end

    it 'identifies projects with deployment configs' do
      attrs = Cloudflare::Types::PagesProjectAttributes.new(
        account_id: account_id,
        name: "test",
        deployment_configs: {
          production: {
            compatibility_date: "2025-01-01"
          }
        }
      )

      expect(attrs.has_deployment_configs?).to be true
    end

    it 'identifies GitLab source' do
      attrs = Cloudflare::Types::PagesProjectAttributes.new(
        account_id: account_id,
        name: "test",
        source: {
          type: "gitlab",
          config: {
            owner: "test",
            repo_name: "test"
          }
        }
      )

      expect(attrs.gitlab_source?).to be true
      expect(attrs.github_source?).to be false
    end
  end
end
