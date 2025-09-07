# AWS MediaLive Channel - Technical Implementation

## Resource Overview

The `aws_media_live_channel` resource provides comprehensive support for AWS MediaLive channels, enabling live video processing, encoding, and distribution workflows with enterprise-grade features.

## Architecture Integration Patterns

### Live Streaming Infrastructure

```ruby
template :live_streaming_platform do
  # Input infrastructure
  rtmp_input = aws_media_live_input(:rtmp_input, {
    name: "rtmp-ingest",
    type: "RTMP_PUSH",
    destinations: [
      { url: "rtmp://ingest1.example.com:1935/live" },
      { url: "rtmp://ingest2.example.com:1935/live" }
    ]
  })

  # Processing channel
  live_channel = aws_media_live_channel(:broadcast_channel, {
    name: "live-broadcast-processor",
    channel_class: "STANDARD",
    input_attachments: [
      {
        input_attachment_name: "primary_feed",
        input_id: rtmp_input.id
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
          height: 1080,
          width: 1920,
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
            hls_group_settings: {
              destination: { destination_ref_id: "hls_out" },
              segment_length: 6
            }
          },
          outputs: [
            {
              output_settings: {
                hls_output_settings: {
                  hls_settings: {
                    standard_hls_settings: {
                      m3u8_settings: {
                        program_num: 1
                      }
                    }
                  }
                }
              }
            }
          ]
        }
      ],
      timecode_config: { source: "EMBEDDED" }
    },
    destinations: [
      {
        id: "hls_out",
        settings: [
          { url: "s3ssl://streaming-bucket/hls/" }
        ]
      }
    ],
    input_specification: {
      codec: "AVC",
      maximum_bitrate: "MAX_20_MBPS",
      resolution: "HD"
    },
    role_arn: aws_iam_role(:medialive_role, {
      # IAM role configuration
    }).arn
  })

  # Distribution through CloudFront
  aws_cloudfront_distribution(:streaming_cdn, {
    origins: [
      {
        domain_name: "streaming-bucket.s3.amazonaws.com",
        origin_path: "/hls",
        custom_origin_config: {
          http_port: 80,
          https_port: 443,
          origin_protocol_policy: "https-only"
        }
      }
    ],
    default_cache_behavior: {
      target_origin_id: "s3-origin",
      viewer_protocol_policy: "redirect-to-https",
      allowed_methods: ["GET", "HEAD"],
      cached_methods: ["GET", "HEAD"],
      compress: true
    },
    enabled: true
  })
end
```

### Multi-Region Broadcasting

```ruby
template :global_broadcast do
  # Primary region setup
  primary_channel = aws_media_live_channel(:primary_broadcast, {
    name: "global-primary-channel",
    channel_class: "STANDARD",
    # Comprehensive configuration...
    destinations: [
      {
        id: "primary_hls",
        settings: [
          { url: "s3ssl://primary-region-bucket/live/" }
        ]
      },
      {
        id: "backup_rtmp", 
        settings: [
          {
            url: "rtmps://backup-region-ingest.example.com/live/",
            stream_name: "primary-backup-stream"
          }
        ]
      }
    ],
    vpc: {
      public_address_allocation_ids: [
        "eipalloc-primary-1",
        "eipalloc-primary-2"
      ],
      security_group_ids: ["sg-medialive-primary"],
      subnet_ids: ["subnet-primary-1", "subnet-primary-2"]
    }
  })

  # Cross-region replication monitoring
  aws_cloudwatch_metric_alarm(:channel_health, {
    alarm_name: "medialive-channel-health",
    comparison_operator: "LessThanThreshold",
    evaluation_periods: 2,
    metric_name: "NetworkIn",
    namespace: "AWS/MediaLive",
    period: 300,
    statistic: "Average",
    threshold: 1000000,
    alarm_description: "MediaLive channel input monitoring",
    dimensions: {
      ChannelId: primary_channel.channel_id
    }
  })
end
```

### Adaptive Bitrate Streaming

```ruby
template :abr_streaming do
  abr_channel = aws_media_live_channel(:abr_channel, {
    name: "adaptive-bitrate-channel",
    channel_class: "STANDARD",
    input_attachments: [
      {
        input_attachment_name: "source_feed",
        input_id: "input-source-123"
      }
    ],
    encoder_settings: {
      audio_descriptions: [
        {
          audio_selector_name: "default",
          name: "audio_128k",
          codec_settings: {
            aac_settings: {
              bitrate: 128000.0,
              coding_mode: "CODING_MODE_2_0",
              sample_rate: 48000.0,
              profile: "LC"
            }
          }
        },
        {
          audio_selector_name: "default",
          name: "audio_64k",
          codec_settings: {
            aac_settings: {
              bitrate: 64000.0,
              coding_mode: "CODING_MODE_2_0",
              sample_rate: 48000.0,
              profile: "LC"
            }
          }
        }
      ],
      video_descriptions: [
        {
          name: "video_1080p",
          height: 1080,
          width: 1920,
          codec_settings: {
            h264_settings: {
              bitrate: 6000000,
              rate_control_mode: "CBR",
              profile: "HIGH",
              level: "H264_LEVEL_4_1",
              gop_size: 90.0,
              gop_b_reference: "ENABLED"
            }
          }
        },
        {
          name: "video_720p",
          height: 720,
          width: 1280,
          codec_settings: {
            h264_settings: {
              bitrate: 3500000,
              rate_control_mode: "CBR",
              profile: "HIGH",
              level: "H264_LEVEL_4",
              gop_size: 90.0
            }
          }
        },
        {
          name: "video_480p",
          height: 480,
          width: 854,
          codec_settings: {
            h264_settings: {
              bitrate: 1500000,
              rate_control_mode: "CBR",
              profile: "MAIN",
              level: "H264_LEVEL_3_1",
              gop_size: 90.0
            }
          }
        }
      ],
      output_groups: [
        {
          name: "HLS_ABR",
          output_group_settings: {
            hls_group_settings: {
              destination: { destination_ref_id: "abr_output" },
              manifest_duration_format: "FLOATING_POINT",
              segment_length: 6,
              program_date_time: "INCLUDE",
              hls_id3_segment_tagging: "ENABLED",
              codec_specification: "RFC_6381",
              output_selection: "MANIFESTS_AND_SEGMENTS",
              caption_language_setting: "OMIT",
              client_cache: "ENABLED",
              stream_inf_resolution: "INCLUDE"
            }
          },
          outputs: [
            {
              output_name: "1080p",
              audio_description_names: ["audio_128k"],
              video_description_name: "video_1080p",
              output_settings: {
                hls_output_settings: {
                  name_modifier: "_1080p",
                  hls_settings: {
                    standard_hls_settings: {
                      audio_rendition_sets: "program_audio",
                      m3u8_settings: {
                        program_num: 1,
                        audio_frames_per_pes: 4,
                        nielsen_id3_behavior: "PASSTHROUGH",
                        scte35_behavior: "PASSTHROUGH"
                      }
                    }
                  }
                }
              }
            },
            {
              output_name: "720p",
              audio_description_names: ["audio_128k"],
              video_description_name: "video_720p",
              output_settings: {
                hls_output_settings: {
                  name_modifier: "_720p",
                  hls_settings: {
                    standard_hls_settings: {
                      m3u8_settings: {
                        program_num: 2,
                        audio_frames_per_pes: 4
                      }
                    }
                  }
                }
              }
            },
            {
              output_name: "480p",
              audio_description_names: ["audio_64k"],
              video_description_name: "video_480p", 
              output_settings: {
                hls_output_settings: {
                  name_modifier: "_480p",
                  hls_settings: {
                    standard_hls_settings: {
                      m3u8_settings: {
                        program_num: 3,
                        audio_frames_per_pes: 4
                      }
                    }
                  }
                }
              }
            }
          ]
        }
      ],
      timecode_config: {
        source: "EMBEDDED",
        sync_threshold: 5000
      },
      global_configuration: {
        input_end_action: "SWITCH_AND_LOOP_INPUTS",
        output_timing_source: "INPUT_CLOCK",
        support_low_framerate_inputs: "DISABLED"
      }
    },
    destinations: [
      {
        id: "abr_output",
        settings: [
          {
            url: "s3ssl://abr-streaming-bucket/live/{output_name}/"
          }
        ]
      }
    ],
    input_specification: {
      codec: "AVC",
      maximum_bitrate: "MAX_20_MBPS", 
      resolution: "HD"
    },
    role_arn: "arn:aws:iam::123456789012:role/MediaLiveStreamingRole"
  })

  # Output metrics for monitoring ABR performance
  output :channel_arn do
    value abr_channel.arn
    description "MediaLive channel ARN for monitoring"
  end

  output :channel_id do
    value abr_channel.channel_id
    description "MediaLive channel ID for API operations"
  end
end
```

## Advanced Features

### SCTE-35 Ad Insertion

```ruby
# Channel with advanced SCTE-35 ad insertion support
aws_media_live_channel(:ad_insertion_channel, {
  name: "scte35-ad-insertion",
  encoder_settings: {
    # Audio/video descriptions...
    output_groups: [
      {
        output_group_settings: {
          hls_group_settings: {
            destination: { destination_ref_id: "ads_hls" },
            ad_markers: ["ELEMENTAL_SCTE35"],
            program_date_time: "INCLUDE",
            program_date_time_period: 600,
            timed_metadata_id3_frame: "PRIV",
            timed_metadata_id3_period: 10
          }
        },
        outputs: [
          {
            output_settings: {
              hls_output_settings: {
                hls_settings: {
                  standard_hls_settings: {
                    m3u8_settings: {
                      scte35_behavior: "PASSTHROUGH",
                      timed_metadata_behavior: "PASSTHROUGH"
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ],
    avail_configuration: {
      avail_settings: {
        scte35_splice_insert: {
          ad_avail_offset: 0,
          no_regional_blackout_flag: "FOLLOW",
          web_delivery_allowed_flag: "FOLLOW"
        }
      }
    }
  }
  # Other configuration...
})
```

### Multi-Language Audio Support

```ruby
# Channel with multiple audio languages
aws_media_live_channel(:multilang_channel, {
  name: "multilingual-broadcast",
  input_attachments: [
    {
      input_attachment_name: "multilang_input",
      input_id: "input-multilang-456",
      input_settings: {
        audio_selectors: [
          {
            name: "english_audio",
            selector_settings: {
              audio_language_selection: {
                language_code: "eng",
                language_selection_policy: "STRICT"
              }
            }
          },
          {
            name: "spanish_audio",
            selector_settings: {
              audio_language_selection: {
                language_code: "spa",
                language_selection_policy: "STRICT"
              }
            }
          },
          {
            name: "french_audio",
            selector_settings: {
              audio_language_selection: {
                language_code: "fra",
                language_selection_policy: "STRICT"
              }
            }
          }
        ]
      }
    }
  ],
  encoder_settings: {
    audio_descriptions: [
      {
        audio_selector_name: "english_audio",
        name: "eng_aac",
        language_code: "eng",
        language_code_control: "USE_CONFIGURED",
        codec_settings: {
          aac_settings: {
            bitrate: 128000.0,
            coding_mode: "CODING_MODE_2_0"
          }
        }
      },
      {
        audio_selector_name: "spanish_audio", 
        name: "spa_aac",
        language_code: "spa",
        language_code_control: "USE_CONFIGURED",
        codec_settings: {
          aac_settings: {
            bitrate: 128000.0,
            coding_mode: "CODING_MODE_2_0"
          }
        }
      },
      {
        audio_selector_name: "french_audio",
        name: "fra_aac", 
        language_code: "fra",
        language_code_control: "USE_CONFIGURED",
        codec_settings: {
          aac_settings: {
            bitrate: 128000.0,
            coding_mode: "CODING_MODE_2_0"
          }
        }
      }
    ],
    output_groups: [
      {
        output_group_settings: {
          hls_group_settings: {
            destination: { destination_ref_id: "multilang_hls" },
            caption_language_mappings: [
              {
                caption_channel: 1,
                language_code: "eng",
                language_description: "English"
              },
              {
                caption_channel: 2, 
                language_code: "spa",
                language_description: "Spanish"
              },
              {
                caption_channel: 3,
                language_code: "fra", 
                language_description: "French"
              }
            ],
            caption_language_setting: "INSERT"
          }
        },
        outputs: [
          {
            output_name: "english_stream",
            audio_description_names: ["eng_aac"],
            output_settings: {
              hls_output_settings: {
                name_modifier: "_eng",
                hls_settings: {
                  audio_only_hls_settings: {
                    audio_group_id: "english_audio",
                    audio_track_type: "ALTERNATE_AUDIO_AUTO_SELECT_DEFAULT"
                  }
                }
              }
            }
          },
          {
            output_name: "spanish_stream",
            audio_description_names: ["spa_aac"],
            output_settings: {
              hls_output_settings: {
                name_modifier: "_spa",
                hls_settings: {
                  audio_only_hls_settings: {
                    audio_group_id: "spanish_audio",
                    audio_track_type: "ALTERNATE_AUDIO_AUTO_SELECT"
                  }
                }
              }
            }
          },
          {
            output_name: "french_stream",
            audio_description_names: ["fra_aac"],
            output_settings: {
              hls_output_settings: {
                name_modifier: "_fra",
                hls_settings: {
                  audio_only_hls_settings: {
                    audio_group_id: "french_audio",
                    audio_track_type: "ALTERNATE_AUDIO_AUTO_SELECT"
                  }
                }
              }
            }
          }
        ]
      }
    ]
  }
  # Other configuration...
})
```

## Operational Considerations

### Monitoring and Alerting

```ruby
template :medialive_monitoring do
  channel = aws_media_live_channel(:monitored_channel, {
    # Channel configuration...
  })

  # Input signal monitoring
  aws_cloudwatch_metric_alarm(:input_signal_loss, {
    alarm_name: "medialive-input-signal-loss",
    comparison_operator: "LessThanThreshold",
    evaluation_periods: 3,
    metric_name: "InputVideoFrameRate",
    namespace: "AWS/MediaLive",
    period: 60,
    statistic: "Average", 
    threshold: 1.0,
    alarm_description: "MediaLive input signal loss detection",
    dimensions: {
      ChannelId: channel.channel_id,
      Pipeline: "0"
    },
    alarm_actions: [
      "arn:aws:sns:us-east-1:123456789012:medialive-alerts"
    ]
  })

  # Output bitrate monitoring
  aws_cloudwatch_metric_alarm(:output_bitrate_low, {
    alarm_name: "medialive-output-bitrate-low",
    comparison_operator: "LessThanThreshold",
    evaluation_periods: 2,
    metric_name: "OutputVideoBitrate",
    namespace: "AWS/MediaLive", 
    period: 300,
    statistic: "Average",
    threshold: 1000000, # 1 Mbps
    alarm_description: "MediaLive output bitrate below threshold",
    dimensions: {
      ChannelId: channel.channel_id,
      Pipeline: "0"
    }
  })

  # Error monitoring
  aws_cloudwatch_metric_alarm(:channel_errors, {
    alarm_name: "medialive-channel-errors",
    comparison_operator: "GreaterThanThreshold",
    evaluation_periods: 1,
    metric_name: "PipelineErrorCount",
    namespace: "AWS/MediaLive",
    period: 300,
    statistic: "Sum",
    threshold: 0,
    alarm_description: "MediaLive channel pipeline errors",
    dimensions: {
      ChannelId: channel.channel_id
    }
  })
end
```

### Cost Optimization Strategies

```ruby
template :cost_optimized_streaming do
  # Development/testing single pipeline channel
  dev_channel = aws_media_live_channel(:dev_channel, {
    name: "development-channel",
    channel_class: "SINGLE_PIPELINE", # Lower cost
    input_attachments: [
      {
        input_attachment_name: "dev_input",
        input_id: "input-dev-123"
      }
    ],
    encoder_settings: {
      # Minimal configuration for cost savings
      audio_descriptions: [
        {
          audio_selector_name: "default",
          name: "basic_audio",
          codec_settings: {
            aac_settings: {
              bitrate: 96000.0, # Lower bitrate
              coding_mode: "CODING_MODE_2_0"
            }
          }
        }
      ],
      video_descriptions: [
        {
          name: "basic_video",
          height: 720, # Lower resolution
          width: 1280,
          codec_settings: {
            h264_settings: {
              bitrate: 2500000, # Lower bitrate
              rate_control_mode: "CBR",
              profile: "MAIN" # Lower complexity profile
            }
          }
        }
      ],
      output_groups: [
        {
          output_group_settings: {
            hls_group_settings: {
              destination: { destination_ref_id: "dev_output" },
              segment_length: 10 # Longer segments
            }
          },
          outputs: [
            {
              output_settings: {
                hls_output_settings: {
                  hls_settings: {
                    standard_hls_settings: {
                      m3u8_settings: {
                        program_num: 1
                      }
                    }
                  }
                }
              }
            }
          ]
        }
      ],
      timecode_config: { source: "SYSTEMCLOCK" }
    },
    destinations: [
      {
        id: "dev_output",
        settings: [
          { url: "s3ssl://dev-streaming-bucket/" }
        ]
      }
    ],
    input_specification: {
      codec: "AVC",
      maximum_bitrate: "MAX_10_MBPS", # Lower max bitrate
      resolution: "HD" # Not UHD
    },
    log_level: "ERROR", # Minimal logging
    role_arn: "arn:aws:iam::123456789012:role/MediaLiveBasicRole",
    tags: {
      Environment: "development",
      CostCenter: "engineering",
      AutoShutdown: "enabled"
    }
  })
end
```

## Security Best Practices

### VPC Deployment

```ruby
template :secure_medialive do
  # Secure MediaLive channel in VPC
  secure_channel = aws_media_live_channel(:secure_channel, {
    name: "secure-broadcast-channel",
    channel_class: "STANDARD",
    # Standard configuration...
    vpc: {
      public_address_allocation_ids: [
        "eipalloc-secure-1",
        "eipalloc-secure-2"
      ],
      security_group_ids: [
        "sg-medialive-secure"  # Restricted security group
      ],
      subnet_ids: [
        "subnet-private-1",    # Private subnets
        "subnet-private-2"
      ]
    },
    destinations: [
      {
        id: "secure_output",
        settings: [
          {
            url: "s3ssl://encrypted-streaming-bucket/", # SSL/TLS
            username: "medialive-user",
            password_param: "/medialive/secure/password" # Systems Manager Parameter
          }
        ]
      }
    ],
    role_arn: "arn:aws:iam::123456789012:role/MediaLiveSecureRole", # Least privilege role
    tags: {
      SecurityLevel: "high",
      DataClassification: "confidential",
      Compliance: "required"
    }
  })

  # Dedicated security group for MediaLive
  aws_security_group(:medialive_sg, {
    name: "medialive-secure-sg", 
    description: "Security group for MediaLive channel",
    vpc_id: "vpc-secure-123",
    ingress: [
      {
        from_port: 1935,
        to_port: 1935,
        protocol: "tcp",
        cidr_blocks: ["10.0.0.0/8"] # Internal networks only
      }
    ],
    egress: [
      {
        from_port: 443,
        to_port: 443, 
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"] # HTTPS outbound only
      }
    ]
  })
end
```

## Performance Tuning

### High-Throughput Configuration

```ruby
# Optimized for high-throughput broadcasting
aws_media_live_channel(:high_perf_channel, {
  name: "high-performance-broadcast",
  channel_class: "STANDARD",
  encoder_settings: {
    video_descriptions: [
      {
        name: "optimized_video",
        codec_settings: {
          h264_settings: {
            # Performance-optimized settings
            adaptive_quantization: "HIGH",
            look_ahead_rate_control: "HIGH",
            quality_level: "ENHANCED_QUALITY",
            spatial_aq: "ENABLED",
            temporal_aq: "ENABLED",
            flicker_aq: "ENABLED",
            # Buffer management
            buf_size: 3000000,
            buf_fill_pct: 90,
            # GOP optimization
            gop_b_reference: "ENABLED",
            gop_num_b_frames: 3,
            gop_closed_cadence: 1,
            # Advanced features
            entropy_encoding: "CABAC",
            num_ref_frames: 3,
            scene_change_detect: "ENABLED"
          }
        }
      }
    ],
    global_configuration: {
      output_timing_source: "INPUT_CLOCK",
      output_locking_mode: "EPOCH_LOCKING",
      input_loss_behavior: {
        black_frame_msec: 0,
        repeat_frame_msec: 0,
        input_loss_image_type: "COLOR"
      }
    }
  }
  # Other configuration...
})
```

This implementation provides enterprise-grade MediaLive channel management with comprehensive encoding options, advanced features, and operational best practices for professional broadcasting workflows.