VERSION = 1.5.0-dev
OBJ = src/js/ui.js
SRC = src/ui/src/ui.gleam
SLUG = wp-cron-pixie
ZIP = builds/$(SLUG)-$(VERSION).zip
PLUGIN_BUILD = "https://raw.githubusercontent.com/deliciousbrains/wp-plugin-build/94b5c3ff47cbded11386f8aeaca749a6248010be/plugin-build"

GLEAM ?= gleam

$(OBJ): $(SRC)
	cd src/ui; $(GLEAM) run -m esgleam/bundle
	mv src/ui/dist/ui.js $@

.PHONY: zip
zip: $(ZIP)

$(ZIP): builds/plugin-build $(OBJ)
	cd ./build-cfg/$(SLUG) && ../../builds/plugin-build $(VERSION)

builds/plugin-build: | builds
	curl -sSL $(PLUGIN_BUILD) -o "builds/plugin-build"
	chmod +x "builds/plugin-build"

builds:
	mkdir "builds"

.PHONY: publish
publish: builds/plugin-build prod
	cd ./build-cfg/$(SLUG) && ../../builds/plugin-build $(VERSION) -p

.PHONY: clean
clean:
	# Deliverables and artefacts.
	rm -rf ./builds ./src/ui/build ./src/ui/dist $(OBJ)
	# Legacy deliverables and artefacts.
	rm -rf ./node_modules ./npm-debug.log* ./src/js/build.js ./elm-stuff ./src/js/CronPixie.js
