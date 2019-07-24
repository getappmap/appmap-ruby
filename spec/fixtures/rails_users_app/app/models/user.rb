UserStruct = Struct.new(:login, :password)

class User < UserStruct
  def valid?
    !login.blank? && !password.blank?
  end
end
