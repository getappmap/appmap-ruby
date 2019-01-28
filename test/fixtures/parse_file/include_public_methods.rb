# @appmap include=public_methods
class Main
  class << self
    def sclass_function
    end
  end

  def public_function
  end

  protected

  def protected_function
  end

  def Main.protected_function_2
  end

  def self.protected_function_3
  end

  public

  def public_function_2
  end
end

module Mod
end

# @appmap include=public_methods
class M2
  include Mod

  def public_function_3
  end
end

puts DATA.read
__END__
{
  "explicit": [
    {
      "name": "Main",
      "location": "$FIXTURE_DIR/include_public_methods.rb:2",
      "attributes": {
        "include": "public_methods"
      },
      "children": [
        {
          "name": "public_function",
          "location": "$FIXTURE_DIR/include_public_methods.rb:8",
          "kind": "method",
          "class_name": "Main",
          "static": false
        },
        {
          "name": "public_function_2",
          "location": "$FIXTURE_DIR/include_public_methods.rb:24",
          "kind": "method",
          "class_name": "Main",
          "static": false
        }
      ],
      "kind": "class"
    },
    {
      "name": "M2",
      "location": "$FIXTURE_DIR/include_public_methods.rb:32",
      "attributes": {
        "include": "public_methods"
      },
      "children": [
        {
          "name": "public_function_3",
          "location": "$FIXTURE_DIR/include_public_methods.rb:35",
          "kind": "method",
          "class_name": "M2",
          "static": false
        }
      ],
      "kind": "class"
    }
  ],
  "implicit": [
    {
      "name": "Main",
      "location": "$FIXTURE_DIR/include_public_methods.rb:2",
      "children": [
        {
          "name": "sclass_function",
          "location": "$FIXTURE_DIR/include_public_methods.rb:4",
          "kind": "method",
          "class_name": "Main",
          "static": true
        },
        {
          "name": "public_function",
          "location": "$FIXTURE_DIR/include_public_methods.rb:8",
          "kind": "method",
          "class_name": "Main",
          "static": false
        },
        {
          "name": "public_function_2",
          "location": "$FIXTURE_DIR/include_public_methods.rb:24",
          "kind": "method",
          "class_name": "Main",
          "static": false
        }
      ],
      "kind": "class"
    },
    {
      "name": "M2",
      "location": "$FIXTURE_DIR/include_public_methods.rb:32",
      "children": [
        {
          "name": "public_function_3",
          "location": "$FIXTURE_DIR/include_public_methods.rb:35",
          "kind": "method",
          "class_name": "M2",
          "static": false
        }
      ],
      "kind": "class"
    }
  ]
}
