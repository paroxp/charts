# maintenance

This branch is responsible for:

- keeping [`merged` branch](https://github.com/concourse/charts/tree/merged) up to date with the branches that represent Concourse contributions to [upstream](https://github.com/helm/charts) that either didn't get merge yet or can't be submitted because they belong to release candidates; and
- automatically updating our hosted Helm repository (see [gh-pages](https://github.com/concourse/charts/tree/gh-pages)).


## Using

If you have push access:

    ./update-merged-branch.sh

For documentation around the script, checkout the comments in the script itself.


## Updating the list of branches

Both `update-merged-branch` and the pipeline (generated via `jsonnet`) have as their source the file `./refs.json`.

To update that, include an entry in the JSON that describes where such branch can be found.
