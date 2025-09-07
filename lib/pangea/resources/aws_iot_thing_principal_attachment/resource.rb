# frozen_string_literal: true

require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Thing Principal Attachment Resource
    # 
    # Attaches X.509 certificates or other principals to IoT things, enabling secure device
    # authentication and authorization. This is a crucial component of the IoT security model,
    # allowing devices to authenticate using certificates and access AWS IoT services.
    #
    # @example Attach certificate to thing
    #   aws_iot_thing_principal_attachment(:device_cert, {
    #     thing_name: "sensor-001",
    #     principal: "arn:aws:iot:us-east-1:123456789012:cert/abcd1234"
    #   })
    #
    # @example Using certificate reference
    #   cert = aws_iot_certificate(:device_certificate, {
    #     active: true
    #   })
    #   
    #   thing = aws_iot_thing(:temperature_sensor, {
    #     thing_name: "temp-sensor-01"
    #   })
    #   
    #   aws_iot_thing_principal_attachment(:secure_attachment, {
    #     thing_name: thing.thing_name,
    #     principal: cert.arn
    #   })
    #
    # @example Multiple principals per thing
    #   # Primary certificate
    #   aws_iot_thing_principal_attachment(:primary_cert, {
    #     thing_name: "multi-auth-device",
    #     principal: "arn:aws:iot:us-east-1:123456789012:cert/primary-cert-id"
    #   })
    #   
    #   # Backup certificate
    #   aws_iot_thing_principal_attachment(:backup_cert, {
    #     thing_name: "multi-auth-device", 
    #     principal: "arn:aws:iot:us-east-1:123456789012:cert/backup-cert-id"
    #   })
    module AwsIotThingPrincipalAttachment
      include AwsIotThingPrincipalAttachmentTypes

      # Creates an AWS IoT thing principal attachment
      #
      # @param name [Symbol] Logical name for the attachment resource
      # @param attributes [Hash] Attachment configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_thing_principal_attachment(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_thing_principal_attachment, name do
          principal validated_attributes.principal
          thing_name validated_attributes.thing_name
        end

        Reference.new(
          type: :aws_iot_thing_principal_attachment,
          name: name,
          attributes: Outputs.new(
            id: "${aws_iot_thing_principal_attachment.#{name}.id}",
            principal: "${aws_iot_thing_principal_attachment.#{name}.principal}",
            thing_name: "${aws_iot_thing_principal_attachment.#{name}.thing_name}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)