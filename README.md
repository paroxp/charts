# Concourse hosted Helm repository

Here you can find the assets served as a Helm repository.

To make use of it, add this branch to your list of helm repositories:

```sh
helm repo add concourse https://raw.githubusercontent.com/concourse/charts/gh-pages
helm repo update
```

Once the repository has been added, you can install Concourse:

```sh
helm install \
        --name myrelease \
        concourse/concourse
```
