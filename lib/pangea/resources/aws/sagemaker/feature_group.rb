# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      module SageMaker
        # AWS SageMaker Feature Group resource
        # This resource manages feature groups in Amazon SageMaker Feature Store.
        # Feature groups store, retrieve, and share machine learning features across
        # teams and models, enabling feature reuse and consistent data transformations.
        #
        # @see https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store.html
        module FeatureGroup
          # Creates an AWS SageMaker Feature Group
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the feature group
          # @option attributes [String] :feature_group_name The name of the feature group (required)
          # @option attributes [String] :record_identifier_feature_name The name of the record identifier feature (required)
          # @option attributes [String] :event_time_feature_name The name of the event time feature (required)
          # @option attributes [Array<Hash>] :feature_definitions The feature definitions (required)
          #   Each feature definition contains:
          #   - :feature_name [String] The name of the feature
          #   - :feature_type [String] The data type of the feature (Integral, Fractional, or String)
          # @option attributes [Hash] :online_store_config Configuration for the online store
          #   - :enable_online_store [Boolean] Whether to enable online store
          #   - :security_config [Hash] Security configuration
          #     - :kms_key_id [String] KMS key for encryption
          # @option attributes [Hash] :offline_store_config Configuration for the offline store
          #   - :s3_storage_config [Hash] S3 storage configuration
          #     - :s3_uri [String] The S3 URI for offline store
          #     - :kms_key_id [String] KMS key for encryption
          #   - :disable_glue_table_creation [Boolean] Whether to disable Glue table creation
          #   - :data_catalog_config [Hash] Data catalog configuration
          #     - :table_name [String] The table name in Glue catalog
          #     - :catalog [String] The catalog name
          #     - :database [String] The database name
          # @option attributes [String] :description A description of the feature group
          # @option attributes [String] :role_arn The IAM role ARN for the feature group (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic feature group for customer data
          #   aws_sagemaker_feature_group(:customer_features, {
          #     feature_group_name: "customer-demographic-features",
          #     record_identifier_feature_name: "customer_id",
          #     event_time_feature_name: "event_time",
          #     role_arn: ref(:aws_iam_role, :sagemaker_feature_store, :arn),
          #     feature_definitions: [
          #       { feature_name: "customer_id", feature_type: "String" },
          #       { feature_name: "age", feature_type: "Integral" },
          #       { feature_name: "income", feature_type: "Fractional" },
          #       { feature_name: "location", feature_type: "String" },
          #       { feature_name: "event_time", feature_type: "Fractional" }
          #     ]
          #   })
          #
          # @example Advanced feature group with both online and offline stores
          #   aws_sagemaker_feature_group(:transaction_features, {
          #     feature_group_name: "transaction-behavioral-features",
          #     record_identifier_feature_name: "transaction_id",
          #     event_time_feature_name: "transaction_time",
          #     role_arn: ref(:aws_iam_role, :ml_feature_store, :arn),
          #     description: "Real-time transaction features for fraud detection",
          #     feature_definitions: [
          #       { feature_name: "transaction_id", feature_type: "String" },
          #       { feature_name: "amount", feature_type: "Fractional" },
          #       { feature_name: "merchant_category", feature_type: "String" },
          #       { feature_name: "is_weekend", feature_type: "Integral" },
          #       { feature_name: "hour_of_day", feature_type: "Integral" },
          #       { feature_name: "days_since_last_transaction", feature_type: "Integral" },
          #       { feature_name: "avg_transaction_last_30d", feature_type: "Fractional" },
          #       { feature_name: "transaction_time", feature_type: "Fractional" }
          #     ],
          #     online_store_config: {
          #       enable_online_store: true,
          #       security_config: {
          #         kms_key_id: ref(:aws_kms_key, :feature_store_encryption, :arn)
          #       }
          #     },
          #     offline_store_config: {
          #       s3_storage_config: {
          #         s3_uri: "s3://ml-feature-store/transaction-features/",
          #         kms_key_id: ref(:aws_kms_key, :feature_store_encryption, :arn)
          #       },
          #       disable_glue_table_creation: false,
          #       data_catalog_config: {
          #         table_name: "transaction_features",
          #         catalog: "AwsDataCatalog",
          #         database: "ml_features"
          #       }
          #     },
          #     tags: {
          #       UseCase: "FraudDetection",
          #       DataSource: "TransactionStream",
          #       Team: "MLEngineering",
          #       Environment: "production"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created feature group
          def aws_sagemaker_feature_group(name, attributes = {})
            resource = resource(:aws_sagemaker_feature_group, name) do
              feature_group_name attributes[:feature_group_name] if attributes[:feature_group_name]
              record_identifier_feature_name attributes[:record_identifier_feature_name] if attributes[:record_identifier_feature_name]
              event_time_feature_name attributes[:event_time_feature_name] if attributes[:event_time_feature_name]
              feature_definitions attributes[:feature_definitions] if attributes[:feature_definitions]
              online_store_config attributes[:online_store_config] if attributes[:online_store_config]
              offline_store_config attributes[:offline_store_config] if attributes[:offline_store_config]
              description attributes[:description] if attributes[:description]
              role_arn attributes[:role_arn] if attributes[:role_arn]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_sagemaker_feature_group',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_sagemaker_feature_group.#{name}.id}",
                arn: "${aws_sagemaker_feature_group.#{name}.arn}",
                feature_group_name: "${aws_sagemaker_feature_group.#{name}.feature_group_name}",
                feature_group_status: "${aws_sagemaker_feature_group.#{name}.feature_group_status}",
                creation_time: "${aws_sagemaker_feature_group.#{name}.creation_time}",
                offline_store_status: "${aws_sagemaker_feature_group.#{name}.offline_store_status}"
              }
            )
          end
        end
      end
    end
  end
end