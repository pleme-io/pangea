# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module EcsServiceBlockBuilders
        # Build Service Connect configuration block
        # @param context [Object] The DSL context for building blocks
        # @param config [Hash] The service_connect_configuration hash
        def self.build_service_connect(context, config)
          context.instance_eval do
            service_connect_configuration do
              enabled config[:enabled]
              namespace config[:namespace] if config[:namespace]

              build_service_connect_services(config[:services]) if config[:services]
              build_service_connect_log_config(config[:log_configuration]) if config[:log_configuration]
            end
          end
        end

        private_class_method def self.build_service_connect_services_block(context, services)
          services.each do |svc|
            context.service do
              port_name svc[:port_name]
              discovery_name svc[:discovery_name] if svc[:discovery_name]
              ingress_port_override svc[:ingress_port_override] if svc[:ingress_port_override]

              build_client_aliases(svc[:client_aliases]) if svc[:client_aliases]
              build_timeout_config(svc[:timeout]) if svc[:timeout]
              build_tls_config(svc[:tls]) if svc[:tls]
            end
          end
        end
      end

      # DSL methods mixed into the service block context
      module EcsServiceConnectDsl
        def build_service_connect_services(services)
          services.each do |svc|
            service do
              port_name svc[:port_name]
              discovery_name svc[:discovery_name] if svc[:discovery_name]
              ingress_port_override svc[:ingress_port_override] if svc[:ingress_port_override]

              build_client_aliases(svc[:client_aliases]) if svc[:client_aliases]
              build_timeout_config(svc[:timeout]) if svc[:timeout]
              build_tls_config(svc[:tls]) if svc[:tls]
            end
          end
        end

        def build_client_aliases(aliases)
          aliases.each do |alias_config|
            client_alias do
              port alias_config[:port]
              dns_name alias_config[:dns_name] if alias_config[:dns_name]
            end
          end
        end

        def build_timeout_config(timeout_config)
          timeout do
            idle_timeout_seconds timeout_config[:idle_timeout_seconds] if timeout_config[:idle_timeout_seconds]
            per_request_timeout_seconds timeout_config[:per_request_timeout_seconds] if timeout_config[:per_request_timeout_seconds]
          end
        end

        def build_tls_config(tls_config)
          tls do
            issuer_certificate_authority do
              aws_pca_authority_arn tls_config[:issuer_certificate_authority][:aws_pca_authority_arn]
            end
            kms_key tls_config[:kms_key] if tls_config[:kms_key]
            role_arn tls_config[:role_arn] if tls_config[:role_arn]
          end
        end

        def build_service_connect_log_config(log_config)
          log_configuration do
            log_driver log_config[:log_driver]
            options log_config[:options] if log_config[:options]

            if log_config[:secret_options]
              log_config[:secret_options].each do |secret|
                secret_option do
                  name secret[:name]
                  value_from secret[:value_from]
                end
              end
            end
          end
        end
      end
    end
  end
end
