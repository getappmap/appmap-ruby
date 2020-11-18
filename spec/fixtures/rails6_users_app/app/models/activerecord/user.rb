class User < ActiveRecord::Base
  has_secure_password validations: false
  validates_presence_of :login
  validates_confirmation_of :password, if: -> { password_provided? }

  def authenticate(unencrypted)
    # Just be extra sure that empty passwords aren't accepted
    return false if unencrypted.blank? || password.blank?

    super
  end

  protected

  def password_provided?
    !(password.blank? && password_confirmation.blank?)
  end
end
