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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # CodeArtifact Repository resource attributes with validation
        class CodeArtifactRepositoryAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :repository, Resources::Types::String
          attribute :domain, Resources::Types::String
          attribute :format, Resources::Types::String.enum('npm', 'pypi', 'maven', 'nuget')
          
          # Optional attributes
          attribute :domain_owner, Resources::Types::String.optional.default(nil)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :upstream, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              repository_name: Resources::Types::String
            )
          ).default([].freeze)
          attribute :external_connections, Resources::Types::Hash.schema(
            external_connection_name?: Resources::Types::String.optional
          ).optional.default(nil)
          attribute :tags, Resources::Types::AwsTags
          
          # Validate attributes
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate repository name
            if attrs[:repository]
              repo = attrs[:repository]
              unless repo.match?(/^[a-zA-Z0-9][a-zA-Z0-9._\-]{1,98}[a-zA-Z0-9]$/)
                raise Dry::Struct::Error, "repository must be 2-100 characters, start and end with alphanumeric, contain only letters, numbers, dots, hyphens, underscores"
              end
              
              if repo.length < 2 || repo.length > 100
                raise Dry::Struct::Error, "repository must be between 2 and 100 characters"
              end
            end
            
            # Validate domain name (allow terraform references)
            if attrs[:domain] && !attrs[:domain].match?(/^\$\{/)
              domain = attrs[:domain]
              unless domain.match?(/^[a-z][a-z0-9\-]{1,48}[a-z0-9]$/)
                raise Dry::Struct::Error, "domain must be 2-50 characters, start with letter, end with letter or number, contain only lowercase letters, numbers, and hyphens"
              end
            end
            
            # Validate domain_owner if provided
            if attrs[:domain_owner] && !attrs[:domain_owner].empty?
              owner = attrs[:domain_owner]
              unless owner.match?(/^\d{12}$/) || owner.match?(/^\$\{/)
                raise Dry::Struct::Error, "domain_owner must be a 12-digit AWS account ID or terraform reference"
              end
            end
            
            # Validate external connections based on format
            if attrs[:external_connections] && attrs[:format]
              format = attrs[:format]
              ext_conn = attrs[:external_connections][:external_connection_name]
              
              if ext_conn
                valid_connections = {
                  'npm' => 'public:npmjs',
                  'pypi' => 'public:pypi',
                  'maven' => 'public:maven-central',
                  'nuget' => 'public:nuget-org'
                }
                
                unless ext_conn == valid_connections[format]
                  raise Dry::Struct::Error, "external_connection_name for #{format} must be '#{valid_connections[format]}'"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def repository_endpoint_template(region = 'us-east-1')
            case format
            when 'npm'
              "https://#{domain}-#{domain_owner || '${data.aws_caller_identity.current.account_id}'}.d.codeartifact.#{region}.amazonaws.com/npm/#{repository}/"
            when 'pypi'
              "https://#{domain}-#{domain_owner || '${data.aws_caller_identity.current.account_id}'}.d.codeartifact.#{region}.amazonaws.com/pypi/#{repository}/simple/"
            when 'maven'
              "https://#{domain}-#{domain_owner || '${data.aws_caller_identity.current.account_id}'}.d.codeartifact.#{region}.amazonaws.com/maven/#{repository}/"
            when 'nuget'
              "https://#{domain}-#{domain_owner || '${data.aws_caller_identity.current.account_id}'}.d.codeartifact.#{region}.amazonaws.com/nuget/#{repository}/"
            else
              "https://#{domain}-#{domain_owner || '${data.aws_caller_identity.current.account_id}'}.d.codeartifact.#{region}.amazonaws.com/#{format}/#{repository}/"
            end
          end
          
          def has_upstream_repositories?
            upstream.any?
          end
          
          def upstream_count
            upstream.size
          end
          
          def has_external_connection?
            external_connections && external_connections[:external_connection_name] && !external_connections[:external_connection_name].empty?
          end
          
          def external_connection_type
            return nil unless has_external_connection?
            
            conn = external_connections[:external_connection_name]
            case conn
            when 'public:npmjs' then :npm_public
            when 'public:pypi' then :pypi_public  
            when 'public:maven-central' then :maven_central
            when 'public:nuget-org' then :nuget_public
            else :unknown
            end
          end
          
          def supports_external_connection?
            %w[npm pypi maven nuget].include?(format)
          end
          
          def is_private_repository?
            !has_external_connection?
          end
          
          def is_public_proxy_repository?
            has_external_connection?
          end
          
          def package_manager_config_command(region = 'us-east-1')
            case format
            when 'npm'
              "aws codeartifact login --tool npm --domain #{domain} --repository #{repository} --region #{region}"
            when 'pypi'
              "aws codeartifact login --tool pip --domain #{domain} --repository #{repository} --region #{region}"
            when 'maven'
              "aws codeartifact login --tool mvn --domain #{domain} --repository #{repository} --region #{region}"
            when 'nuget'
              "aws codeartifact login --tool nuget --domain #{domain} --repository #{repository} --region #{region}"
            end
          end
          
          def estimated_monthly_cost_per_gb
            # Rough estimates per GB stored
            case format
            when 'npm' then 0.05
            when 'pypi' then 0.05
            when 'maven' then 0.05
            when 'nuget' then 0.05
            else 0.05
            end
          end
          
          def to_h
            hash = {
              repository: repository,
              domain: domain,
              format: format,
              tags: tags
            }
            
            hash[:domain_owner] = domain_owner if domain_owner
            hash[:description] = description if description
            hash[:upstream] = upstream if upstream.any?
            hash[:external_connections] = external_connections if external_connections
            
            hash.compact
          end
        end
      end
    end
  end
end