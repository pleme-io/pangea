# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        class SfnStateMachineAttributes
          # Common state machine pattern builders
          module Builders
            extend self

            def simple_task_definition(task_arn, next_state = nil)
              state = { "Type" => "Task", "Resource" => task_arn }
              state[next_state ? "Next" : "End"] = next_state || true
              JSON.pretty_generate({
                "Comment" => "Simple task state machine",
                "StartAt" => "Task",
                "States" => { "Task" => state }
              })
            end

            def sequential_tasks_definition(tasks)
              states = {}
              tasks.each_with_index do |(name, resource), index|
                state = { "Type" => "Task", "Resource" => resource }
                if index < tasks.size - 1
                  state["Next"] = tasks[index + 1][0]
                else
                  state["End"] = true
                end
                states[name] = state
              end
              JSON.pretty_generate({
                "Comment" => "Sequential tasks state machine",
                "StartAt" => tasks.first[0],
                "States" => states
              })
            end

            def parallel_tasks_definition(branches)
              parallel_branches = branches.map do |_branch_name, tasks|
                {
                  "StartAt" => tasks.first[0],
                  "States" => tasks.each_with_object({}) do |(name, resource), states|
                    states[name] = { "Type" => "Task", "Resource" => resource, "End" => true }
                  end
                }
              end
              JSON.pretty_generate({
                "Comment" => "Parallel tasks state machine",
                "StartAt" => "Parallel",
                "States" => {
                  "Parallel" => { "Type" => "Parallel", "Branches" => parallel_branches, "End" => true }
                }
              })
            end

            def choice_definition(choices, default_state)
              choice_rules = choices.map do |condition, next_state|
                { "Variable" => condition[:variable], condition[:operator] => condition[:value], "Next" => next_state }
              end
              JSON.pretty_generate({
                "Comment" => "Choice state machine",
                "StartAt" => "Choice",
                "States" => { "Choice" => { "Type" => "Choice", "Choices" => choice_rules, "Default" => default_state } }
              })
            end

            def cloudwatch_logging(log_group_arn, level = "ERROR", include_execution_data = false)
              {
                level: level,
                include_execution_data: include_execution_data,
                destinations: [{ cloud_watch_logs_log_group: { log_group_arn: log_group_arn } }]
              }
            end

            def enable_xray_tracing = { enabled: true }
            def disable_tracing = { enabled: false }
          end
        end
      end
    end
  end
end
