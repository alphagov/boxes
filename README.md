# GOV.UK Vagrant base boxes

This repository contains [Packer] templates for building virtual machines for the GOV.UK environment.

Currently supports:

  - Ubuntu Precise LTS
  - Ubuntu Trusty LTS

On the following hypervisors:

  - VirtualBox
  - VMware Fusion

[packer]: http://www.packer.io

## Install

    brew tap homebrew/binary
    brew install packer

## Usage

    # Build all the boxes (currently Ubuntu Precise and Trusty for Virtualbox and VMWare Fusion)
    packer build template.json

    # Upload the box to GOV.UK's Amazon S3 bucket (assuming you've set up s3cmd)
    s3cmd sync --acl-public example.box 's3://gds-boxes/'
