class Main
  # @appmap
  def self.main_func; end
end

class Sub < Main
  # @appmap
  def self.sub_func; end

  # @appmap
  def Main.sub_func_2; end

  # @appmap
  def self.sub_func_3; end

  protected

  # TODO: ensure that this is ignored by implicit scan
  def self.sub_func_protected; end
end

puts DATA.read
__END__
{
  "explicit": [
    {
      "name": "main_func",
      "location": "$FIXTURE_DIR/defs_static_function.rb:3",
      "kind": "method",
      "class_name": "Main",
      "static": true
    },
    {
      "name": "sub_func",
      "location": "$FIXTURE_DIR/defs_static_function.rb:8",
      "kind": "method",
      "class_name": "Sub",
      "static": true
    },
    {
      "name": "sub_func_2",
      "location": "$FIXTURE_DIR/defs_static_function.rb:11",
      "kind": "method",
      "class_name": "Main",
      "static": true
    },
    {
      "name": "sub_func_3",
      "location": "$FIXTURE_DIR/defs_static_function.rb:14",
      "kind": "method",
      "class_name": "Sub",
      "static": true
    }
  ],
  "implicit": [
    {
      "name": "Main",
      "location": "$FIXTURE_DIR/defs_static_function.rb:1",
      "children": [
        {
          "name": "main_func",
          "location": "$FIXTURE_DIR/defs_static_function.rb:3",
          "kind": "method",
          "class_name": "Main",
          "static": true
        }
      ],
      "kind": "class"
    },
    {
      "name": "Sub",
      "location": "$FIXTURE_DIR/defs_static_function.rb:6",
      "children": [
        {
          "name": "sub_func",
          "location": "$FIXTURE_DIR/defs_static_function.rb:8",
          "kind": "method",
          "class_name": "Sub",
          "static": true
        },
        {
          "name": "sub_func_2",
          "location": "$FIXTURE_DIR/defs_static_function.rb:11",
          "kind": "method",
          "class_name": "Main",
          "static": true
        },
        {
          "name": "sub_func_3",
          "location": "$FIXTURE_DIR/defs_static_function.rb:14",
          "kind": "method",
          "class_name": "Sub",
          "static": true
        }
      ],
      "kind": "class"
    }
  ]
}
