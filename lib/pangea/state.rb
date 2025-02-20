require %(aws-sdk-s3)

# manage state
# class State
# end

# manage local state
class LocalState < State
end

# manage s3 state
class S3State < State
  REGION = %(us-east-1).freeze

  def initialize(bucket:, key: %())
    @bucket = bucket
    @key    = key
  end

  # provision the s3 state setup in s3
  def provision
    create_bucket
  end

  def create_bucket
    s3 = Aws::S3::Client.new(region: REGION)

    begin
      s3.create_bucket(bucket: @bucket)
      puts "Bucket '#{@bucket}' created successfully!"
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
      puts "Bucket '#{@bucket}' already exists and is owned by you."
    rescue Aws::S3::Errors::ServiceError => e
      puts "Failed to create bucket: #{e.message}"
    end
  end
end

def test
  state = S3State.new(bucket: %(cbj-state-test))
  state.provision
end
