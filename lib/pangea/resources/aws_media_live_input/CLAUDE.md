# AWS MediaLive Input - Technical Implementation

## Resource Overview

The `aws_media_live_input` resource provides comprehensive support for AWS MediaLive inputs, enabling ingestion of live video content from diverse sources with enterprise-grade reliability and security features.

## Architecture Integration Patterns

### Multi-Source Live Streaming Platform

```ruby
template :multi_source_streaming do
  # Primary RTMP input from studio
  studio_input = aws_media_live_input(:studio_rtmp, {
    name: "studio-primary-rtmp",
    type: "RTMP_PUSH",
    input_class: "STANDARD",
    destinations: [
      {
        stream_name: "studio-primary",
        url: "rtmp://primary-us-east-1.medialive.amazonaws.com:1935/live"
      },
      {
        stream_name: "studio-backup", 
        url: "rtmp://backup-us-east-1.medialive.amazonaws.com:1935/live"
      }
    ],
    input_security_groups: ["sg-studio-inputs"],
    tags: {
      Source: "studio",
      Priority: "primary",
      Location: "headquarters"
    }
  })

  # Remote contribution via MediaConnect
  remote_input = aws_media_live_input(:remote_contribution, {
    name: "remote-mediaconnect-input",
    type: "MEDIACONNECT",
    media_connect_flows: [
      {
        flow_arn: aws_media_connect_flow(:remote_flow, {
          name: "remote-contribution-flow",
          # MediaConnect flow configuration
        }).arn
      }
    ],
    role_arn: aws_iam_role(:medialive_mediaconnect_role, {
      name: "MediaLiveMediaConnectRole",
      assume_role_policy: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: { Service: "medialive.amazonaws.com" },
            Action: "sts:AssumeRole"
          }
        ]
      },
      policies: [
        {
          name: "MediaConnectAccess",
          policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "mediaconnect:DescribeFlow",
                  "mediaconnect:DescribeOffering",
                  "mediaconnect:PurchaseOffering"
                ],
                Resource: "*"
              }
            ]
          }
        }
      ]
    }).arn,
    tags: {
      Source: "remote",
      Transport: "mediaconnect",
      Reliability: "high"
    }
  })

  # Backup URL pull input
  backup_input = aws_media_live_input(:backup_url_pull, {
    name: "backup-url-pull",
    type: "URL_PULL",
    sources: [
      {
        url: "https://backup-stream.example.com/live/stream.m3u8",
        username: "backup_user",
        password_param: aws_ssm_parameter(:backup_stream_password, {
          name: "/medialive/backup/password",
          type: "SecureString",
          value: "backup-stream-password"
        }).name
      }
    ],
    role_arn: aws_iam_role(:medialive_url_pull_role, {
      # IAM role configuration for URL access
    }).arn,
    tags: {
      Source: "backup",
      Type: "failover"
    }
  })

  # File-based input for pre-recorded content
  file_input = aws_media_live_input(:file_content, {
    name: "pre-recorded-content",
    type: "MP4_FILE",
    sources: [
      {
        url: "s3ssl://content-bucket/prerecorded/program.mp4"
      }
    ],
    role_arn: aws_iam_role(:medialive_s3_role, {
      # S3 access role configuration
    }).arn,
    tags: {
      ContentType: "prerecorded",
      Purpose: "schedule-filler"
    }
  })

  # Output configuration showing input integration
  output :input_references do
    value {
      studio_input: studio_input.id,
      remote_input: remote_input.id,
      backup_input: backup_input.id,
      file_input: file_input.id
    }
    description "MediaLive input IDs for channel configuration"
  end
end
```

### Broadcast Production Workflow

```ruby
template :broadcast_production do
  # High-end RTP input for live production
  production_input = aws_media_live_input(:production_rtp, {
    name: "broadcast-production-rtp",
    type: "RTP_PUSH",
    input_class: "STANDARD",
    destinations: [
      {
        url: "rtp://10.0.10.100:5004"
      },
      {
        url: "rtp://10.0.20.100:5004"
      }
    ],
    vpc: {
      security_group_ids: [
        aws_security_group(:rtp_production_sg, {
          name: "rtp-production-sg",
          description: "RTP production security group",
          vpc_id: "vpc-production-123",
          ingress: [
            {
              from_port: 5004,
              to_port: 5004,
              protocol: "udp",
              cidr_blocks: ["10.0.0.0/16"]  # Internal network only
            }
          ]
        }).id
      ],
      subnet_ids: [
        "subnet-production-media-1a",
        "subnet-production-media-1b"
      ]
    },
    tags: {
      Environment: "production",
      Protocol: "rtp",
      Quality: "broadcast",
      Tier: "tier1"
    }
  })

  # Elemental Link device input for studio cameras
  device_input = aws_media_live_input(:studio_cameras, {
    name: "studio-camera-input",
    type: "INPUT_DEVICE",
    input_devices: [
      {
        id: "device-camera-001",
        settings: {
          audio_channel_pairs: [
            {
              id: 1,
              profile: "CBR-2000"  # High quality audio
            },
            {
              id: 2,
              profile: "CBR-2000"
            }
          ],
          codec: "AVC",
          max_bitrate: 50000000,  # 50 Mbps
          resolution: "UHD",      # 4K resolution
          scan_type: "PROGRESSIVE"
        }
      },
      {
        id: "device-camera-002",
        settings: {
          codec: "HEVC",          # HEVC for 4K efficiency
          max_bitrate: 30000000,
          resolution: "UHD",
          scan_type: "PROGRESSIVE"
        }
      }
    ],
    tags: {
      DeviceType: "elemental-link",
      Resolution: "4k",
      Location: "studio-floor",
      Purpose: "live-production"
    }
  })

  # Graphics/playout server input
  graphics_input = aws_media_live_input(:graphics_server, {
    name: "graphics-playout-input",
    type: "RTMP_PULL",
    sources: [
      {
        url: "rtmp://graphics-server-1.internal:1935/live/program",
        username: "playout_system",
        password_param: aws_ssm_parameter(:graphics_password, {
          name: "/broadcast/graphics/password",
          type: "SecureString",
          value: "graphics-server-password"
        }).name
      },
      {
        url: "rtmp://graphics-server-2.internal:1935/live/program",
        username: "playout_system",
        password_param: "/broadcast/graphics/backup-password"
      }
    ],
    tags: {
      Source: "graphics-server",
      Content: "program-playout",
      Redundancy: "automatic"
    }
  })

  # AWS CDI input for uncompressed video
  cdi_input = aws_media_live_input(:cdi_uncompressed, {
    name: "cdi-uncompressed-input",
    type: "AWS_CDI",
    vpc: {
      security_group_ids: [
        aws_security_group(:cdi_sg, {
          name: "cdi-security-group",
          description: "CDI uncompressed video security group", 
          vpc_id: "vpc-production-123",
          ingress: [
            {
              from_port: 2088,
              to_port: 2088,
              protocol: "udp",
              cidr_blocks: ["10.0.0.0/16"]
            }
          ]
        }).id
      ],
      subnet_ids: [
        "subnet-production-cdi-1a",
        "subnet-production-cdi-1b"
      ]
    },
    role_arn: aws_iam_role(:cdi_role, {
      name: "MediaLiveCDIRole",
      # CDI-specific permissions
    }).arn,
    tags: {
      Protocol: "cdi",
      Quality: "uncompressed",
      Bandwidth: "12gbps"
    }
  })
end
```

### Global Distribution Input Hub

```ruby
template :global_input_hub do
  # Regional input aggregation
  regions = ['us-east-1', 'eu-west-1', 'ap-southeast-1']
  
  regional_inputs = regions.map do |region|
    aws_media_live_input(:"regional_input_#{region.gsub('-', '_')}", {
      name: "regional-input-#{region}",
      type: "RTMP_PUSH",
      input_class: "STANDARD",
      destinations: [
        {
          stream_name: "regional-primary-#{region}",
          url: "rtmp://#{region}.medialive.amazonaws.com:1935/live"
        },
        {
          stream_name: "regional-backup-#{region}",
          url: "rtmp://backup-#{region}.medialive.amazonaws.com:1935/live"
        }
      ],
      input_security_groups: [
        "sg-regional-inputs-#{region}"
      ],
      tags: {
        Region: region,
        Purpose: "regional-aggregation",
        Tier: "global-distribution"
      }
    })
  end

  # Satellite/fiber contribution feeds
  satellite_input = aws_media_live_input(:satellite_feed, {
    name: "satellite-contribution",
    type: "UDP_PUSH",
    destinations: [
      {
        url: "udp://239.1.1.10:1234"  # Multicast for satellite
      }
    ],
    input_security_groups: [
      aws_medialive_input_security_group(:satellite_sg, {
        whitelist_rules: [
          {
            cidr: "203.0.113.0/24"  # Satellite uplink facility
          }
        ],
        tags: {
          Source: "satellite-uplink"
        }
      }).id
    ],
    tags: {
      Source: "satellite",
      Reliability: "primary",
      Coverage: "global"
    }
  })

  # Fiber contribution with redundancy
  fiber_input = aws_media_live_input(:fiber_contribution, {
    name: "fiber-contribution-input",
    type: "RTP_PUSH",
    destinations: [
      {
        url: "rtp://10.1.1.100:5004"  # Primary fiber endpoint
      },
      {
        url: "rtp://10.2.1.100:5004"  # Backup fiber endpoint
      }
    ],
    vpc: {
      security_group_ids: [
        aws_security_group(:fiber_sg, {
          name: "fiber-contribution-sg",
          vpc_id: "vpc-media-hub-123",
          ingress: [
            {
              from_port: 5004,
              to_port: 5008,  # Range for multiple streams
              protocol: "udp",
              cidr_blocks: ["10.0.0.0/8"]
            }
          ]
        }).id
      ],
      subnet_ids: [
        "subnet-fiber-1a",
        "subnet-fiber-1b"
      ]
    },
    tags: {
      Transport: "fiber",
      Quality: "contribution",
      Redundancy: "dual-path"
    }
  })

  # Internet contribution aggregation
  internet_inputs = (1..5).map do |i|
    aws_media_live_input(:"internet_feed_#{i}", {
      name: "internet-feed-#{i}",
      type: "RTMP_PULL",
      sources: [
        {
          url: "rtmp://feed#{i}.partner.example.com:1935/live/stream",
          username: "partner_#{i}",
          password_param: "/medialive/partners/feed#{i}/password"
        }
      ],
      tags: {
        Source: "internet-partner",
        Partner: "feed-#{i}",
        Quality: "variable"
      }
    })
  end

  # Output aggregated input information
  output :global_inputs do
    value {
      regional: regional_inputs.map(&:id),
      satellite: satellite_input.id,
      fiber: fiber_input.id,
      internet: internet_inputs.map(&:id)
    }
    description "Global input hub configuration"
  end
end
```

## Advanced Security Patterns

### Zero-Trust Input Security

```ruby
template :zero_trust_inputs do
  # Highly restricted input security group
  restricted_sg = aws_security_group(:zero_trust_input_sg, {
    name: "zero-trust-medialive-input",
    description: "Zero-trust security group for MediaLive inputs",
    vpc_id: "vpc-secure-prod-123",
    ingress: [
      {
        from_port: 1935,
        to_port: 1935,
        protocol: "tcp",
        source_security_group_id: "sg-encoder-whitelist"  # Only from approved encoders
      }
    ],
    egress: []  # No outbound allowed
  })

  # VPC-only input with strict access control
  secure_input = aws_media_live_input(:zero_trust_input, {
    name: "zero-trust-secure-input",
    type: "RTMP_PUSH",
    destinations: [
      {
        stream_name: "secure-stream",
        url: "rtmp://internal-lb.vpc.local:1935/live"
      }
    ],
    vpc: {
      security_group_ids: [
        restricted_sg.id,
        "sg-logging-endpoints",   # CloudWatch logs access
        "sg-parameter-store"      # Systems Manager access
      ],
      subnet_ids: [
        "subnet-secure-media-1a",
        "subnet-secure-media-1b"
      ]
    },
    role_arn: aws_iam_role(:zero_trust_medialive_role, {
      name: "ZeroTrustMediaLiveRole",
      assume_role_policy: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: { Service: "medialive.amazonaws.com" },
            Action: "sts:AssumeRole",
            Condition: {
              StringEquals: {
                "aws:RequestedRegion": "us-east-1"  # Region restriction
              }
            }
          }
        ]
      },
      policies: [
        {
          name: "MinimalMediaLiveAccess",
          policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "logs:CreateLogStream",
                  "logs:PutLogEvents"
                ],
                Resource: "arn:aws:logs:us-east-1:*:log-group:/aws/medialive/*"
              }
            ]
          }
        }
      ]
    }).arn,
    tags: {
      SecurityLevel: "zero-trust",
      NetworkAccess: "vpc-only",
      DataClassification: "restricted",
      Compliance: "required"
    }
  })

  # Monitoring for security events
  aws_cloudwatch_log_group(:security_logs, {
    name: "/aws/medialive/zero-trust/security",
    retention_in_days: 90,
    kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/security-logs"
  })

  # Security alarm for unauthorized access attempts
  aws_cloudwatch_metric_alarm(:unauthorized_access, {
    alarm_name: "medialive-unauthorized-access",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 1,
    metric_name: "UnauthorizedApiCalls",
    namespace: "AWS/MediaLive",
    period: 300,
    statistic: "Sum",
    threshold: 0,
    alarm_description: "Unauthorized access attempts to MediaLive inputs",
    alarm_actions: [
      "arn:aws:sns:us-east-1:123456789012:security-alerts"
    ]
  })
end
```

### Credential Management

```ruby
template :secure_credential_management do
  # KMS key for credential encryption
  credential_key = aws_kms_key(:medialive_credentials, {
    description: "MediaLive credential encryption key",
    policy: {
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::123456789012:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: "medialive.amazonaws.com" },
          Action: [
            "kms:Decrypt",
            "kms:DescribeKey"
          ],
          Resource: "*"
        }
      ]
    }
  })

  # Secure parameter store for stream credentials
  stream_credentials = [
    { name: "primary", password: "primary-stream-key" },
    { name: "backup", password: "backup-stream-key" },
    { name: "emergency", password: "emergency-stream-key" }
  ].map do |cred|
    aws_ssm_parameter(:"stream_#{cred[:name]}_password", {
      name: "/medialive/streams/#{cred[:name]}/password",
      type: "SecureString",
      value: cred[:password],
      key_id: credential_key.id,
      description: "MediaLive stream password for #{cred[:name]} feed"
    })
  end

  # Input with secure credential management
  authenticated_input = aws_media_live_input(:authenticated_pull, {
    name: "authenticated-stream-input",
    type: "RTMP_PULL",
    sources: stream_credentials.map.with_index do |param, index|
      {
        url: "rtmp://secure-source-#{index + 1}.example.com:1935/live/stream",
        username: "medialive_user_#{index + 1}",
        password_param: param.name
      }
    end,
    role_arn: aws_iam_role(:secure_credential_role, {
      name: "MediaLiveSecureCredentialRole",
      assume_role_policy: {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: { Service: "medialive.amazonaws.com" },
            Action: "sts:AssumeRole"
          }
        ]
      },
      policies: [
        {
          name: "ParameterStoreAccess",
          policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Action: [
                  "ssm:GetParameter",
                  "ssm:GetParameters"
                ],
                Resource: "arn:aws:ssm:*:*:parameter/medialive/streams/*"
              },
              {
                Effect: "Allow",
                Action: [
                  "kms:Decrypt"
                ],
                Resource: credential_key.arn
              }
            ]
          }
        }
      ]
    }).arn,
    tags: {
      CredentialManagement: "parameter-store",
      Encryption: "kms",
      AccessPattern: "pull"
    }
  })
end
```

## Performance Optimization

### High-Throughput Input Configuration

```ruby
template :high_throughput_inputs do
  # Optimized for maximum throughput
  high_perf_input = aws_media_live_input(:high_throughput, {
    name: "high-throughput-rtp",
    type: "RTP_PUSH", 
    input_class: "STANDARD",
    destinations: [
      {
        url: "rtp://10.0.100.10:5004"
      },
      {
        url: "rtp://10.0.200.10:5004"  
      }
    ],
    vpc: {
      security_group_ids: [
        aws_security_group(:high_perf_sg, {
          name: "high-performance-sg",
          vpc_id: "vpc-high-perf-123",
          ingress: [
            {
              from_port: 5004,
              to_port: 5020,  # Range for multiple concurrent streams
              protocol: "udp",
              cidr_blocks: ["10.0.0.0/16"]
            }
          ]
        }).id
      ],
      subnet_ids: [
        "subnet-high-perf-1a",  # Enhanced networking enabled
        "subnet-high-perf-1b"
      ]
    },
    tags: {
      Performance: "optimized",
      Bandwidth: "high", 
      Latency: "minimal",
      NetworkType: "enhanced"
    }
  })

  # Multiple parallel inputs for load distribution
  parallel_inputs = (1..4).map do |i|
    aws_media_live_input(:"parallel_input_#{i}", {
      name: "parallel-rtp-input-#{i}",
      type: "RTP_PUSH",
      destinations: [
        {
          url: "rtp://10.0.#{100 + i}.10:5004"
        }
      ],
      vpc: {
        security_group_ids: ["sg-parallel-inputs"],
        subnet_ids: ["subnet-parallel-#{i}"]
      },
      tags: {
        InputGroup: "parallel-processing",
        LoadBalancing: "enabled",
        Instance: "#{i}"
      }
    })
  end

  # Performance monitoring
  aws_cloudwatch_metric_alarm(:input_throughput, {
    alarm_name: "medialive-input-throughput",
    comparison_operator: "LessThanThreshold",
    evaluation_periods: 2,
    metric_name: "NetworkIn",
    namespace: "AWS/MediaLive",
    period: 60,
    statistic: "Average",
    threshold: 50000000,  # 50 Mbps minimum
    alarm_description: "MediaLive input throughput below threshold",
    dimensions: {
      InputId: high_perf_input.id
    }
  })
end
```

This implementation provides comprehensive MediaLive input management with advanced security, performance optimization, and operational monitoring capabilities for professional media workflows.