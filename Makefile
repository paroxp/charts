pipeline.json: ./refs.json ./pipeline.jsonnet
	@jsonnet \
		--ext-code 'branches=$(shell cat ./refs.json)' \
		./pipeline.jsonnet > $@
