require 'logger'
require 'nokogiri'
require 'open-uri'
require 'securerandom'
require 'yaml'

require_relative 'output'
require_relative 'pki'

LOG = Logger.new(STDOUT)
LOG.level = Logger::INFO

class MiddlewareConfig
  def self.from_yaml_file(file)
    self.new(YAML.load_file(file), File.dirname(File.expand_path(file)))
  end

  def self.from_env_vars(env)
    cfg = env.select { |k,_| k.start_with?('MW_') }.map { |k,v| [k.gsub('MW_', ''), v] }.to_h
    self.new(cfg, __dir__)
  end

  def initialize(cfg, working_dir)
    @cfg = cfg
    @working_dir = working_dir
  end

  def render(output_dir)
    # Random password for keystores
    @cfg['ks_password'] = SecureRandom.hex

    # Fetch connector metadata
    connector_metadata_url = @cfg.fetch('connector_metadata_url')
    begin
      LOG.info("Fetching connector metadata from #{connector_metadata_url}")
      @connector_metadata_raw = open(connector_metadata_url, read_timeout: 10).read
    rescue StandardError => e
      LOG.error("Failed: #{e}")
      abort
    end
   
    # Extract signing cert
    connector_metadata_xml = Nokogiri::XML(@connector_metadata_raw)
    connector_metadata_xml.remove_namespaces!
    connector_metadata_x509 = connector_metadata_xml.css('EntityDescriptor Signature KeyInfo X509Data X509Certificate').text
    @connector_metadata_cert = OpenSSL::X509::Certificate.new(Base64.decode64(connector_metadata_x509))
    LOG.info("Connector metadata signing cert: #{@connector_metadata_cert.subject}")

    Dir.chdir(@working_dir) do |cwd|
      LOG.info("Setting working directory: #{cwd}")

      # User-facing SSL keypair
      ssl_key, ssl_cert = get_pair(@cfg, 'ssl')
      ssl_key_enc = ssl_key.export(OpenSSL::Cipher.new('AES-128-CBC'), @cfg['ks_password'])
      @ssl_p12 = OpenSSL::PKCS12.create(@cfg['ks_password'], 'localhost', ssl_key, ssl_cert)

      # DVCA-facing TLS keypair
      tls_key, tls_cert = get_pair(@cfg, 'dvca_tls')
      @cfg['client_cert'] = tls_cert.to_pem.gsub(/-{5}.+-{5}/, '').gsub("\n", '')
      @cfg['client_key'] = tls_key.to_pem.gsub(/-{5}.+-{5}/, '').gsub("\n", '')
     
      saml_signing_key, saml_signing_cert = get_pair(@cfg, 'saml_signing')
      @saml_signing_p12 = OpenSSL::PKCS12.create(@cfg['ks_password'], 'saml_signing', saml_signing_key, saml_signing_cert)

      saml_crypt_key, saml_crypt_cert = get_pair(@cfg, 'saml_crypt')
      @saml_crypt_p12 = OpenSSL::PKCS12.create(@cfg['ks_password'], 'saml_crypt', saml_crypt_key, saml_crypt_cert)
    end

    LOG.info("Config output to: #{output_dir}")

    if File.directory?(output_dir)
      LOG.warn("#{output_dir} already exists. Overwriting contents.")
    else
      Dir.mkdir(output_dir)
    end

    Dir.chdir(output_dir) do
      # Write signing cert as DER
      File.open('connector_metadata_cert.der', 'wb') { |f| f.print(@connector_metadata_cert.to_der) }

      # Write connector metadata to file in euconfigs/
      Dir.mkdir('euconfigs') unless File.directory?('euconfigs')
      File.open(File.join('euconfigs', 'connector_metadata.xml'), 'w') { |f| f.print(@connector_metadata_raw) }
      
      # Write pkcs12 containing user-facing SSL cert and key
      File.open('ssl.p12', 'wb') { |f| f.print(@ssl_p12.to_der) }

      # Write pkcs12 containing SAML signing cert and key
      File.open('saml_signing.p12', 'wb') { |f| f.print(@saml_signing_p12.to_der) }

      # Write pkcs12 containing SAML crypt cert and key
      File.open('saml_crypt.p12', 'wb') { |f| f.print(@saml_crypt_p12.to_der) }

      # Render config templates
      render_erb('application.properties', @cfg)
      render_erb('eidasmiddleware.properties', @cfg)
      render_erb("POSeIDAS_#{@cfg['which_dvca']}.xml", @cfg, 'POSeIDAS.xml')
    end
  end
end
