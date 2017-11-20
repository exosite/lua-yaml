SAMPLES_IN = $(wildcard samples/*.yaml)
SAMPLES_OUT = $(SAMPLES_IN:.yaml=.json)

all: test

samples/%.json: samples/%.yaml yaml.lua parser.lua
	lua parser.lua -- $< > $@

clean:
	-rm $(SAMPLES_OUT)

.PHONY: test
test: $(SAMPLES_OUT)
