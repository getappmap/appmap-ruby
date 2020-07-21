require 'active_support/security_utils'

class Compare
  def self.compare(s1, s2)
    ActiveSupport::SecurityUtils.secure_compare(s1, s2)
  end
end
