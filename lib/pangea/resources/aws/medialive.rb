# frozen_string_literal: true

require_relative 'medialive/channel'
require_relative 'medialive/input'
require_relative 'medialive/input_security_group'
require_relative 'medialive/multiplex'
require_relative 'medialive/multiplex_program'

module Pangea
  module Resources
    module AWS
      # AWS Elemental MediaLive service module
      # Provides type-safe resource functions for live video processing and streaming
      module MediaLive
        # Creates a MediaLive channel for live video processing
        #
        # @param name [Symbol] Unique name for the channel resource
        # @param attributes [Hash] Configuration attributes for the channel
        # @return [MediaLive::Channel::ChannelReference] Reference to the created channel
        def aws_medialive_channel(name, attributes = {})
          resource = MediaLive::Channel.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaLive::Channel::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaLive input for ingesting live video streams
        #
        # @param name [Symbol] Unique name for the input resource
        # @param attributes [Hash] Configuration attributes for the input
        # @return [MediaLive::Input::InputReference] Reference to the created input
        def aws_medialive_input(name, attributes = {})
          resource = MediaLive::Input.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaLive::Input::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaLive input security group for access control
        #
        # @param name [Symbol] Unique name for the input security group resource
        # @param attributes [Hash] Configuration attributes for the input security group
        # @return [MediaLive::InputSecurityGroup::InputSecurityGroupReference] Reference to the created input security group
        def aws_medialive_input_security_group(name, attributes = {})
          resource = MediaLive::InputSecurityGroup.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaLive::InputSecurityGroup::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaLive multiplex for combining multiple video streams
        #
        # @param name [Symbol] Unique name for the multiplex resource
        # @param attributes [Hash] Configuration attributes for the multiplex
        # @return [MediaLive::Multiplex::MultiplexReference] Reference to the created multiplex
        def aws_medialive_multiplex(name, attributes = {})
          resource = MediaLive::Multiplex.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaLive::Multiplex::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaLive multiplex program for individual stream configuration
        #
        # @param name [Symbol] Unique name for the multiplex program resource
        # @param attributes [Hash] Configuration attributes for the multiplex program
        # @return [MediaLive::MultiplexProgram::MultiplexProgramReference] Reference to the created multiplex program
        def aws_medialive_multiplex_program(name, attributes = {})
          resource = MediaLive::MultiplexProgram.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaLive::MultiplexProgram::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end