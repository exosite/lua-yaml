SAMPLES_IN = $(wildcard samples/*.yaml)
SAMPLES_OUT = $(SAMPLES_IN:.yaml=.lua)

all: test

samples/%.lua: samples/%.yaml yaml.lua parser.lua
	lua parser.lua -- $< > $@


clean:
	-rm $(SAMPLES_OUT)

.PHONY: samples
samples: $(SAMPLES_OUT)

.PHONY: test
test:
	busted && luacheck yaml.lua
