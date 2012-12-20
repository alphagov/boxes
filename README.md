# GOV.UK vagrant base boxes

This repository contains [VeeWee][vw] scripts for building virtual machines for the GOV.UK environment.

[vw]: https://github.com/jedi4ever/veewee/

## Install

    bundle install

## Usage

    # Build the lucid box
    make lucid
    
    # Upload the box to GDS S3 (assuming you've set up s3cmd)
    make sync-lucid

    # Build and sync all boxes
    make sync
