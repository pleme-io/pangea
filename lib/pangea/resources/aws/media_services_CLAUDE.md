# AWS Media Services Resources

This document provides comprehensive coverage of AWS Media Services resources implemented in Pangea, focusing on video streaming, live broadcasting, content packaging, and media processing workflows.

## Resource Coverage

### AWS Elemental MediaLive (5/15 core resources)
Live video processing and broadcasting infrastructure:

**Core Resources:**
- ✅ `aws_medialive_channel` - Live video processing channels
- ✅ `aws_medialive_input` - Input sources for streaming  
- ✅ `aws_medialive_input_security_group` - Access control for inputs
- ✅ `aws_medialive_multiplex` - Multiple stream combining
- ✅ `aws_medialive_multiplex_program` - Individual multiplex programs

**Extended Resources (Future Implementation):**
- `aws_medialive_reservation` - Reserved capacity management
- `aws_medialive_offering` - Available reservation offerings
- `aws_medialive_channel_schedule` - Scheduled channel operations
- `aws_medialive_input_attachment` - Input-to-channel attachments
- `aws_medialive_channel_encoder_settings` - Detailed encoder configurations
- `aws_medialive_channel_output_settings` - Output format specifications
- `aws_medialive_channel_input_specification` - Input format requirements
- `aws_medialive_multiplex_settings` - Advanced multiplex configurations
- `aws_medialive_channel_availability_zone` - AZ-specific channel settings
- `aws_medialive_channel_pipeline_detail` - Pipeline status and metrics

### AWS Elemental MediaPackage (4/12 core resources)
Video streaming and packaging services:

**Core Resources:**
- ✅ `aws_mediapackage_channel` - Stream ingestion channels
- ✅ `aws_mediapackage_origin_endpoint` - Content distribution endpoints
- ✅ `aws_mediapackage_packaging_configuration` - VOD packaging settings
- ✅ `aws_mediapackage_packaging_group` - Configuration groupings

**Extended Resources (Future Implementation):**
- `aws_mediapackage_configuration` - Service configurations
- `aws_mediapackage_harvest_job` - Content harvesting jobs
- `aws_mediapackage_asset` - VOD content assets
- `aws_mediapackage_channel_policy` - Channel access policies
- `aws_mediapackage_origin_endpoint_policy` - Endpoint access policies
- `aws_mediapackage_channel_harvest_job` - Channel-specific harvest jobs
- `aws_mediapackage_channel_ingest_endpoint` - Ingestion endpoint details
- `aws_mediapackage_channel_egress_endpoint` - Distribution endpoint details

### AWS Kinesis Video Streams (2/8 core resources)
Video streaming infrastructure:

**Core Resources:**
- ✅ `aws_kinesisvideo_stream` - Video stream management
- ✅ `aws_kinesisvideo_signaling_channel` - WebRTC signaling

**Extended Resources (Future Implementation):**
- `aws_kinesisvideo_stream_consumer` - Stream data consumers
- `aws_kinesisvideo_archived_media` - Archived video data
- `aws_kinesisvideo_media` - Live media data access
- `aws_kinesisvideo_webrtc_signaling` - WebRTC communication
- `aws_kinesisvideo_edge_configuration` - Edge device configurations
- `aws_kinesisvideo_notification_configuration` - Event notifications

### AWS Elemental MediaConvert (4/10 core resources)
Video transcoding and processing:

**Core Resources:**
- ✅ `aws_mediaconvert_job_template` - Reusable transcoding templates
- ✅ `aws_mediaconvert_preset` - Output encoding settings
- ✅ `aws_mediaconvert_queue` - Job processing queues
- ✅ `aws_mediaconvert_job` - Transcoding jobs

**Extended Resources (Future Implementation):**
- `aws_mediaconvert_job_settings` - Detailed job configurations
- `aws_mediaconvert_output_group` - Output grouping settings
- `aws_mediaconvert_input` - Input source specifications
- `aws_mediaconvert_output` - Individual output settings
- `aws_mediaconvert_acceleration_settings` - Hardware acceleration
- `aws_mediaconvert_reservation` - Reserved transcoding capacity

## Architecture Patterns

### Live Streaming Workflow
```ruby
template :live_streaming_platform do
  # Input security for stream access control
  security_group = aws_medialive_input_security_group(:stream_security, {
    whitelist_rules: [
      { cidr: "10.0.0.0/8" },
      { cidr: "172.16.0.0/12" }
    ]
  })

  # RTMP input for live stream ingestion
  live_input = aws_medialive_input(:live_rtmp_input, {
    name: "Live RTMP Input",
    type: "RTMP_PUSH",
    input_security_groups: [security_group.id],
    destinations: [
      { stream_name: "live-stream-primary" },
      { stream_name: "live-stream-backup" }
    ]
  })

  # MediaPackage channel for stream packaging
  package_channel = aws_mediapackage_channel(:live_channel, {
    channel_id: "live-streaming-channel",
    description: "Live streaming content packaging"
  })

  # MediaLive channel for live processing
  live_channel = aws_medialive_channel(:live_processing, {
    name: "Live Processing Channel",
    channel_class: "SINGLE_PIPELINE",
    input_attachments: [{
      input_attachment_name: "primary-input",
      input_id: live_input.id
    }],
    destinations: [{
      id: "mediapackage-destination",
      media_package_settings: [{
        channel_id: package_channel.id
      }]
    }],
    encoder_settings: {
      # Video encoding for multiple bitrates
      video_descriptions: [{
        name: "video_1080p",
        codec_settings: {
          h264_settings: {
            bitrate: 5000000,
            framerate_numerator: 30,
            framerate_denominator: 1,
            gop_size: 60,
            profile: "HIGH"
          }
        },
        height: 1080,
        width: 1920
      }, {
        name: "video_720p",
        codec_settings: {
          h264_settings: {
            bitrate: 3000000,
            framerate_numerator: 30,
            framerate_denominator: 1,
            gop_size: 60,
            profile: "HIGH"
          }
        },
        height: 720,
        width: 1280
      }],
      # Audio encoding settings
      audio_descriptions: [{
        name: "audio_aac",
        codec_settings: {
          aac_settings: {
            bitrate: 128000,
            coding_mode: "CODING_MODE_2_0",
            sample_rate: 48000
          }
        }
      }],
      # Output configuration for adaptive bitrate
      output_groups: [{
        output_group_settings: {
          media_package_group_settings: {
            destination: {
              destination_ref_id: "mediapackage-destination"
            }
          }
        },
        outputs: [{
          output_name: "output_1080p",
          video_description_name: "video_1080p",
          audio_description_names: ["audio_aac"]
        }, {
          output_name: "output_720p", 
          video_description_name: "video_720p",
          audio_description_names: ["audio_aac"]
        }]
      }],
      timecode_config: {
        source: "EMBEDDED"
      }
    }
  })

  # HLS origin endpoint for video playback
  hls_endpoint = aws_mediapackage_origin_endpoint(:hls_playback, {
    endpoint_id: "hls-playback-endpoint",
    channel_id: package_channel.id,
    hls_package: {
      segment_duration_seconds: 6,
      playlist_window_seconds: 60,
      ad_markers: "SCTE35_ENHANCED",
      include_iframe_only_stream: true,
      stream_selection: {
        stream_order: "VIDEO_BITRATE_DESCENDING"
      }
    }
  })

  # DASH origin endpoint for alternative playback
  dash_endpoint = aws_mediapackage_origin_endpoint(:dash_playback, {
    endpoint_id: "dash-playback-endpoint", 
    channel_id: package_channel.id,
    dash_package: {
      segment_duration_seconds: 30,
      manifest_window_seconds: 300,
      min_buffer_time_seconds: 30,
      profile: "NONE",
      stream_selection: {
        stream_order: "VIDEO_BITRATE_DESCENDING"  
      }
    }
  })
end
```

### Video-on-Demand Processing Pipeline
```ruby
template :vod_transcoding_pipeline do
  # MediaConvert queue for job processing
  processing_queue = aws_mediaconvert_queue(:vod_processing, {
    name: "VOD Processing Queue",
    description: "Queue for video-on-demand transcoding jobs",
    pricing_plan: "ON_DEMAND",
    status: "ACTIVE"
  })

  # Preset for high-quality H.264 output
  h264_preset = aws_mediaconvert_preset(:h264_high_quality, {
    name: "H264 High Quality Preset",
    category: "Video",
    description: "High-quality H.264 encoding preset",
    settings: {
      video_description: {
        codec_settings: {
          codec: "H_264",
          h264_settings: {
            bitrate: 8000000,
            codec_profile: "HIGH",
            framerate_control: "SPECIFIED",
            framerate_numerator: 30,
            framerate_denominator: 1,
            gop_size: 60,
            rate_control_mode: "CBR"
          }
        },
        width: 1920,
        height: 1080
      },
      audio_descriptions: [{
        codec_settings: {
          codec: "AAC",
          aac_settings: {
            bitrate: 128000,
            coding_mode: "CODING_MODE_2_0",
            sample_rate: 48000
          }
        }
      }],
      container_settings: {
        container: "MP4"
      }
    }
  })

  # Job template for consistent processing
  vod_template = aws_mediaconvert_job_template(:vod_template, {
    name: "VOD Processing Template",
    category: "VOD",
    description: "Standard template for VOD content processing",
    settings: {
      inputs: [{
        timecode_source: "EMBEDDED",
        video_selector: {
          color_space: "FOLLOW"
        }
      }],
      output_groups: [{
        name: "File Group",
        output_group_settings: {
          type: "FILE_GROUP_SETTINGS",
          file_group_settings: {
            destination: "s3://vod-output-bucket/processed/"
          }
        },
        outputs: [{
          preset: h264_preset.name,
          name_modifier: "_processed"
        }]
      }],
      timecode_config: {
        source: "EMBEDDED"
      }
    },
    queue: processing_queue.name,
    priority: 0
  })

  # MediaPackage packaging group for VOD content
  packaging_group = aws_mediapackage_packaging_group(:vod_packaging, {
    packaging_group_id: "vod-content-packaging"
  })

  # HLS packaging configuration
  hls_packaging = aws_mediapackage_packaging_configuration(:hls_vod, {
    packaging_configuration_id: "hls-vod-config",
    packaging_group_id: packaging_group.id,
    hls_package: {
      hls_manifests: [{
        ad_markers: "NONE",
        include_iframe_only_stream: false,
        repeat_ext_x_key: true,
        stream_selection: {
          stream_order: "ORIGINAL"
        }
      }],
      segment_duration_seconds: 6,
      use_audio_rendition_group: false
    }
  })

  # DASH packaging configuration  
  dash_packaging = aws_mediapackage_packaging_configuration(:dash_vod, {
    packaging_configuration_id: "dash-vod-config", 
    packaging_group_id: packaging_group.id,
    dash_package: {
      dash_manifests: [{
        manifest_layout: "FULL",
        profile: "NONE",
        stream_selection: {
          stream_order: "ORIGINAL"
        }
      }],
      segment_duration_seconds: 30,
      segment_template_format: "NUMBER_WITH_TIMELINE"
    }
  })
end
```

### WebRTC Video Communication
```ruby
template :webrtc_communication do
  # Kinesis Video signaling channel for WebRTC
  webrtc_signaling = aws_kinesisvideo_signaling_channel(:webrtc_signal, {
    name: "WebRTC Signaling Channel",
    type: "SINGLE_MASTER",
    message_ttl_seconds: 60
  })

  # Kinesis Video stream for recording
  recording_stream = aws_kinesisvideo_stream(:call_recording, {
    name: "WebRTC Call Recording",
    data_retention_in_hours: 24,
    media_type: "video/h264"
  })

  output :signaling_channel_arn do
    value webrtc_signaling.arn
  end

  output :recording_stream_arn do
    value recording_stream.arn
  end
end
```

### Multi-Channel Broadcasting
```ruby  
template :multi_channel_broadcast do
  # Shared input security group
  broadcast_security = aws_medialive_input_security_group(:broadcast_security, {
    whitelist_rules: [
      { cidr: "0.0.0.0/0" }  # Allow all for public broadcast
    ]
  })

  # Multiple input sources
  primary_input = aws_medialive_input(:primary_feed, {
    name: "Primary Broadcast Feed",
    type: "RTMP_PUSH", 
    input_security_groups: [broadcast_security.id],
    destinations: [{ stream_name: "primary-broadcast" }]
  })

  backup_input = aws_medialive_input(:backup_feed, {
    name: "Backup Broadcast Feed",
    type: "RTMP_PUSH",
    input_security_groups: [broadcast_security.id], 
    destinations: [{ stream_name: "backup-broadcast" }]
  })

  # Multiplex for combining streams
  broadcast_multiplex = aws_medialive_multiplex(:broadcast_mux, {
    name: "Broadcast Multiplex",
    availability_zones: ["us-east-1a", "us-east-1b"],
    multiplex_settings: {
      transport_stream_bitrate: 10000000,
      transport_stream_id: 1,
      transport_stream_reserved_bitrate: 1000000
    }
  })

  # Multiplex programs for different channels
  sports_program = aws_medialive_multiplex_program(:sports_channel, {
    multiplex_id: broadcast_multiplex.id,
    program_name: "Sports Channel",
    multiplex_program_settings: {
      program_number: 1,
      service_descriptor: {
        provider_name: "Sports Network",
        service_name: "Live Sports"
      }
    }
  })

  news_program = aws_medialive_multiplex_program(:news_channel, {
    multiplex_id: broadcast_multiplex.id,
    program_name: "News Channel", 
    multiplex_program_settings: {
      program_number: 2,
      service_descriptor: {
        provider_name: "News Network",
        service_name: "Breaking News"
      }
    }
  })
end
```

## Key Features

### Type Safety & Validation
- **Dry-Struct Attributes**: Runtime validation of all resource configurations
- **Enum Constraints**: Strict validation of codec settings, streaming formats, and quality levels
- **Schema Validation**: Complex nested structures for encoder settings and packaging configurations
- **Reference Types**: Type-safe resource references between MediaLive, MediaPackage, and MediaConvert

### Streaming Protocols Support
- **HLS (HTTP Live Streaming)**: Adaptive bitrate streaming with segment-based delivery
- **DASH (Dynamic Adaptive Streaming)**: International standard for adaptive streaming
- **RTMP**: Real-time messaging protocol for live stream ingestion
- **WebRTC**: Real-time peer-to-peer communication
- **Microsoft Smooth Streaming**: Legacy streaming format support

### Encoding & Processing
- **Multi-Codec Support**: H.264, H.265/HEVC, AV1, MPEG-2 video codecs
- **Audio Codecs**: AAC, AC-3, EAC-3, MP2, MP3, Opus, Vorbis
- **Adaptive Bitrate**: Multiple quality tiers for optimal streaming experience
- **Hardware Acceleration**: GPU-accelerated transcoding for improved performance

### Security & Access Control
- **Input Security Groups**: IP-based access control for streaming inputs
- **Content Encryption**: DRM and AES encryption for secure content delivery
- **IAM Integration**: Fine-grained access control using AWS IAM roles and policies
- **VPC Integration**: Private network deployment for secure media workflows

### Monitoring & Operations
- **CloudWatch Integration**: Comprehensive metrics and logging for all media services
- **Status Tracking**: Real-time status monitoring for channels, streams, and jobs
- **Error Handling**: Automatic failover and error recovery mechanisms
- **Resource Tagging**: Organized resource management and cost allocation

## Best Practices

### Live Streaming Architecture
1. **Input Redundancy**: Always configure backup inputs for production streams
2. **Multi-AZ Deployment**: Use multiple availability zones for high availability
3. **Adaptive Bitrate**: Provide multiple quality levels for different network conditions
4. **Content Delivery**: Use CloudFront with MediaPackage for global distribution

### Video Processing Optimization
1. **Queue Management**: Use separate queues for different priority levels
2. **Template Standardization**: Create reusable job templates for consistent processing
3. **Preset Optimization**: Fine-tune encoding presets for quality vs. file size balance
4. **Batch Processing**: Group similar jobs for improved resource utilization

### Cost Optimization
1. **Reserved Capacity**: Use MediaConvert reserved slots for predictable workloads
2. **Queue Prioritization**: Implement priority-based job scheduling
3. **Format Selection**: Choose appropriate streaming formats based on target devices
4. **Storage Lifecycle**: Implement S3 lifecycle policies for processed content

### Security Implementation
1. **Network Isolation**: Deploy media services within private VPCs
2. **Encryption at Rest**: Enable encryption for all stored media content
3. **Secure Streaming**: Implement DRM for premium content protection
4. **Access Logging**: Enable comprehensive access logging for compliance

This implementation provides a comprehensive foundation for AWS Media Services in Pangea, enabling sophisticated video streaming, live broadcasting, and media processing workflows with type safety and enterprise-grade features.