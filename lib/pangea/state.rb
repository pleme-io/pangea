require 'aws-sdk-s3'
require 'aws-sdk-dynamodb'

module Pangea
  # Base state management class
  class State
    def initialize
      # Initialize common state if needed.
    end
  end

  # Manage local state
  class LocalState < Pangea::State; end

  # Manage S3 state
  class S3State < Pangea::State
    # Creates a DynamoDB table to be used for state locking.
    # Optional parameters allow you to customize the table name, AWS region, and whether to check for existing table.
    def create_dynamodb_table_for_lock(name:, region:, check: true)
      dynamodb = Aws::DynamoDB::Client.new(region: region)

      if check
        begin
          # Check if the table already exists
          dynamodb.describe_table(table_name: name)
          puts "DynamoDB table '#{name}' already exists, skipping creation."
          return
        rescue Aws::DynamoDB::Errors::ResourceNotFoundException
          # Table does not exist; proceed with creation.
        rescue Aws::DynamoDB::Errors::ServiceError => e
          puts "Failed to check DynamoDB table existence: #{e.message}"
          return
        end
      end

      begin
        dynamodb.create_table(
          {
            table_name: name,
            attribute_definitions: [
              {
                attribute_name: 'LockID',
                attribute_type: 'S'
              }
            ],
            key_schema: [
              {
                attribute_name: 'LockID',
                key_type: 'HASH'
              }
            ],
            provisioned_throughput: {
              read_capacity_units: 1,
              write_capacity_units: 1
            }
          }
        )
        puts "DynamoDB table '#{name}' created successfully!"
      rescue Aws::DynamoDB::Errors::ResourceInUseException
        puts "DynamoDB table '#{name}' already exists."
      rescue Aws::DynamoDB::Errors::ServiceError => e
        puts "Failed to create DynamoDB table: #{e.message}"
      end
    end

    # Creates an S3 bucket for state storage.
    # If `check` is true, the method first checks if the bucket exists.
    def create_bucket(name:, region:, check: true)
      s3 = Aws::S3::Client.new(region: region)

      if check
        begin
          # Attempt to check if the bucket exists
          s3.head_bucket(bucket: name)
          # Bucket exists; nothing to do.
          return
        rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchBucket
          # Bucket does not exist; proceed with creation.
        rescue Aws::S3::Errors::Forbidden => e
          # The bucket exists but is inaccessible (perhaps owned by someone else).
          puts "Bucket '#{name}' exists but is not accessible: #{e.message}"
          return
        end
      end

      begin
        s3.create_bucket(bucket: name)
        puts "Bucket '#{name}' created successfully!"
      rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
        puts "Bucket '#{name}' already exists and is owned by you."
      rescue Aws::S3::Errors::ServiceError => e
        puts "Failed to create bucket: #{e.message}"
      end
    end
  end
end
