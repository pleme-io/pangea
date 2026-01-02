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

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_athena_named_query/resource'

RSpec.describe "aws_athena_named_query synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "test_query",
          database: "test_database",
          query: "SELECT * FROM test_table LIMIT 10"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_athena_named_query")
      expect(result["resource"]["aws_athena_named_query"]).to have_key("test")
    end

    it "includes required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "daily_summary",
          database: "analytics",
          query: "SELECT date, COUNT(*) as total FROM events GROUP BY date"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["database"]).to eq("analytics")
      expect(query_config["query"]).to include("SELECT")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "documented_query",
          database: "analytics",
          query: "SELECT * FROM users LIMIT 100",
          description: "Query to fetch sample users"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["description"]).to eq("Query to fetch sample users")
    end

    it "includes workgroup when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "workgroup_query",
          database: "analytics",
          query: "SELECT * FROM logs",
          workgroup: "analytics_workgroup"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["workgroup"]).to eq("analytics_workgroup")
    end

    it "defaults workgroup to primary" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "default_workgroup_query",
          database: "analytics",
          query: "SELECT * FROM data"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["workgroup"]).to eq("primary")
    end

    it "supports complex queries with CTEs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "cte_query",
          database: "analytics",
          query: <<~SQL
            WITH daily_counts AS (
              SELECT date, COUNT(*) as cnt FROM events GROUP BY date
            )
            SELECT * FROM daily_counts WHERE cnt > 100
          SQL
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["query"]).to include("WITH")
      expect(query_config["query"]).to include("SELECT")
    end

    it "supports DDL queries" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "create_table_query",
          database: "analytics",
          query: <<~SQL
            CREATE EXTERNAL TABLE IF NOT EXISTS events (
              id BIGINT,
              name STRING,
              created_at TIMESTAMP
            )
            LOCATION 's3://bucket/data/'
          SQL
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["query"]).to include("CREATE EXTERNAL TABLE")
    end

    it "supports aggregation queries" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "aggregation_query",
          database: "analytics",
          query: <<~SQL
            SELECT
              date,
              COUNT(*) as total,
              SUM(amount) as total_amount,
              AVG(amount) as avg_amount
            FROM transactions
            GROUP BY date
            HAVING COUNT(*) > 10
          SQL
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_athena_named_query"]["test"]

      expect(query_config["query"]).to include("COUNT")
      expect(query_config["query"]).to include("SUM")
      expect(query_config["query"]).to include("GROUP BY")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_named_query(:test, {
          name: "valid_query",
          database: "valid_db",
          query: "SELECT 1"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_named_query"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_named_query"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "ref_test_query",
          database: "test_db",
          query: "SELECT * FROM test"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_athena_named_query.test.id}")
    end

    it "returns computed properties for SELECT queries" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "select_query",
          database: "test_db",
          query: "SELECT * FROM users WHERE active = true"
        })
      end

      expect(ref.computed_properties[:is_select_query]).to eq(true)
      expect(ref.computed_properties[:is_ddl_query]).to eq(false)
      expect(ref.computed_properties[:query_type]).to eq("SELECT")
    end

    it "returns computed properties for DDL queries" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "ddl_query",
          database: "test_db",
          query: "CREATE TABLE new_table (id INT)"
        })
      end

      expect(ref.computed_properties[:is_ddl_query]).to eq(true)
      expect(ref.computed_properties[:is_select_query]).to eq(false)
      expect(ref.computed_properties[:query_type]).to eq("CREATE_TABLE")
    end

    it "returns computed properties for aggregation queries" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "agg_query",
          database: "test_db",
          query: "SELECT date, COUNT(*) FROM events GROUP BY date"
        })
      end

      expect(ref.computed_properties[:uses_aggregations]).to eq(true)
    end

    it "returns computed properties for partition-aware queries" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "partition_query",
          database: "test_db",
          query: "SELECT * FROM events WHERE year = '2024' AND month = '01'"
        })
      end

      expect(ref.computed_properties[:uses_partitions]).to eq(true)
    end

    it "returns query complexity score" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "complex_query",
          database: "test_db",
          query: <<~SQL
            SELECT
              a.id,
              b.name,
              ROW_NUMBER() OVER (PARTITION BY a.type ORDER BY a.created_at) as rn
            FROM table_a a
            JOIN table_b b ON a.id = b.a_id
            WHERE a.year = '2024'
            GROUP BY a.id, b.name
            ORDER BY a.id
          SQL
        })
      end

      expect(ref.computed_properties[:query_complexity_score]).to be > 1.0
      expect(ref.computed_properties[:uses_window_functions]).to eq(true)
    end

    it "returns documentation for queries" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_named_query(:test, {
          name: "documented_query",
          database: "analytics",
          query: "SELECT * FROM events",
          description: "Fetch all events"
        })
      end

      expect(ref.computed_properties[:documentation]).to be_a(String)
      expect(ref.computed_properties[:documentation]).to include("documented_query")
    end
  end
end
