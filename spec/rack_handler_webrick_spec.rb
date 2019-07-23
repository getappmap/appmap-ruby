require 'rspec'
require 'net/http'
require 'json'
require 'yaml'
require 'English'

describe 'RackHandlerWebrick' do
  around(:each) do |example|
    FileUtils.mkdir_p tmpdir
    FileUtils.rm_f appmap_json
    container_id = `cd spec/fixtures/users_app && docker run -d -v #{File.absolute_path tmpdir}:/app/tmp -p 9292 appmap-users_app`.strip
    raise 'Failed to start users_app container' unless $CHILD_STATUS.exitstatus == 0

    begin
      start_time = Time.now
      until (cid = `docker ps -q -f id=#{container_id} -f health=healthy`.strip) != '' && container_id.include?(cid)
        $stderr.write '.' if Time.now - start_time > 3
        sleep 0.25
      end
      @container_id = container_id
      example.run
    ensure
      if ENV['NOKILL'] != 'true'
        `docker rm -f #{container_id}`
        warn 'Failed to remove users_app container' unless $CHILD_STATUS.exitstatus == 0
      end
    end
  end

  let(:tmpdir) { 'tmp/spec/RackHandlerWebrick' }
  let(:appmap_json) { File.join(tmpdir, 'appmap.json') }
  let(:users_app_host_and_port) { `docker port #{@container_id} 9292`.strip.split(':') }
  let(:users_app_port) { users_app_host_and_port[1] }

  describe 'POST /users' do
    it 'is created' do
      uri = URI("http://localhost:#{users_app_port}/users")
      res = Net::HTTP.post(uri, { 'login' => 'alice', 'password' => 'foobar' }.to_json)
      expect(res.code.to_i).to eq(201)

      `docker stop #{@container_id}`

      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to include(<<-WEB_REQUEST.strip)
  http_server_request:
    request_method: POST
    path_info: "/users"
    version: HTTP/1.1
      WEB_REQUEST

      expect(appmap).to include(<<-WEB_RESPONSE.strip)
  http_server_response:
    status: 201
      WEB_RESPONSE
    end
  end
end
