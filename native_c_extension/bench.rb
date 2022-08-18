require 'date'
require 'net/http'
require 'net/http/generic_request'
require 'tabulate'

# load custom Ruby implementation of to_s
load 'ruby_custom_to_s.rb'

# load custom C    implementation of to_s
require Dir.getwd + '/ccustomtos'
include CCustomToS

def generate_many_times(value, num_times)
  ret = []
  num_times.times do
    ret.append(value)
  end
  return ret
end

data_nil = nil
data_true = true
data_false = false
data_int = 5
data_float = 5.5
data_time = Time.now
data_date = Date.today
data_sym = :some_symbol
data_str_8   = "12345678"
data_str_16  = "1234567890123456"
data_str_32  = "12345678901234567890123456789012"
data_str_64  = "1234567890123456789012345678901234567890123456789012345678901234"
data_str_128 = "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678"
data_str_16376 = "1" * 16376 # stringifying this used to crash
data_file = File.new("bench_file", "w")
data_net_http = Net::HTTP.new('example.com')
data_net_httpgenericrequest = Net::HTTPGenericRequest.new('m', 'request_body', 'response_body', 'example.com')
data_hash = {
  1 => "one",
  2 => "two",
  3 => "three",
  4 => "four"
}
data_array_int = [ 10, 20, 30, 40 ]
data_array_int_more_than_max = generate_many_times(1, 15)
data_array_float = [ 1.5, 2.5, 3.5, 4.5 ]
data_array_float_more_than_max = generate_many_times(1.5, 15)
data_array_str8 = [ data_str_8, data_str_8, data_str_8, data_str_8 ]
data_array_str8_more_than_max = generate_many_times( data_str_8, 15)
data_array_mix = [10, 2.5, nil, "some string", true, false ]
data_array_hash = [ data_hash, data_hash, data_hash, data_hash ]
data_array_hash_more_than_max = generate_many_times(data_hash, 15)
data_array_file = [ data_file, data_file, data_file, data_file ]

# number of benchmark iterations
n = 100000

def benchmark_to_s(n, data_name, data)
  time_start = Time.now
  n.times do
    data.to_s # use Ruby's .to_s
  end
  time_stop = Time.now
  time_diff_milliseconds = (time_stop - time_start) * 1000
  time_diff_milliseconds
end

def benchmark_ruby_custom_to_s(n, data_name, data)
  time_start = Time.now
  n.times do
    ruby_custom_to_s(data) # use custom stringify algorithm in Ruby
  end
  time_stop = Time.now
  time_diff_milliseconds = (time_stop - time_start) * 1000
  time_diff_milliseconds
end

def benchmark_c_custom_to_s(n, data_name, data)
  time_start = Time.now
  n.times do
    c_custom_to_s(data) # use custom stringify algorithm in C
  end
  time_stop = Time.now
  time_diff_milliseconds = (time_stop - time_start) * 1000
  time_diff_milliseconds
end

symbols = [
  :data_nil,
  :data_true,
  :data_false,
  :data_int,
  :data_float,
  # :data_time,
  # :data_date,
  :data_sym,
  :data_str_8,
  :data_str_16,
  :data_str_32,
  :data_str_64,
  :data_str_128,
  :data_str_16376,
  # :data_file,
  # :data_net_http,
  # :data_net_httpgenericrequest,
  :data_hash,
  :data_array_int,
  :data_array_int_more_than_max,
  :data_array_float,
  :data_array_float_more_than_max,  
  :data_array_str8,
  :data_array_str8_more_than_max,
  :data_array_mix,
  :data_array_hash,
  :data_array_hash_more_than_max,
  # :data_array_file,
]


puts "======================================================================="
puts "Verifying all implementations are functionally equivalent"
symbols.each do |symbol|
  puts "---------------------------------------------------------------------"
  data = eval(symbol.to_s)
  ruby = data.to_s
  ruby_custom = ruby_custom_to_s(data)
  c_custom = c_custom_to_s(data)
  if (ruby == ruby_custom and
      ruby_custom == c_custom)
    puts "PASS verifying #{symbol}"
  else
    puts "FAIL verifying #{symbol}"
    puts ruby
    puts ruby_custom
    puts c_custom
  end
end

puts "======================================================================="

times = {
  "to_s" => {},
  "ruby_custom_to_s" => {},
  "c_custom_to_s" => {},
}

puts "Benchmark with Ruby's .to_s"
symbols.each do |symbol|
  time_diff = benchmark_to_s(n, symbol.to_s, eval(symbol.to_s))
  times["to_s"][symbol.to_s] = { "time_diff" => time_diff }
end


puts "Benchmark with custom .to_s in Ruby"
symbols.each do |symbol|
  time_diff = benchmark_ruby_custom_to_s(n, symbol.to_s, eval(symbol.to_s))
  times["ruby_custom_to_s"][symbol.to_s] = { "time_diff" => time_diff }  
end

puts "Benchmark with custom .to_s in C"
symbols.each do |symbol|
  time_diff = benchmark_c_custom_to_s(n, symbol.to_s, eval(symbol.to_s))
  times["c_custom_to_s"][symbol.to_s] = { "time_diff" => time_diff }
end

# show absolute times
puts ""
puts "Performance for #{n} iterations"
times_output = []
times["to_s"].keys().each do |symbol_str|
  ruby_to_s = times["to_s"][symbol_str]["time_diff"]
  ruby_custom_to_s = times["ruby_custom_to_s"][symbol_str]["time_diff"]
  c_custom_to_s = times["c_custom_to_s"][symbol_str]["time_diff"]
  times_output.append([symbol_str, ruby_to_s.round(2), ruby_custom_to_s.round(2), c_custom_to_s.round(2)])
end
puts tabulate(["symbol", "Ruby .to_s", "ruby_custom_to_s", "c_custom_to_s"],
              times_output,
              :indent => 4,
              :style => 'legacy')

# show performance difference
puts ""
puts "Performance difference for #{n} iterations (higher is better)"
times_output = []
times["to_s"].keys().each do |symbol_str|
  ruby_custom_to_s_factor = times["to_s"][symbol_str]["time_diff"] / times["ruby_custom_to_s"][symbol_str]["time_diff"]
  c_custom_to_s_factor = times["to_s"][symbol_str]["time_diff"] / times["c_custom_to_s"][symbol_str]["time_diff"]
  times_output.append([symbol_str, 1, ruby_custom_to_s_factor.round(2), c_custom_to_s_factor.round(2)])
end
puts tabulate(["symbol", "Ruby .to_s", "ruby_custom_to_s", "c_custom_to_s"],
              times_output,
              :indent => 4,
              :style => 'legacy')
