# frozen_string_literal: true

# From the manual page https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL.html

require 'openssl'

module Example
  def Example.encrypt
    cipher = OpenSSL::Cipher.new 'AES-256-CBC'
    cipher.encrypt
    iv = cipher.random_iv

    pwd = 'some hopefully not to easily guessable password'
    salt = OpenSSL::Random.random_bytes 16
    iter = 20000
    key_len = cipher.key_len
    digest = OpenSSL::Digest::SHA256.new

    key = OpenSSL::PKCS5.pbkdf2_hmac(pwd, salt, iter, key_len, digest)
    cipher.key = key

    document = 'the document'

    encrypted = cipher.update document
    encrypted << cipher.final
    encrypted
  end
end

if __FILE__ == $0
  ciphertext = Example.encrypt
  require 'base64'
  puts "Computed ciphertext #{Base64.urlsafe_encode64(ciphertext)}"
end
