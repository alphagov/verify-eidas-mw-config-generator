# eIDAS German Middleware Config Generator

The [middleware](https://github.com/Governikus/eidas-middleware) provided by Germany for their eIDAS scheme requires a set of PKI and config files. The `generate` script consumes a config definition and produces the following files required by the middleware:

* SSL keypair in PKCS12 format
* POSeIDAS.xml containing the TLS keypair and middleware server URL
* SAML keypairs in Java Keystore (JKS) format
* application.properties and eidasmiddleware.properties defining server parameters

Merging changes into the master repository triggers a build on the Jenkins project `eidas-mw-config-generator`.

This build in turn creates a docker hub image using the `eidas-mw-config-generator-upload-to-dockerhub` Jenkins project.

The nightly roll of the German Middleware uses this image to create the runtime configuration, using [verify-terraform/modules/eidas_mw/cloud-init](https://github.com/alphagov/verify-terraform/tree/master/modules/eidas_mw/cloud-init) config.

## Requirements

* Docker
* docker-compose
* rbenv

## Usage

A sample config definition can be found in `test/config.yml`.

    gem install bundler
    bundle
    ./generate <config definition> <output dir>
    
## Testing

The config generator can be tested against the actual German middleware by running `./pre-commit.sh`.

