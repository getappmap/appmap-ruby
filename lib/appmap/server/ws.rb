require 'sinatra/base'
require 'appmap'
require 'appmap/inspector'
require 'appmap/config'
require 'appmap/scenario'

class AppMapServer < Sinatra::Base
  set :bind, '0.0.0.0'
  set :server, :webrick

  SCENARIO_PATH = ".appmap/scenarios"

  before do
    headers 'Access-Control-Allow-Origin' => '*'
  end

  helpers do
    def serve_json
      headers 'Content-Type' => 'application/json'
    end

    def expand_scenairo(fname)
      File.join(SCENARIO_PATH, fname)
    end
  end

  get '/map' do
    serve_json
    config = AppMap::Config.load_from_file('.appmap.yml')
    JSON.pretty_generate config.map(&AppMap::Inspector.method(:detect_features))
  end

  get '/scenarios' do
    serve_json
    files = Dir.new(SCENARIO_PATH).entries.select do |fname|
      ::File.file?(expand_scenairo(fname)) &&
        !::File.symlink?(expand_scenairo(fname))
    end.map do |fname|
      File.new(expand_scenairo(fname))
    end
    result = files.map do |file|
      {
        path: file.path[SCENARIO_PATH.length+1..-1]
      }
    end
    JSON.pretty_generate result
  end

  get '/scenarios/:id' do
    File.read(expand_scenairo(params[:id]))
  end
end
