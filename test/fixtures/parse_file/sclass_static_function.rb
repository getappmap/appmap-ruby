obj = Object.new
class << obj
  # @appmap
  def object_sclass_func
  end
end

class Main
  class << self
    # @appmap
    def main_sclass_func_1
    end
  end
end

class Main2
  class << self
    # @appmap
    def main_sclass_func_1
    end

    # @appmap
    def main_sclass_func_2
    end
  end
end

puts DATA.read
__END__
{
  "explicit": [
    {
      "name": "main_sclass_func_1",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:11",
      "type": "function",
      "class_name": "Main",
      "static": true
    },
    {
      "name": "main_sclass_func_1",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:19",
      "type": "function",
      "class_name": "Main2",
      "static": true
    },
    {
      "name": "main_sclass_func_2",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:23",
      "type": "function",
      "class_name": "Main2",
      "static": true
    }
  ],
  "implicit": [
    {
      "name": "Main",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:8",
      "type": "class",
      "children": [
        {
          "name": "main_sclass_func_1",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:11",
          "type": "function",
          "static": true
        }
      ]
    },
    {
      "name": "Main2",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:16",
      "type": "class",
      "children": [
        {
          "name": "main_sclass_func_1",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:19",
          "type": "function",
          "static": true
        },
        {
          "name": "main_sclass_func_2",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:23",
          "type": "function",
          "static": true
        }
      ]
    }
  ]
}
