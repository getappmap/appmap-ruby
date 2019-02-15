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
    "children": [
      {
        "name": "main_func",
        "location": "$FIXTURE_DIR/modules.rb:2",
        "type": "function",
        "class_name": "Main",
        "static": false
      },
      {
        "name": "MainModule",
        "location": "$FIXTURE_DIR/modules.rb:4",
        "children": [
          {
            "name": "module_func",
            "location": "$FIXTURE_DIR/modules.rb:5",
            "type": "function",
            "class_name": "Main::MainModule",
            "static": false
          },
          {
            "name": "module_class_func",
            "location": "$FIXTURE_DIR/modules.rb:7",
            "type": "function",
            "class_name": "Main::MainModule",
            "static": true
          }
        ],
        "type": "class"
      },
      {
        "name": "Cls",
        "location": "$FIXTURE_DIR/modules.rb:10",
        "children": [
          {
            "name": "ClsModule",
            "location": "$FIXTURE_DIR/modules.rb:11",
            "children": [
              {
                "name": "cls_module_func",
                "location": "$FIXTURE_DIR/modules.rb:12",
                "type": "function",
                "class_name": "Main::Cls::ClsModule",
                "static": false
              }
            ],
            "type": "class"
          }
        ],
        "type": "class"
      }
    ],
    "type": "class"
  }
]
