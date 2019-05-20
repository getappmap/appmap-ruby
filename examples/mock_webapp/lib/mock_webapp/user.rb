module MockWebapp
  UserStruct = Struct.new(:login)

  # Mock model object.
  # @appmap
  class User < UserStruct
    USERS = {
      'alice' => User.new('alice')
    }.freeze

    class << self
      # @appmap
      def find(id)
        USERS[id] || raise("No such user #{id}")
      end
    end
  end
end
