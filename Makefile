pipeline: pipeline.json
	fly -t hh set-pipeline \
	  -p concourse-charts \
	  -c $^

pipeline.json: ./refs.json ./pipeline.jsonnet
	@jsonnet \
		--ext-code 'branches=$(shell cat ./refs.json)' \
		./pipeline.jsonnet > $@

