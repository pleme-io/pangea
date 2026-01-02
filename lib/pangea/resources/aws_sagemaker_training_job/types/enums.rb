# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        SageMakerTrainingInstanceType = String.enum(
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge', 'ml.m5.48xlarge',
          'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5n.xlarge', 'ml.c5n.2xlarge', 'ml.c5n.4xlarge', 'ml.c5n.9xlarge', 'ml.c5n.18xlarge',
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge', 'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.p3dn.24xlarge', 'ml.p4d.24xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge'
        )
        SageMakerTrainingInputMode = String.enum('File', 'Pipe')
        SageMakerTrainingCompressionType = String.enum('None', 'Gzip')
        SageMakerTrainingContentType = String.enum('text/csv', 'text/libsvm', 'application/x-parquet', 'application/json',
                                                    'application/jsonlines', 'application/x-recordio-protobuf', 'application/x-image', 'application/x-numpy')
      end
    end
  end
end
