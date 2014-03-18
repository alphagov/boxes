VEEWEE = bundle exec veewee vbox
VERSION := $(shell date +'%Y%m%d')

all: lucid precise

lucid: govuk_dev_lucid64_$(VERSION).box

govuk_dev_lucid64_$(VERSION).box: govuk_dev_lucid64.box
	cp -p govuk_dev_lucid64.box govuk_dev_lucid64_$(VERSION).box

govuk_dev_lucid64.box: definitions/govuk_dev_lucid64/*
	$(VEEWEE) build -f govuk_dev_lucid64
	$(VEEWEE) export -f govuk_dev_lucid64

precise: govuk_dev_precise64_$(VERSION).box

govuk_dev_precise64_$(VERSION).box: govuk_dev_precise64.box
	cp -p govuk_dev_precise64.box govuk_dev_precise64_$(VERSION).box

govuk_dev_precise64.box: definitions/govuk_dev_precise64/*
	$(VEEWEE) build -f govuk_dev_precise64
	$(VEEWEE) export -f govuk_dev_precise64

clean:
	$(VEEWEE) destroy -f govuk_dev_lucid64
	$(VEEWEE) destroy -f govuk_dev_precise64
	rm -f *.box

sync-lucid: lucid 
	s3cmd sync --acl-public govuk_dev_lucid64_$(VERSION).box 's3://gds-boxes/'

sync-precise: precise
	s3cmd sync --acl-public govuk_dev_precise64_$(VERSION).box 's3://gds-boxes/'

sync: sync-lucid sync-precise
