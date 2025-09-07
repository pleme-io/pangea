# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Complete Gaming Infrastructure with GameLift, GameSparks, Sumerian AR/VR, and GameDev
# Demonstrates multiplayer game hosting, matchmaking, AR/VR content delivery, and game development workflows

require 'pangea'

template :gamelift_multiplayer_hosting do
  provider :aws do
    region "us-east-1"
  end

  # GameLift Build for game server executable
  build = aws_gamelift_build(:mygame_build, {
    name: "MyGame Server Build",
    version: "1.0.0",
    storage_location: {
      bucket: "my-gamelift-builds",
      key: "builds/mygame-server-1.0.0.zip",
      role_arn: "arn:aws:iam::123456789012:role/GameLiftRole"
    },
    operating_system: "AMAZON_LINUX_2",
    tags: {
      Game: "MyGame",
      Environment: "production"
    }
  })

  # GameLift Script for Realtime Servers
  script = aws_gamelift_script(:mygame_script, {
    name: "MyGame Realtime Script",
    version: "1.0",
    storage_location: {
      bucket: "my-gamelift-scripts",
      key: "scripts/mygame-realtime-1.0.js"
    },
    tags: {
      Game: "MyGame",
      Type: "Realtime"
    }
  })

  # GameLift Fleet for hosting game sessions
  fleet = aws_gamelift_fleet(:mygame_fleet, {
    name: "MyGame Production Fleet",
    description: "Production fleet for MyGame multiplayer sessions",
    build_id: build.id,
    ec2_instance_type: "c5.large",
    fleet_type: "ON_DEMAND",
    min_size: 2,
    max_size: 10,
    desired_ec2_instances: 4,
    new_game_session_protection_policy: "FullProtection",
    runtime_configuration: {
      server_processes: [{
        launch_path: "/local/game/MyGameServer.exe",
        parameters: "--port=7777",
        concurrent_executions: 1
      }]
    },
    tags: {
      Game: "MyGame",
      Environment: "production"
    }
  })

  # GameLift Fleet Locations for multi-region deployment
  aws_gamelift_fleet_locations(:mygame_fleet_locations, {
    fleet_id: fleet.id,
    locations: ["us-west-2", "eu-west-1", "ap-southeast-1"]
  })

  # GameLift Fleet Capacity management
  aws_gamelift_fleet_capacity(:mygame_fleet_capacity_uswest, {
    fleet_id: fleet.id,
    desired_instances: 2,
    location: "us-west-2"
  })

  # GameLift Alias for fleet abstraction
  alias_ref = aws_gamelift_alias(:mygame_alias, {
    name: "MyGame Production",
    description: "Production alias for MyGame fleet",
    routing_strategy: {
      type: "SIMPLE",
      fleet_id: fleet.id
    },
    tags: {
      Game: "MyGame",
      Environment: "production"
    }
  })

  # GameLift Matchmaking Rule Set
  rule_set = aws_gamelift_matchmaking_rule_set(:mygame_rules, {
    name: "MyGameMatchmakingRules",
    rule_set_body: JSON.pretty_generate({
      name: "MyGameMatchmakingRuleSet",
      ruleLanguageVersion: "1.0",
      playerAttributes: [{
        name: "skill",
        type: "number",
        default: 10
      }],
      teams: [{
        name: "team",
        maxPlayers: 8,
        minPlayers: 4
      }],
      rules: [{
        name: "EqualTeamSizes",
        description: "Make teams equal size",
        type: "comparison",
        measurements: ["flatten(teams[*].players.count)"],
        referenceValue: "max(measurements[*])",
        maxDistance: 1
      }]
    }),
    tags: {
      Game: "MyGame",
      Version: "1.0"
    }
  })

  # GameLift Matchmaking Configuration
  aws_gamelift_matchmaking_configuration(:mygame_matchmaking, {
    name: "MyGameMatchmaking",
    description: "Matchmaking configuration for MyGame",
    game_session_queue_arns: [
      "arn:aws:gamelift:us-east-1:123456789012:gamesessionqueue/MyGameQueue"
    ],
    request_timeout_seconds: 60,
    acceptance_timeout_seconds: 30,
    acceptance_required: true,
    rule_set_name: rule_set.name,
    additional_player_count: 0,
    custom_event_data: "MyGame_v1.0",
    game_properties: [{
      key: "gameMode",
      value: "ranked"
    }],
    tags: {
      Game: "MyGame",
      Type: "Ranked"
    }
  })

  # GameLift Game Session Queue
  aws_gamelift_game_session_queue(:mygame_queue, {
    name: "MyGameQueue",
    timeout_in_seconds: 300,
    destinations: [{
      destination_arn: fleet.arn
    }],
    player_latency_policies: [{
      maximum_individual_player_latency_milliseconds: 100,
      policy_duration_seconds: 60
    }],
    tags: {
      Game: "MyGame",
      Environment: "production"
    }
  })

  # GameLift Compute for GameLift Anywhere
  aws_gamelift_compute(:mygame_compute, {
    compute_name: "MyGameCompute01",
    fleet_id: fleet.id,
    ip_address: "10.0.1.100",
    dns_name: "mygame-compute-01.local"
  })

  # Output important values
  output :fleet_id do
    value fleet.id
    description "GameLift Fleet ID for MyGame"
  end

  output :alias_id do
    value alias_ref.id
    description "GameLift Alias ID for MyGame"
  end

  output :matchmaking_configuration do
    value "MyGameMatchmaking"
    description "Matchmaking configuration name"
  end
end

template :gamesparks_backend do
  provider :aws do
    region "us-east-1"
  end

  # GameSparks Game
  game = aws_gamesparks_game(:mygame, {
    name: "MyGame",
    description: "A multiplayer action game with real-time features",
    tags: {
      Game: "MyGame",
      Version: "1.0"
    }
  })

  # GameSparks Stage for development
  dev_stage = aws_gamesparks_stage(:mygame_dev, {
    game_name: game.name,
    stage_name: "development",
    description: "Development stage for MyGame",
    tags: {
      Environment: "development"
    }
  })

  # GameSparks Stage for production
  prod_stage = aws_gamesparks_stage(:mygame_prod, {
    game_name: game.name,
    stage_name: "production",
    description: "Production stage for MyGame",
    tags: {
      Environment: "production"
    }
  })

  # GameSparks Extension for player management
  player_extension = aws_gamesparks_extension(:player_manager, {
    namespace: "com.mygame.player",
    name: "PlayerManager",
    description: "Player management extension",
    extension_version: "1.0"
  })

  # GameSparks Configuration for game settings
  aws_gamesparks_configuration(:mygame_config, {
    game_name: game.name,
    stage_name: prod_stage.stage_name,
    sections: {
      gameSettings: {
        maxPlayersPerMatch: 8,
        matchDurationMinutes: 15,
        enableRanking: true
      },
      serverSettings: {
        region: "us-east-1",
        instanceType: "c5.large"
      }
    }
  })

  # GameSparks Snapshot for version control
  aws_gamesparks_snapshot(:mygame_v1_0, {
    game_name: game.name,
    description: "MyGame version 1.0 snapshot"
  })

  output :game_arn do
    value game.arn
    description "GameSparks Game ARN"
  end

  output :dev_stage_endpoint do
    value dev_stage.endpoint
    description "Development stage endpoint"
  end

  output :prod_stage_endpoint do
    value prod_stage.endpoint
    description "Production stage endpoint"
  end
end

template :sumerian_arvr_content do
  provider :aws do
    region "us-east-1"
  end

  # Sumerian Project for AR/VR content
  project = aws_sumerian_project(:mygame_arvr, {
    name: "MyGame AR/VR Experience",
    description: "Augmented and Virtual Reality content for MyGame",
    template: "augmented_reality",
    tags: {
      Game: "MyGame",
      Type: "AR/VR"
    }
  })

  # Sumerian Scene for AR gameplay
  ar_scene = aws_sumerian_scene(:ar_gameplay, {
    project_name: project.name,
    scene_name: "ARGameplayScene",
    description: "Main AR gameplay scene with 3D models and interactions",
    tags: {
      SceneType: "AR",
      Version: "1.0"
    }
  })

  # Sumerian Scene for VR lobby
  vr_scene = aws_sumerian_scene(:vr_lobby, {
    project_name: project.name,
    scene_name: "VRLobbyScene",
    description: "Virtual reality lobby for player interaction",
    tags: {
      SceneType: "VR",
      Version: "1.0"
    }
  })

  # Sumerian Asset for 3D character models
  character_asset = aws_sumerian_asset(:character_models, {
    project_name: project.name,
    asset_name: "CharacterModels",
    asset_type: "model",
    description: "3D character models for AR/VR scenes",
    tags: {
      AssetType: "Character",
      Format: "GLTF"
    }
  })

  # Sumerian Asset for environment textures
  environment_asset = aws_sumerian_asset(:environment_textures, {
    project_name: project.name,
    asset_name: "EnvironmentTextures",
    asset_type: "texture",
    description: "High-resolution environment textures",
    tags: {
      AssetType: "Environment",
      Resolution: "4K"
    }
  })

  # Sumerian Bundle for game assets
  asset_bundle = aws_sumerian_bundle(:game_assets, {
    project_name: project.name,
    bundle_name: "MyGameAssetBundle",
    asset_ids: [character_asset.asset_id, environment_asset.asset_id],
    description: "Complete asset bundle for MyGame AR/VR experience",
    tags: {
      BundleType: "Game",
      Version: "1.0"
    }
  })

  # Sumerian Host for AI-powered virtual characters
  virtual_host = aws_sumerian_host(:game_host, {
    project_name: project.name,
    host_name: "MyGameHost",
    host_configuration: {
      voice: "Joanna",
      language: "en-US",
      gesture_pack: "default"
    },
    polly_config: {
      voice_id: "Joanna",
      output_format: "mp3",
      sample_rate: "16000"
    },
    tags: {
      HostType: "GameGuide",
      Version: "1.0"
    }
  })

  # Sumerian Published Scene for AR experience
  aws_sumerian_published_scene(:ar_published, {
    project_name: project.name,
    scene_name: ar_scene.scene_name,
    version: "1.0",
    description: "Published AR gameplay scene for mobile devices",
    access_policy: "public"
  })

  output :project_id do
    value project.project_id
    description "Sumerian Project ID"
  end

  output :ar_scene_url do
    value ar_scene.url
    description "AR Scene URL for mobile integration"
  end

  output :vr_scene_url do
    value vr_scene.url
    description "VR Scene URL for VR headsets"
  end

  output :asset_bundle_url do
    value asset_bundle.url
    description "Asset bundle URL for CDN delivery"
  end
end

template :gamedev_pipeline do
  provider :aws do
    region "us-east-1"
  end

  # GameDev Project for development workflow
  dev_project = aws_gamedeveloper_project(:mygame_dev, {
    name: "MyGameDevelopment",
    description: "Development project for MyGame with CI/CD pipeline",
    game_engine: "unity",
    repository_url: "https://github.com/mygame/mygame-unity",
    tags: {
      Game: "MyGame",
      Engine: "Unity"
    }
  })

  # GameDev Stage for development builds
  dev_stage = aws_gamedeveloper_stage(:dev_builds, {
    project_name: dev_project.name,
    stage_name: "development",
    description: "Development stage for automated builds and testing",
    stage_configuration: {
      build_config: "Debug",
      auto_deploy: true,
      run_tests: true
    },
    tags: {
      Environment: "development"
    }
  })

  # GameDev Stage for production releases
  prod_stage = aws_gamedeveloper_stage(:prod_releases, {
    project_name: dev_project.name,
    stage_name: "production",
    description: "Production stage for release builds",
    stage_configuration: {
      build_config: "Release",
      auto_deploy: false,
      approval_required: true
    },
    tags: {
      Environment: "production"
    }
  })

  # GameDev Extension for Unity Cloud Build integration
  unity_extension = aws_gamedeveloper_extension(:unity_cloudbuild, {
    project_name: dev_project.name,
    extension_name: "UnityCloudBuild",
    extension_configuration: {
      api_key: "unity_api_key_placeholder",
      project_id: "unity_project_id",
      build_target: "standalone"
    },
    tags: {
      Extension: "Unity",
      Type: "CloudBuild"
    }
  })

  # GameDev Snapshot for version control
  aws_gamedeveloper_snapshot(:v1_0_snapshot, {
    project_name: dev_project.name,
    description: "MyGame version 1.0 development snapshot",
    source_version: "v1.0.0"
  })

  # GameDev Deployment for automated deployment
  aws_gamedeveloper_deployment(:dev_deployment, {
    project_name: dev_project.name,
    stage_name: dev_stage.stage_name,
    source_version: "main",
    deployment_configuration: {
      build_timeout: 30,
      test_timeout: 15,
      deploy_to_staging: true
    }
  })

  output :dev_project_id do
    value dev_project.project_id
    description "GameDev Project ID"
  end

  output :dev_stage_role do
    value dev_stage.role
    description "Development stage IAM role"
  end

  output :prod_stage_role do
    value prod_stage.role
    description "Production stage IAM role"
  end
end