# Simple Pangea template example

template :simple_s3 do
  provider :aws do
    region "us-east-1"
  end
  
  resource :aws_s3_bucket, :example do
    bucket "my-simple-bucket-${random_id.bucket_suffix.hex}"
    
    tags do
      Name "Simple Example Bucket"
      ManagedBy "Pangea"
    end
  end
  
  resource :random_id, :bucket_suffix do
    byte_length 8
  end
  
  output :bucket_name do
    value ref(:aws_s3_bucket, :example, :bucket)
    description "Name of the created S3 bucket"
  end
end