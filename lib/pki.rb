require 'openssl'
require 'base64'

def get_pair(hash, what)
  p12_s, p12_pass = hash.values_at("#{what}_pkcs12", "#{what}_passphrase")
  key_s, cert_s = hash.values_at("#{what}_key", "#{what}_cert")

  if p12_s && p12_pass
    p12_d = File.exist?(p12_s) ? OpenSSL::PKCS12.new(File.read(p12_s), p12_pass) : OpenSSL::PKCS12.new(p12_s, p12_pass)
    LOG.info("[pkcs12] #{what}.cert: #{p12_d.certificate.subject}")
    return [p12_d.key, p12_d.certificate]
  elsif key_s && cert_s
    # Try base64 decoding strings
    key_s = key_s.start_with?('LS0t') ? Base64.strict_decode64(key_s) : key_s
    cert_s = cert_s.start_with?('LS0t') ? Base64.strict_decode64(cert_s) : cert_s

    key_d = File.exist?(key_s) ? File.read(key_s) : key_s
    cert_d = File.exist?(cert_s) ? File.read(cert_s) : cert_s
    key = OpenSSL::PKey.read(key_d)
    cert = OpenSSL::X509::Certificate.new(cert_d)
    LOG.info("[inline] #{what}.cert: #{cert.subject}")
    return [key, cert]
  else
    LOG.error("Bad keypair definition for '#{what}'")
    abort
  end
rescue StandardError => e
  LOG.error("PKI error for #{what}: #{e}")
  abort
end
