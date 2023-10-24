VERSION = 1.4.3
OBJ = src/js/CronPixie.js
SRC = src/elm/CronPixie.elm
SLUG = wp-cron-pixie
ZIP = builds/$(SLUG)-$(VERSION).zip
PLUGIN_BUILD = "https://raw.githubusercontent.com/deliciousbrains/wp-plugin-build/94b5c3ff47cbded11386f8aeaca749a6248010be/plugin-build"

ELM ?= elm
ELMFMT ?= elm-format

$(OBJ): $(SRC)
	$(ELMFMT) src/elm/ --yes
	$(ELM) make $(SRC) --output=$(OBJ)

.PHONY: zip prod publish clean

zip: $(ZIP)

$(ZIP): builds/plugin-build $(OBJ)
	cd ./build-cfg/$(SLUG) && ../../builds/plugin-build $(VERSION)

builds/plugin-build: | builds
	curl -sSL $(PLUGIN_BUILD) -o "builds/plugin-build"
	chmod +x "builds/plugin-build"

builds:
	mkdir "builds"

prod:
	$(ELMFMT) src/elm/ --yes
	$(ELM) make $(SRC) --output=$(OBJ) --optimize

publish: builds/plugin-build prod
	cd ./build-cfg/$(SLUG) && ../../builds/plugin-build $(VERSION) -p

clean:
	# Deliverables and artefacts.
	rm -rf ./builds ./elm-stuff $(OBJ)
	# Legacy deliverables and artefacts.
	rm -rf ./node_modules ./npm-debug.log* ./src/js/build.js
