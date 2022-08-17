MAX_ARRAY_ENUMERATION = 10
MAX_HASH_ENUMERATION = 10
MAX_STRING_LENGTH = 100

def ruby_custom_to_s(value)
  case value
  when NilClass, TrueClass, FalseClass, Numeric, Time, Date
    value.to_s
  when Symbol
    ":#{value}"
  when String    
    result = value[0...MAX_STRING_LENGTH].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
    result << " (...#{value.length - MAX_STRING_LENGTH} more characters)" if value.length > MAX_STRING_LENGTH
    result
  when Array
    result = value[0...MAX_ARRAY_ENUMERATION].map{|v| ruby_custom_to_s(v)}.join(', ')
    result << " (...#{value.length - MAX_ARRAY_ENUMERATION} more items)" if value.length > MAX_ARRAY_ENUMERATION
[ '[', result, ']' ].join
  when Hash
    result = value.keys[0...MAX_HASH_ENUMERATION].map{|key| "#{ruby_custom_to_s(key)}=>#{ruby_custom_to_s(value[key])}"}.join(', ')
    result << " (...#{value.size - MAX_HASH_ENUMERATION} more entries)" if value.size > MAX_HASH_ENUMERATION
    [ '{', result, '}' ].join
  when File
    "#{value.class}[path=#{value.path}]"
  when Net::HTTP
    "#{value.class}[#{value.address}:#{value.port}]"
  when Net::HTTPGenericRequest
    "#{value.class}[#{value.method} #{value.path}]"
  end
end
