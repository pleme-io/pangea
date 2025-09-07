# AWS MediaPackage Channel - Technical Implementation

## Resource Overview

The `aws_media_package_channel` resource provides foundational content packaging capabilities for live streaming workflows, acting as the ingress point and origin service for video distribution architectures.

## Architecture Integration Patterns

### Complete Live Streaming Infrastructure

```ruby
template :complete_streaming_infrastructure do
  # Core MediaPackage channel
  primary_channel = aws_media_package_channel(:primary_streaming, {
    channel_id: "live-streaming-primary",
    description: "Primary live streaming channel for content packaging",
    tags: {
      Environment: "production",
      Service: "live-streaming",
      Tier: "primary",
      Region: "us-east-1"
    }
  })

  # Backup channel for redundancy
  backup_channel = aws_media_package_channel(:backup_streaming, {
    channel_id: "live-streaming-backup",
    description: "Backup channel for streaming redundancy",
    tags: {
      Environment: "production",
      Service: "live-streaming",
      Tier: "backup",
      Region: "us-west-2"
    }
  })

  # MediaLive channel feeding into MediaPackage
  live_channel = aws_media_live_channel(:broadcast_encoder, {
    name: "live-broadcast-encoder",
    channel_class: "STANDARD",
    input_attachments: [
      {
        input_attachment_name: "primary_input",
        input_id: aws_media_live_input(:rtmp_input, {
          name: "studio-rtmp-input",
          type: "RTMP_PUSH",
          destinations: [
            { stream_name: "live-stream" }
          ]
        }).id
      }
    ],
    encoder_settings: {
      audio_descriptions: [
        {
          audio_selector_name: "default",
          name: "aac_audio",
          codec_settings: {
            aac_settings: {
              bitrate: 128000.0,
              coding_mode: "CODING_MODE_2_0"
            }
          }
        }
      ],
      video_descriptions: [
        {
          name: "hd_video",
          codec_settings: {
            h264_settings: {
              bitrate: 5000000,
              rate_control_mode: "CBR",
              gop_size: 60.0
            }
          }
        }
      ],
      output_groups: [
        {
          output_group_settings: {
            media_package_group_settings: {
              destination: { destination_ref_id: "primary_package" }
            }
          },
          outputs: [
            {
              output_settings: {
                media_package_output_settings: {}
              }
            }
          ]
        }
      ],
      timecode_config: { source: "EMBEDDED" }
    },
    destinations: [
      {
        id: "primary_package",
        media_package_settings: [
          { channel_id: primary_channel.channel_id }
        ]
      },
      {
        id: "backup_package",
        media_package_settings: [
          { channel_id: backup_channel.channel_id }
        ]
      }
    ],
    input_specification: {
      codec: "AVC",
      maximum_bitrate: "MAX_20_MBPS",
      resolution: "HD"
    },
    role_arn: aws_iam_role(:medialive_role, {
      # MediaLive service role configuration
    }).arn
  })

  # Multiple origin endpoints for different formats
  hls_endpoint = aws_media_package_origin_endpoint(:hls_delivery, {
    channel_id: primary_channel.channel_id,
    id: "hls-adaptive-streaming",
    hls_package: {
      segment_duration_seconds: 6,
      playlist_window_seconds: 60,
      ad_markers: "SCTE35_ENHANCED",
      include_iframe_only_stream: true,
      use_audio_rendition_group: true
    }
  })

  dash_endpoint = aws_media_package_origin_endpoint(:dash_delivery, {
    channel_id: primary_channel.channel_id,
    id: "dash-adaptive-streaming", 
    dash_package: {
      segment_duration_seconds: 6,
      manifest_window_seconds: 60,
      profile: "NONE",
      stream_selection: {
        max_video_bits_per_second: 10000000,
        min_video_bits_per_second: 500000,
        stream_order: "ORIGINAL"
      }
    }
  })

  # CloudFront distribution for global delivery
  streaming_distribution = aws_cloudfront_distribution(:global_streaming, {
    origins: [
      {
        domain_name: hls_endpoint.url.gsub(/^https?:\/\//, ''),
        origin_id: "mediapackage-hls",
        custom_origin_config: {
          http_port: 80,
          https_port: 443,
          origin_protocol_policy: "https-only",
          origin_ssl_protocols: ["TLSv1.2"],
          origin_keepalive_timeout: 5,
          origin_read_timeout: 30
        }
      }
    ],
    default_cache_behavior: {
      target_origin_id: "mediapackage-hls",
      viewer_protocol_policy: "redirect-to-https",
      allowed_methods: ["GET", "HEAD", "OPTIONS"],
      cached_methods: ["GET", "HEAD"],
      compress: true,
      cache_policy_id: "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
      origin_request_policy_id: "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
    },
    enabled: true,
    http_version: "http2",
    is_ipv6_enabled: true,
    price_class: "PriceClass_All",
    comment: "Global live streaming distribution"
  })

  # Monitoring and alerting
  aws_cloudwatch_metric_alarm(:ingest_health, {
    alarm_name: "mediapackage-ingest-health",
    comparison_operator: "LessThanThreshold",
    evaluation_periods: 2,
    metric_name: "IngressRequestCount",
    namespace: "AWS/MediaPackage",
    period: 300,
    statistic: "Sum",
    threshold: 1.0,
    alarm_description: "MediaPackage channel not receiving content",
    dimensions: {
      Channel: primary_channel.channel_id
    }
  })

  # Output infrastructure endpoints
  output :streaming_endpoints do
    value {
      primary_channel_id: primary_channel.channel_id,
      hls_endpoint: hls_endpoint.url,
      dash_endpoint: dash_endpoint.url,
      cloudfront_domain: streaming_distribution.domain_name,
      ingest_endpoints: primary_channel.hls_ingest
    }
    description "Live streaming infrastructure endpoints"
  end
end
```

### Multi-Event Channel Management

```ruby
template :multi_event_channels do
  # Base configuration for event channels
  event_configs = [
    { id: "sports-championship", description: "Sports Championship Live Stream", expected_viewers: 500000 },
    { id: "conference-keynote", description: "Tech Conference Keynote", expected_viewers: 100000 },
    { id: "concert-live", description: "Live Concert Stream", expected_viewers: 250000 },
    { id: "breaking-news", description: "Breaking News Channel", expected_viewers: 1000000 }
  ]

  # Create channels for each event
  event_channels = event_configs.map do |config|
    aws_media_package_channel(:"channel_#{config[:id].gsub('-', '_')}", {
      channel_id: config[:id],
      description: config[:description],
      tags: {
        EventType: config[:id].split('-').first,
        ExpectedViewers: config[:expected_viewers].to_s,
        Environment: "production",
        Scaling: config[:expected_viewers] > 300000 ? "high" : "standard",
        Priority: config[:expected_viewers] > 500000 ? "critical" : "normal"
      }
    })
  end

  # Create origin endpoints for each channel
  endpoint_configurations = event_channels.map do |channel|
    # HLS endpoint with adaptive settings based on expected load
    expected_viewers = channel.resource_attributes[:tags]["ExpectedViewers"].to_i
    
    hls_config = if expected_viewers > 500000
      {
        segment_duration_seconds: 4,  # Shorter segments for better startup
        playlist_window_seconds: 120, # Longer buffer for high load
        ad_markers: "SCTE35_ENHANCED",
        include_iframe_only_stream: true,
        use_audio_rendition_group: true,
        program_date_time_interval_seconds: 60
      }
    else
      {
        segment_duration_seconds: 6,
        playlist_window_seconds: 60,
        ad_markers: "SCTE35_ENHANCED"
      }
    end

    aws_media_package_origin_endpoint(:"endpoint_#{channel.name}", {
      channel_id: channel.channel_id,
      id: "#{channel.channel_id}-hls",
      hls_package: hls_config
    })
  end

  # Auto-scaling CloudFront behaviors
  event_distributions = endpoint_configurations.map do |endpoint|
    channel_name = endpoint.name.to_s.gsub('endpoint_channel_', '')
    expected_viewers = event_channels.find { |c| c.name.to_s.include?(channel_name) }
                                   .resource_attributes[:tags]["ExpectedViewers"].to_i

    price_class = expected_viewers > 300000 ? "PriceClass_All" : "PriceClass_100"
    
    aws_cloudfront_distribution(:"dist_#{channel_name}", {
      origins: [
        {
          domain_name: endpoint.url.gsub(/^https?:\/\//, ''),
          origin_id: "#{channel_name}-origin",
          custom_origin_config: {
            http_port: 80,
            https_port: 443,
            origin_protocol_policy: "https-only"
          }
        }
      ],
      default_cache_behavior: {
        target_origin_id: "#{channel_name}-origin",
        viewer_protocol_policy: "redirect-to-https",
        allowed_methods: ["GET", "HEAD"],
        cached_methods: ["GET", "HEAD"],
        compress: true,
        cache_policy_id: "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      },
      enabled: true,
      price_class: price_class,
      comment: "Distribution for #{channel_name.humanize} event"
    })
  end

  # Comprehensive monitoring per channel
  event_channels.each do |channel|
    aws_cloudwatch_metric_alarm(:"#{channel.name}_ingest", {
      alarm_name: "#{channel.channel_id}-ingest-health",
      comparison_operator: "LessThanThreshold",
      evaluation_periods: 3,
      metric_name: "IngressRequestCount",
      namespace: "AWS/MediaPackage",
      period: 60,
      statistic: "Sum",
      threshold: 1.0,
      dimensions: { Channel: channel.channel_id }
    })

    aws_cloudwatch_metric_alarm(:"#{channel.name}_egress", {
      alarm_name: "#{channel.channel_id}-high-egress",
      comparison_operator: "GreaterThanThreshold",
      evaluation_periods: 2,
      metric_name: "EgressRequestCount", 
      namespace: "AWS/MediaPackage",
      period: 300,
      statistic: "Sum",
      threshold: channel.resource_attributes[:tags]["ExpectedViewers"].to_i * 0.8,
      dimensions: { Channel: channel.channel_id }
    })
  end

  # Event management outputs
  output :event_channels do
    value Hash[event_channels.map { |c| [c.channel_id, {
      channel_arn: c.arn,
      ingest_endpoints: c.hls_ingest,
      expected_viewers: c.resource_attributes[:tags]["ExpectedViewers"]
    }] }]
    description "Event channel configuration and endpoints"
  end
end
```

### Enterprise Broadcasting Platform

```ruby
template :enterprise_broadcasting do
  # Regional channel architecture
  regions = ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"]
  
  regional_channels = regions.map do |region|
    aws_media_package_channel(:"enterprise_#{region.gsub('-', '_')}", {
      channel_id: "enterprise-broadcast-#{region}",
      description: "Enterprise broadcasting channel for #{region}",
      tags: {
        Environment: "production",
        Service: "enterprise-broadcasting",
        Region: region,
        Tier: "enterprise",
        SLA: "99.9",
        Support: "24x7",
        Disaster_Recovery: "enabled"
      }
    })
  end

  # Premium origin endpoints with advanced features
  premium_endpoints = regional_channels.map do |channel|
    region = channel.channel_id.split('-').last
    
    # HLS endpoint with enterprise features
    hls_endpoint = aws_media_package_origin_endpoint(:"premium_hls_#{region.gsub('-', '_')}", {
      channel_id: channel.channel_id,
      id: "premium-hls-#{region}",
      hls_package: {
        segment_duration_seconds: 6,
        playlist_window_seconds: 300,  # 5-minute buffer
        ad_markers: "SCTE35_ENHANCED",
        include_iframe_only_stream: true,
        use_audio_rendition_group: true,
        program_date_time_interval_seconds: 30,
        playlist_type: "EVENT"
      },
      authorization: {
        cdn_identifier_secret: aws_ssm_parameter(:"cdn_secret_#{region.gsub('-', '_')}", {
          name: "/mediapackage/cdn/secret/#{region}",
          type: "SecureString",
          value: "enterprise-cdn-secret-#{region}"
        }).value,
        secrets_role_arn: aws_iam_role(:"mediapackage_secrets_role_#{region.gsub('-', '_')}", {
          name: "MediaPackageSecretsRole-#{region}",
          assume_role_policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Effect: "Allow",
                Principal: { Service: "mediapackage.amazonaws.com" },
                Action: "sts:AssumeRole"
              }
            ]
          }
        }).arn
      }
    })

    # DASH endpoint for premium delivery
    dash_endpoint = aws_media_package_origin_endpoint(:"premium_dash_#{region.gsub('-', '_')}", {
      channel_id: channel.channel_id,
      id: "premium-dash-#{region}",
      dash_package: {
        segment_duration_seconds: 6,
        manifest_window_seconds: 300,
        profile: "HBBTV_1_5",
        min_update_period_seconds: 6,
        suggested_presentation_delay_seconds: 18,
        stream_selection: {
          max_video_bits_per_second: 20000000,
          min_video_bits_per_second: 500000,
          stream_order: "ORIGINAL"
        }
      }
    })

    # CMAF endpoint for modern devices
    cmaf_endpoint = aws_media_package_origin_endpoint(:"premium_cmaf_#{region.gsub('-', '_')}", {
      channel_id: channel.channel_id,
      id: "premium-cmaf-#{region}",
      cmaf_package: {
        segment_duration_seconds: 6,
        hls_manifests: [
          {
            id: "cmaf-hls",
            include_iframe_only_stream: true,
            playlist_type: "EVENT",
            playlist_window_seconds: 300,
            program_date_time_interval_seconds: 30
          }
        ],
        dash_manifests: [
          {
            id: "cmaf-dash",
            manifest_window_seconds: 300,
            min_update_period_seconds: 6,
            profile: "NONE"
          }
        ]
      }
    })

    { region: region, hls: hls_endpoint, dash: dash_endpoint, cmaf: cmaf_endpoint }
  end

  # Enterprise-grade monitoring and alerting
  regional_channels.each do |channel|
    region = channel.channel_id.split('-').last

    # SLA monitoring
    aws_cloudwatch_metric_alarm(:"sla_#{region.gsub('-', '_')}_availability", {
      alarm_name: "enterprise-#{region}-availability-sla",
      comparison_operator: "LessThanThreshold",
      evaluation_periods: 1,
      metric_name: "OriginRequestCount",
      namespace: "AWS/MediaPackage", 
      period: 300,
      statistic: "Sum",
      threshold: 1.0,
      alarm_description: "Enterprise SLA availability breach for #{region}",
      dimensions: { Channel: channel.channel_id },
      alarm_actions: [
        "arn:aws:sns:#{region}:123456789012:enterprise-critical-alerts"
      ]
    })

    # Performance monitoring
    aws_cloudwatch_metric_alarm(:"perf_#{region.gsub('-', '_')}_latency", {
      alarm_name: "enterprise-#{region}-latency-warning",
      comparison_operator: "GreaterThanThreshold", 
      evaluation_periods: 3,
      metric_name: "OriginLatency",
      namespace: "AWS/MediaPackage",
      period: 60,
      statistic: "Average",
      threshold: 1000.0,  # 1 second
      alarm_description: "High latency detected for enterprise channel in #{region}",
      dimensions: { Channel: channel.channel_id }
    })

    # Capacity monitoring
    aws_cloudwatch_metric_alarm(:"capacity_#{region.gsub('-', '_')}_egress", {
      alarm_name: "enterprise-#{region}-high-egress-volume",
      comparison_operator: "GreaterThanThreshold",
      evaluation_periods: 2,
      metric_name: "EgressBytes",
      namespace: "AWS/MediaPackage", 
      period: 300,
      statistic: "Sum",
      threshold: 10000000000.0,  # 10 GB per 5-minute period
      alarm_description: "High egress volume for enterprise channel in #{region}",
      dimensions: { Channel: channel.channel_id }
    })
  end

  # Disaster recovery configuration
  dr_channels = ["us-west-2", "eu-central-1"].map do |region|
    aws_media_package_channel(:"dr_#{region.gsub('-', '_')}", {
      channel_id: "enterprise-dr-#{region}",
      description: "Disaster recovery channel for #{region}",
      tags: {
        Environment: "disaster-recovery",
        Service: "enterprise-broadcasting",
        Region: region,
        Purpose: "failover",
        Activation: "manual"
      }
    })
  end

  # Global load balancing configuration
  output :enterprise_broadcasting_config do
    value {
      primary_channels: Hash[regional_channels.map { |c| [c.channel_id.split('-').last, c.channel_id] }],
      disaster_recovery: Hash[dr_channels.map { |c| [c.channel_id.split('-').last, c.channel_id] }],
      endpoints: Hash[premium_endpoints.map { |e| [
        e[:region], 
        {
          hls: e[:hls].url,
          dash: e[:dash].url, 
          cmaf_hls: "#{e[:cmaf].url}/cmaf-hls/",
          cmaf_dash: "#{e[:cmaf].url}/cmaf-dash/"
        }
      ] }]
    }
    description "Enterprise broadcasting platform configuration"
  end
end
```

## Operational Excellence Patterns

### Automated Channel Lifecycle Management

```ruby
template :automated_channel_lifecycle do
  # Base configuration for scheduled channels
  scheduled_events = [
    { name: "daily-news", schedule: "0 6,12,18 * * *", duration_hours: 1 },
    { name: "weekly-sports", schedule: "0 14 * * 6,0", duration_hours: 4 },
    { name: "monthly-town-hall", schedule: "0 10 1 * *", duration_hours: 2 }
  ]

  # Create channels with lifecycle tags
  scheduled_channels = scheduled_events.map do |event|
    aws_media_package_channel(:"auto_#{event[:name].gsub('-', '_')}", {
      channel_id: "auto-#{event[:name]}",
      description: "Automatically managed channel for #{event[:name]}",
      tags: {
        Management: "automated",
        Schedule: event[:schedule],
        Duration: "#{event[:duration_hours]}h",
        AutoStart: "enabled",
        AutoStop: "enabled",
        CostOptimization: "aggressive"
      }
    })
  end

  # Lambda function for channel lifecycle management
  lifecycle_function = aws_lambda_function(:channel_lifecycle_manager, {
    function_name: "mediapackage-channel-lifecycle",
    runtime: "python3.9",
    handler: "index.handler",
    code: {
      zip_file: <<~PYTHON
        import json
        import boto3
        import os
        from datetime import datetime
        
        def handler(event, context):
            mediapackage = boto3.client('mediapackage')
            
            # Channel lifecycle logic based on tags
            # Implementation would include:
            # - Start/stop channels based on schedule
            # - Monitor usage and auto-scale
            # - Clean up unused channels
            # - Cost optimization actions
            
            return {
                'statusCode': 200,
                'body': json.dumps('Channel lifecycle management completed')
            }
      PYTHON
    },
    role: aws_iam_role(:lifecycle_lambda_role, {
      # IAM role with MediaPackage permissions
    }).arn,
    timeout: 300,
    environment: {
      variables: {
        CHANNELS: scheduled_channels.map(&:channel_id).join(',')
      }
    }
  })

  # EventBridge rule for scheduled execution
  aws_eventbridge_rule(:channel_lifecycle_schedule, {
    name: "mediapackage-channel-lifecycle",
    description: "Scheduled channel lifecycle management",
    schedule_expression: "rate(15 minutes)",
    targets: [
      {
        id: "lifecycle-lambda",
        arn: lifecycle_function.arn
      }
    ]
  })
end
```

### Cost Optimization and Resource Management

```ruby
template :cost_optimized_channels do
  # Tiered channel configuration based on usage patterns
  channel_tiers = {
    premium: { retention_days: 30, monitoring: "enhanced", sla: "99.9" },
    standard: { retention_days: 7, monitoring: "standard", sla: "99.5" },
    basic: { retention_days: 1, monitoring: "basic", sla: "99.0" }
  }

  optimized_channels = channel_tiers.map do |tier, config|
    aws_media_package_channel(:"optimized_#{tier}", {
      channel_id: "cost-optimized-#{tier}",
      description: "Cost-optimized #{tier} tier channel",
      tags: {
        Tier: tier.to_s,
        CostTier: tier.to_s,
        RetentionDays: config[:retention_days].to_s,
        MonitoringLevel: config[:monitoring],
        SLA: config[:sla],
        BillingOptimization: "enabled"
      }
    })
  end

  # Cost monitoring and alerts
  optimized_channels.each do |channel|
    tier = channel.resource_attributes[:tags]["Tier"]
    
    aws_cloudwatch_metric_alarm(:"cost_#{tier}_egress", {
      alarm_name: "#{channel.channel_id}-cost-alert",
      comparison_operator: "GreaterThanThreshold",
      evaluation_periods: 1,
      metric_name: "EgressBytes",
      namespace: "AWS/MediaPackage",
      period: 3600,
      statistic: "Sum",
      threshold: case tier
                 when "premium" then 100000000000  # 100 GB/hour
                 when "standard" then 50000000000  # 50 GB/hour  
                 when "basic" then 10000000000     # 10 GB/hour
                 end,
      alarm_description: "High egress cost for #{tier} tier channel",
      dimensions: { Channel: channel.channel_id }
    })
  end

  # Automated cost optimization function
  cost_optimization_function = aws_lambda_function(:cost_optimizer, {
    function_name: "mediapackage-cost-optimizer",
    runtime: "python3.9", 
    handler: "cost_optimizer.handler",
    code: {
      s3_bucket: "deployment-artifacts-bucket",
      s3_key: "mediapackage-cost-optimizer.zip"
    },
    role: aws_iam_role(:cost_optimizer_role, {
      # Role with cost optimization permissions
    }).arn,
    environment: {
      variables: {
        COST_THRESHOLD_DAILY: "1000",
        OPTIMIZATION_ENABLED: "true"
      }
    }
  })

  # Daily cost optimization schedule
  aws_eventbridge_rule(:daily_cost_optimization, {
    name: "daily-mediapackage-cost-optimization",
    schedule_expression: "cron(0 2 * * ? *)",  # 2 AM daily
    targets: [
      {
        id: "cost-optimizer",
        arn: cost_optimization_function.arn
      }
    ]
  })
end
```

This implementation provides comprehensive MediaPackage channel management with enterprise-grade features, automated lifecycle management, and cost optimization strategies for scalable live streaming architectures.