# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class EcsContainerDefinition < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Pangea::Resources::Types::String
          attribute :image, Pangea::Resources::Types::String
          attribute? :cpu, Pangea::Resources::Types::Integer.optional
          attribute? :memory, Pangea::Resources::Types::Integer.optional
          attribute? :memory_reservation, Pangea::Resources::Types::Integer.optional

          attribute :port_mappings, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              container_port: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535),
              host_port?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 65535).optional,
              protocol?: Pangea::Resources::Types::String.constrained(included_in: %w[tcp udp]).optional,
              name?: Pangea::Resources::Types::String.optional,
              app_protocol?: Pangea::Resources::Types::String.constrained(included_in: %w[http http2 grpc]).optional
            )
          ).default([].freeze)

          attribute :environment, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(name: Pangea::Resources::Types::String, value: Pangea::Resources::Types::String)
          ).default([].freeze)

          attribute :secrets, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(name: Pangea::Resources::Types::String, value_from: Pangea::Resources::Types::String)
          ).default([].freeze)

          attribute? :log_configuration, Pangea::Resources::Types::Hash.schema(
            log_driver: Pangea::Resources::Types::String.constrained(included_in: %w[awslogs fluentd gelf json-file journald logentries splunk syslog awsfirelens]),
            options?: Pangea::Resources::Types::Hash.optional,
            secret_options?: Pangea::Resources::Types::Array.of(
              Pangea::Resources::Types::Hash.schema(name: Pangea::Resources::Types::String, value_from: Pangea::Resources::Types::String)
            ).optional
          ).optional

          attribute? :health_check, Pangea::Resources::Types::Hash.schema(
            command: Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String),
            interval?: Pangea::Resources::Types::Integer.constrained(gteq: 5, lteq: 300).optional,
            timeout?: Pangea::Resources::Types::Integer.constrained(gteq: 2, lteq: 60).optional,
            retries?: Pangea::Resources::Types::Integer.constrained(gteq: 1, lteq: 10).optional,
            start_period?: Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 300).optional
          ).optional

          attribute :essential, Pangea::Resources::Types::Bool.default(true)
          attribute :entry_point, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :command, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute? :working_directory, Pangea::Resources::Types::String.optional
          attribute :links, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          attribute :mount_points, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              source_volume: Pangea::Resources::Types::String,
              container_path: Pangea::Resources::Types::String,
              read_only?: Pangea::Resources::Types::Bool.optional
            )
          ).default([].freeze)

          attribute :volumes_from, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(source_container: Pangea::Resources::Types::String, read_only?: Pangea::Resources::Types::Bool.optional)
          ).default([].freeze)

          attribute :depends_on, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              container_name: Pangea::Resources::Types::String,
              condition: Pangea::Resources::Types::String.constrained(included_in: %w[START COMPLETE SUCCESS HEALTHY])
            )
          ).default([].freeze)

          attribute? :linux_parameters, Pangea::Resources::Types::Hash.optional
          attribute :ulimits, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              name: Pangea::Resources::Types::String.constrained(included_in: %w[core cpu data fsize locks memlock msgqueue nice nofile nproc rss rtprio rttime sigpending stack]),
              soft_limit: Pangea::Resources::Types::Integer, hard_limit: Pangea::Resources::Types::Integer
            )
          ).default([].freeze)

          attribute? :user, Pangea::Resources::Types::String.optional
          attribute :privileged, Pangea::Resources::Types::Bool.default(false)
          attribute :readonly_root_filesystem, Pangea::Resources::Types::Bool.default(false)
          attribute :dns_servers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :dns_search_domains, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)

          attribute :extra_hosts, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(hostname: Pangea::Resources::Types::String, ip_address: Pangea::Resources::Types::String)
          ).default([].freeze)

          attribute :docker_security_options, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :docker_labels, Pangea::Resources::Types::Hash.default({}.freeze)

          attribute :system_controls, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(namespace: Pangea::Resources::Types::String, value: Pangea::Resources::Types::String)
          ).default([].freeze)

          attribute? :firelens_configuration, Pangea::Resources::Types::Hash.schema(
            type: Pangea::Resources::Types::String.constrained(included_in: %w[fluentd fluentbit]),
            options?: Pangea::Resources::Types::Hash.optional
          ).optional

          def self.new(attributes = {})
            attrs = super(attributes)
            raise Dry::Struct::Error, 'memory_reservation cannot be greater than memory' if attrs.memory_reservation && attrs.memory && attrs.memory_reservation > attrs.memory
            raise Dry::Struct::Error, 'Invalid image URI format' unless attrs.image.match?(/^[\w\-\.\/\:]+$/)
            attrs
          end

          def using_awslogs? = log_configuration && log_configuration[:log_driver] == 'awslogs'
          def is_essential? = essential
          def estimated_memory_mb = memory || memory_reservation || 512
        end
      end
    end
  end
end
