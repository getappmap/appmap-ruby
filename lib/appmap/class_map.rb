# frozen_string_literal: true

module AppMap
  class ClassMap
    module HasChildren
      def self.included(base)
        base.module_eval do
          def children
            @children ||= []
          end
        end
      end
    end

    module Types
      class Root
        include HasChildren
      end

      Package = Struct.new(:name) do
        include HasChildren

        def type
          'package'
        end

        def to_h
          {
            name: name,
            type: type,
            children: children.map(&:to_h)
          }
        end
      end
      Class = Struct.new(:name) do
        include HasChildren

        def type
          'class'
        end

        def to_h
          {
            name: name,
            type: type,
            children: children.map(&:to_h)
          }
        end
      end
      Function = Struct.new(:name) do
        attr_accessor :static, :location, :labels

        def type
          'function'
        end

        def to_h
          {
            name: name,
            type: type,
            location: location,
            static: static,
            labels: labels
          }.delete_if {|k,v| v.nil?}
        end
      end
    end

    class << self
      def build_from_methods(config, methods)
        root = Types::Root.new
        methods.each do |method|
          package = config.package_for_method(method) \
            or raise "No package found for method #{method}"
          add_function root, package, method
        end
        root.children.map(&:to_h)
      end

      protected

      def add_function(root, package, method)
        static = method.static

        object_infos = [
          {
            name: package.path,
            type: 'package'
          }
        ]
        object_infos += method.defined_class.split('::').map do |name|
          {
            name: name,
            type: 'class'
          }
        end
        function_info = {
          name: method.name,
          type: 'function',
          static: static
        }
        location = method.source_location

        function_info[:location] = \
          if location
            location_file, lineno = location
            location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0
            [ location_file, lineno ].join(':')
          else
            [ method.defined_class, static ? '.' : '#', method.name ].join
          end

        function_info[:labels] = package.labels if package.labels
        object_infos << function_info

        parent = root
        object_infos.each do |info|
          parent = find_or_create parent.children, info do
            Types.const_get(info[:type].classify).new(info[:name].to_s).tap do |type|
              info.keys.tap do |keys|
                keys.delete(:name)
                keys.delete(:type)
              end.each do |key|
                type.send "#{key}=", info[key]
              end
            end
          end
        end
      end

      def find_or_create(list, info)
        obj = list.find { |item| item.type == info[:type] && item.name == info[:name] }
        return obj if obj

        yield.tap do |new_obj|
          list << new_obj
        end
      end
    end
  end
end
