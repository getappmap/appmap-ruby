require 'test_helper'
require 'appmap/scenario'

class ScenarioTest < Minitest::Test
  include FixtureFile

  def test_toplevel_class
    trace = <<-TRACE
# Crawl github.com/postgres
Crawler::Action::Run.initialize <0.005501>
Crawler::Action::Run#initialize <0.000671>
Crawler::Action::Run#perform
  Crawler::Provider::GitHub#org_repositories
    Crawler::Cache::TTLIgnoringCache#process
      Crawler::Cache::SQLCache#read <0.001168>
      Crawler::Cache::SQLCache#read <0.001272>
      Crawler::Cache::SQLCache#write <0.026589>
    Crawler::Cache::TTLIgnoringCache#process <0.292458>
  Crawler::Provider::GitHub#org_repositories <0.376040>
Crawler::Action::Run#perform <16.409675>
TRACE

    scenario = AppMap::Scenario.parse_rbtrace(trace)


    json = <<-JSON
{
  "calls": [
    {
      "class_name": "Crawler::Action::Run",
      "method_name": "initialize",
      "static": true,
      "depth": 0,
      "elapsed": 0.005501
    },
    {
      "class_name": "Crawler::Action::Run",
      "method_name": "initialize",
      "static": false,
      "depth": 0,
      "elapsed": 0.000671
    },
    {
      "class_name": "Crawler::Action::Run",
      "method_name": "perform",
      "static": false,
      "depth": 0,
      "elapsed": 16.409675,
      "children": [
        {
          "class_name": "Crawler::Provider::GitHub",
          "method_name": "org_repositories",
          "static": false,
          "depth": 1,
          "elapsed": 0.37604,
          "children": [
            {
              "class_name": "Crawler::Cache::TTLIgnoringCache",
              "method_name": "process",
              "static": false,
              "depth": 2,
              "elapsed": 0.292458,
              "children": [
                {
                  "class_name": "Crawler::Cache::SQLCache",
                  "method_name": "read",
                  "static": false,
                  "depth": 3,
                  "elapsed": 0.001168
                },
                {
                  "class_name": "Crawler::Cache::SQLCache",
                  "method_name": "read",
                  "static": false,
                  "depth": 3,
                  "elapsed": 0.001272
                },
                {
                  "class_name": "Crawler::Cache::SQLCache",
                  "method_name": "write",
                  "static": false,
                  "depth": 3,
                  "elapsed": 0.026589
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
    JSON

    assert_equal json.strip, JSON.pretty_generate(scenario)
  end
end
