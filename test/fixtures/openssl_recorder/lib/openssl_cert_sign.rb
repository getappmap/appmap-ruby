# frozen_string_literal: true

# From the manual page https://ruby-doc.org/stdlib-2.5.1/libdoc/openssl/rdoc/OpenSSL.html

require 'openssl'

module Example
  def Example.sign
    ca_key = OpenSSL::PKey::RSA.new 2048
    pass_phrase = 'my secure pass phrase goes here'

    cipher = OpenSSL::Cipher.new 'AES-256-CBC'

    open 'tmp/ca_key.pem', 'w', 0644 do |io|
      io.write ca_key.export(cipher, pass_phrase)
    end

    ca_name = OpenSSL::X509::Name.parse '/CN=ca/DC=example'

    ca_cert = OpenSSL::X509::Certificate.new
    ca_cert.serial = 0
    ca_cert.version = 2
    ca_cert.not_before = Time.now
    ca_cert.not_after = Time.now + 86400

    ca_cert.public_key = ca_key.public_key
    ca_cert.subject = ca_name
    ca_cert.issuer = ca_name

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = ca_cert
    extension_factory.issuer_certificate = ca_cert

    ca_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')
    ca_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:TRUE', true)

    ca_cert.add_extension    extension_factory.create_extension(
      'keyUsage', 'cRLSign,keyCertSign', true)

    ca_cert.sign ca_key, OpenSSL::Digest::SHA1.new

    open 'tmp/ca_cert.pem', 'w' do |io|
      io.write ca_cert.to_pem
    end

    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = OpenSSL::X509::Name.new([ ['CN', 'the name to sign', OpenSSL::ASN1::UTF8STRING] ])
    csr.public_key = ca_key.public_key
    csr.sign ca_key, OpenSSL::Digest::SHA1.new

    open 'tmp/csr.pem', 'w' do |io|
      io.write csr.to_pem
    end

    csr = OpenSSL::X509::Request.new File.read 'tmp/csr.pem'

    raise 'CSR can not be verified' unless csr.verify csr.public_key

    csr_cert = OpenSSL::X509::Certificate.new
    csr_cert.serial = 0
    csr_cert.version = 2
    csr_cert.not_before = Time.now
    csr_cert.not_after = Time.now + 600

    csr_cert.subject = csr.subject
    csr_cert.public_key = csr.public_key
    csr_cert.issuer = ca_cert.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = csr_cert
    extension_factory.issuer_certificate = ca_cert

    csr_cert.add_extension    extension_factory.create_extension('basicConstraints', 'CA:FALSE')

    csr_cert.add_extension    extension_factory.create_extension(
        'keyUsage', 'keyEncipherment,dataEncipherment,digitalSignature')

    csr_cert.add_extension    extension_factory.create_extension('subjectKeyIdentifier', 'hash')

    csr_cert.sign ca_key, OpenSSL::Digest::SHA1.new

    'tmp/csr_cert.pem'.tap do |fname|
      open fname, 'w' do |io|
        io.write csr_cert.to_pem
      end
    end
  end
end

if __FILE__ == $0
  cert_file = Example.sign
  puts "Wrote cert file #{cert_file}"
end
