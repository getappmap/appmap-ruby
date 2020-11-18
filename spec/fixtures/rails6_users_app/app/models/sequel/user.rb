class User < Sequel::Model(:users)
  plugin :secure_password, cost: 12, include_validations: false
  plugin :validation_helpers

  def authenticate(unencrypted)
    # Just be extra sure that empty passwords aren't accepted
    return false if unencrypted.blank? || password.blank?

    super
  end

  def validate
    super

    errors.add :password, 'doesn\'t match confirmation' if password_provided? && password != password_confirmation

    validates_presence %i[login]
  end

  protected

  def password_provided?
    !(password.blank? && password_confirmation.blank?)
  end
end
