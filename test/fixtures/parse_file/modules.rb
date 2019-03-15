module Main
  def main_func; end

  module MainModule
    def module_func; end

    def MainModule.module_class_func; end
  end

  class Cls
    module ClsModule
      def cls_module_func; end
    end
  end
end
puts DATA.read
__END__
[
  {
    "name": "Main",
    "location": "$FIXTURE_DIR/modules.rb:1",
    "type": "class",
    "children": [
      {
        "name": "main_func",
        "location": "$FIXTURE_DIR/modules.rb:2",
        "type": "function",
        "static": false
      },
      {
        "name": "MainModule",
        "location": "$FIXTURE_DIR/modules.rb:4",
        "type": "class",
        "children": [
          {
            "name": "module_func",
            "location": "$FIXTURE_DIR/modules.rb:5",
            "type": "function",
            "static": false
          },
          {
            "name": "module_class_func",
            "location": "$FIXTURE_DIR/modules.rb:7",
            "type": "function",
            "static": true
          }
        ]
      },
      {
        "name": "Cls",
        "location": "$FIXTURE_DIR/modules.rb:10",
        "type": "class",
        "children": [
          {
            "name": "ClsModule",
            "location": "$FIXTURE_DIR/modules.rb:11",
            "type": "class",
            "children": [
              {
                "name": "cls_module_func",
                "location": "$FIXTURE_DIR/modules.rb:12",
                "type": "function",
                "static": false
              }
            ]
          }
        ]
      }
    ]
  }
]
