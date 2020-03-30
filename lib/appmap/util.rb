# frozen_string_literal: true

module AppMap
  class Util
    class << self
      # See: https://apidock.com/rails/Class/descendants
      def descendant_class(cls)
        descendants = []
        ObjectSpace.each_object(cls) do |k|
          next if k.singleton_class?

          descendants.unshift k unless k == self
        end
        descendants.first || cls
      end
    end
  end
end
