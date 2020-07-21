# frozen_string_literal: true

# From the manual page https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL.html

require 'openssl'

module Example
  def Example.sign
    key = OpenSSL::PKey::RSA.new 2048

    document = 'the document'

    digest = OpenSSL::Digest::SHA256.new
    p key.class
    key.sign digest, document
  end
end

if __FILE__ == $0
  signature = Example.sign
  require 'base64'
  puts "Computed signature #{Base64.urlsafe_encode64(signature)}"
end
