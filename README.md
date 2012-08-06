# GOV.UK vagrant base boxes

This repository contains [VeeWee][vw] scripts for building virtual machines for the GOV.UK environment.

[vw]: https://github.com/jedi4ever/veewee/

## Install

    gem install vagrant veewee

## Usage

    # Build and export the box
    vagrant basebox build govuk_dev_lucid64
    vagrant basebox verify govuk_dev_lucid64 # Expect 1 error, as we don't install chef-client
    vagrant basebox export govuk_dev_lucid64

    # Upload the box to GDS S3 (assuming you've set up s3cmd)
    s3cmd sync --acl-public govuk_dev_lucid64.box 's3://gds-boxes/govuk_dev_lucid64.box'
