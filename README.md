# GOV.UK vagrant base boxes

This repository contains [VeeWee][vw] scripts for building virtual machines for the GOV.UK environment.

[vw]: https://github.com/jedi4ever/veewee/

## Install

    bundle install

## Usage

    # Build and export the box
    bundle exec vagrant basebox build govuk_dev_lucid64
    bundle exec vagrant basebox validate govuk_dev_lucid64 # Expect 1 error, as we don't install chef-client
    bundle exec vagrant basebox export govuk_dev_lucid64

    # Upload the box to GDS S3 (assuming you've set up s3cmd)
    s3cmd sync --acl-public govuk_dev_lucid64.box 's3://gds-boxes/govuk_dev_lucid64.box'
