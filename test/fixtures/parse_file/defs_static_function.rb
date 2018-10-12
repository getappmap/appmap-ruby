  class Main
    # @appmap
    def Main.main_func
    end
  end

class Sub < Main
  # @appmap
  def Main.sub_func
  end
end

puts DATA.read
__END__
[
  {
    "name": "main_func",
    "location": "$FIXTURE_DIR/defs_static_function.rb:3",
    "kind": "method",
    "class_name": "Main",
    "static": true
  },
  {
    "name": "sub_func",
    "location": "$FIXTURE_DIR/defs_static_function.rb:9",
    "kind": "method",
    "class_name": "Main",
    "static": true
  }
]
