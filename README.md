# This repository is no longer maintained

The code here is no longer used or maintained.

At the time it was retired, in November 2014, this code was known to work. We
have retired this repo as its contents have been merged with an internal
repository in a bid to simplify the way that we create VM templates, such that
we can create VMware and Vagrant templates from the same configuration.

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
    s3cmd sync --acl-public govuk_dev_precise64_$(date "+%Y%m%d").box 's3://gds-boxes/'
