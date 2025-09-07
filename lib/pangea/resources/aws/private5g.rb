# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # AWS Private 5G resources for private cellular network deployment
      module Private5G
        include Base

        # Network infrastructure management
        def aws_private5g_network(name, attributes = {})
          create_resource(:aws_private5g_network, name, attributes) do |attrs|
            Reference.new(:aws_private5g_network, name, {
              arn: computed_attr("${aws_private5g_network.#{name}.arn}"),
              id: computed_attr("${aws_private5g_network.#{name}.id}"),
              network_name: attrs[:network_name],
              description: attrs[:description],
              status: computed_attr("${aws_private5g_network.#{name}.status}"),
              status_reason: computed_attr("${aws_private5g_network.#{name}.status_reason}"),
              created_at: computed_attr("${aws_private5g_network.#{name}.created_at}")
            })
          end
        end

        def aws_private5g_network_site(name, attributes = {})
          create_resource(:aws_private5g_network_site, name, attributes) do |attrs|
            Reference.new(:aws_private5g_network_site, name, {
              arn: computed_attr("${aws_private5g_network_site.#{name}.arn}"),
              id: computed_attr("${aws_private5g_network_site.#{name}.id}"),
              network_arn: attrs[:network_arn],
              network_site_name: attrs[:network_site_name],
              description: attrs[:description],
              status: computed_attr("${aws_private5g_network_site.#{name}.status}"),
              status_reason: computed_attr("${aws_private5g_network_site.#{name}.status_reason}"),
              availability_zone: attrs[:availability_zone],
              availability_zone_id: attrs[:availability_zone_id]
            })
          end
        end

        # Device and resource management
        def aws_private5g_device_identifier(name, attributes = {})
          create_resource(:aws_private5g_device_identifier, name, attributes) do |attrs|
            Reference.new(:aws_private5g_device_identifier, name, {
              arn: computed_attr("${aws_private5g_device_identifier.#{name}.arn}"),
              device_identifier_arn: computed_attr("${aws_private5g_device_identifier.#{name}.device_identifier_arn}"),
              imsi: attrs[:imsi],
              iccid: attrs[:iccid],
              network_arn: attrs[:network_arn],
              order_arn: attrs[:order_arn],
              status: computed_attr("${aws_private5g_device_identifier.#{name}.status}"),
              traffic_group_arn: attrs[:traffic_group_arn]
            })
          end
        end

        def aws_private5g_device_identifier_tags(name, attributes = {})
          create_resource(:aws_private5g_device_identifier_tags, name, attributes) do |attrs|
            Reference.new(:aws_private5g_device_identifier_tags, name, {
              device_identifier_arn: attrs[:device_identifier_arn],
              tags: attrs[:tags]
            })
          end
        end

        def aws_private5g_network_resource(name, attributes = {})
          create_resource(:aws_private5g_network_resource, name, attributes) do |attrs|
            Reference.new(:aws_private5g_network_resource, name, {
              arn: computed_attr("${aws_private5g_network_resource.#{name}.arn}"),
              network_resource_arn: computed_attr("${aws_private5g_network_resource.#{name}.network_resource_arn}"),
              network_arn: attrs[:network_arn],
              model: attrs[:model],
              position: attrs[:position],
              status: computed_attr("${aws_private5g_network_resource.#{name}.status}"),
              status_reason: computed_attr("${aws_private5g_network_resource.#{name}.status_reason}"),
              type: attrs[:type],
              vendor: attrs[:vendor]
            })
          end
        end

        # Order management
        def aws_private5g_order(name, attributes = {})
          create_resource(:aws_private5g_order, name, attributes) do |attrs|
            Reference.new(:aws_private5g_order, name, {
              arn: computed_attr("${aws_private5g_order.#{name}.arn}"),
              order_arn: computed_attr("${aws_private5g_order.#{name}.order_arn}"),
              network_arn: attrs[:network_arn],
              network_site_arn: attrs[:network_site_arn],
              acknowledgment_status: computed_attr("${aws_private5g_order.#{name}.acknowledgment_status}"),
              status: computed_attr("${aws_private5g_order.#{name}.status}"),
              tracking_information: computed_attr("${aws_private5g_order.#{name}.tracking_information}")
            })
          end
        end

        # Network monitoring and analysis
        def aws_private5g_network_analyzer(name, attributes = {})
          create_resource(:aws_private5g_network_analyzer, name, attributes) do |attrs|
            Reference.new(:aws_private5g_network_analyzer, name, {
              arn: computed_attr("${aws_private5g_network_analyzer.#{name}.arn}"),
              id: computed_attr("${aws_private5g_network_analyzer.#{name}.id}"),
              name: attrs[:name],
              description: attrs[:description],
              source_arn: attrs[:source_arn],
              status: computed_attr("${aws_private5g_network_analyzer.#{name}.status}"),
              status_reason: computed_attr("${aws_private5g_network_analyzer.#{name}.status_reason}"),
              trace_content: attrs[:trace_content]
            })
          end
        end
      end
    end
  end
end