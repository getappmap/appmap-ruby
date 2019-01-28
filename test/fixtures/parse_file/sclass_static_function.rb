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
      "kind": "method",
      "class_name": "Main",
      "static": true
    },
    {
      "name": "main_sclass_func_1",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:19",
      "kind": "method",
      "class_name": "Main2",
      "static": true
    },
    {
      "name": "main_sclass_func_2",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:23",
      "kind": "method",
      "class_name": "Main2",
      "static": true
    }
  ],
  "implicit": [
    {
      "name": "Main",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:8",
      "children": [
        {
          "name": "main_sclass_func_1",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:11",
          "kind": "method",
          "class_name": "Main",
          "static": true
        }
      ],
      "kind": "class"
    },
    {
      "name": "Main2",
      "location": "$FIXTURE_DIR/sclass_static_function.rb:16",
      "children": [
        {
          "name": "main_sclass_func_1",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:19",
          "kind": "method",
          "class_name": "Main2",
          "static": true
        },
        {
          "name": "main_sclass_func_2",
          "location": "$FIXTURE_DIR/sclass_static_function.rb:23",
          "kind": "method",
          "class_name": "Main2",
          "static": true
        }
      ],
      "kind": "class"
    }
  ]
}
