# Makefile for jenkins-nvm-plugin.
#
# Author:: Greg Albrecht <gba@onbeep.com>
# Copyright:: Copyright 2013 OnBeep, Inc.
# License:: Apache License, Version 2.0
# Source:: https://github.com/OnBeep/jenkins-nvm-plugin
#


all: bundle bundle_install jpi_build

bundle:
	bundle

bundle_install:
	bundle install

build: jpi_build

jpi_build:
	jpi build

clean:
	rm -rf pkg
