# frozen_string_literal: true

require 'active_support/core_ext'

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
        attr_accessor :static, :location

        def type
          'function'
        end

        def to_h
          {
            name: name,
            type: type,
            location: location,
            static: static
          }
        end
      end
    end

    class << self
      def build_from_methods(config, methods)
        root = Types::Root.new
        methods.each do |method|
          package = package_for_method(config.packages, method)
          add_function root, package.path, method
        end
        root.children.map(&:to_h)
      end

      protected

      def package_for_method(packages, method)
        location = method.source_location
        location_file, = location
        location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0

        packages.find do |pkg|
          (location_file.index(pkg.path) == 0) &&
            !pkg.exclude.find { |p| location_file.index(p) }
        end or raise "No package found for method #{method}"
      end

      def add_function(root, package_name, method)
        location = method.source_location
        location_file, lineno = location
        location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0

        owner_class_name, static = \
          if method.owner.singleton_class?
            require 'appmap/util'
            [ AppMap::Util.descendant_class(method.owner).name, true ]
          else
            [ method.owner.name, false ]
          end

        object_infos = [
          {
            name: package_name,
            type: 'package'
          }
        ]
        object_infos += owner_class_name.split('::').map do |name|
          {
            name: name,
            type: 'class'
          }
        end
        object_infos << {
          name: method.name,
          type: 'function',
          location: [ location_file, lineno ].join(':'),
          static: static
        }
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

      def class_names_for_method(method, static)
        owner_name, static = \
        if method.owner.singleton_class?
          require 'appmap/util'
          [ AppMap::Util.descendant_class(method.owner).name, '.' ]
        else
          [ method.owner.name, '#' ]
        end
      end
    end
  end
end
