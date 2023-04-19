# A Continuous Deployment Setup using Watchtower and GitHub Actions

This is a template and basic guide to setting up
a [watchtower](https://containrrr.dev/watchtower/) service
and GitHub actions to enable continuous deployment (CD)
for a set of containers on a server.

> I quickly created this repo and guide by taking pieces from some of my projects.
> Please enter issues or submit PR if you find any errors or have suggestions.

## Setting up your server

### watchtower service

1. Clone this repo (or copy the files from it as desired)
2. Copy `.env.template` as `.env`
3. Edit `.env` to set the relevant variables
4. Run `docker-compose up -d`

NOTE: Alternatively, you can of course just incorporate the settings
and `watchtower` service spec in your existing `docker-compose.yml` file
or other mechanism that launches your containers.

### Proxy-pass

As appropriate to your practices, add a proxy-pass to your webserver to
expose the watchtower service, so it can be accessed externally,
in particular from GitHub (see below).

For example, if using Apache:

```apache
<Location /__watchtower__>
  ProxyPass        http://localhost:9901
  ProxyPassReverse http://localhost:9901
</Location>
```

NOTE: Set the `WATCHTOWER_UPDATE_ENDPOINT` variable in `.env` and
corresponding secret at DockerHub, accordingly. 

## Setup on GitHub

### Secrets

Add the following secrets to your repo,
with values consistent to those indicated in the `.env` file:

- `WATCHTOWER_HTTP_API_TOKEN`: the token for the watchtower API.

- `WATCHTOWER_UPDATE_ENDPOINT`: the endpoint for the watchtower service.
  
    > Note: this is not a watchtower setting, but rather a convenience to
    > avoid exposing the actual endpoint in GitHub logs.

### Release workflow

In your repo's workflow (`.github/workflows/release.yml` or equivalent)
that builds and pushes the image(s) to your docker registry,
add a step to trigger the watchtower update operation:

```yaml
- name: Trigger watchtower to update container(s)
  shell: bash
  run: |
    curl -H "Authorization: Bearer ${{ secrets.WATCHTOWER_HTTP_API_TOKEN }}" ${{ secrets.WATCHTOWER_UPDATE_ENDPOINT }}
```

> NOTE: The above assumes a GitHub Actions environment that includes `curl`,
> like `ubuntu`. Adjust the step as needed for your environment.

That's it!

### Additional notes

#### Opt-in

As indicated with the [`--label-enable`](https://containrrr.dev/watchtower/arguments/#filter_by_enable_label)
option for the watchtower command, the base setup here follows an "opt-in" approach: 
only services marked with the `com.centurylinklabs.watchtower.enable=true` label
will be checked for updates. As an example, if "my-service" should be updated:

```yaml
services:
  my-service:
    image: .../my-service:X.Y.Z
    labels:
      - 'com.centurylinklabs.watchtower.enable=true'
    ... 
```

Of course, as with everything, adjust the setup as desired. 

#### Image tagging and update strategy

As a common practice, it is likely that, for a new version `X.Y.Z` of your app,
you are pushing a corresponding tag `vX.Y.Z` to your git repository,
while the corresponding image gets the tag `X.Y.Z`.

If not already, consider also generating the image tags:

- `X.Y`: the major and minor version
- `X`: the major version
- `latest`: the latest version

Then, in your `docker-compose.yml`, indicate the desired "version level" for the CD automated updates,
for example, for every new release with the same major and minor, `X.Y`:

```yaml
services:
  my-service:
    image: .../my-service:X.Y
    labels:
      - 'com.centurylinklabs.watchtower.enable=true'
    ... 
```
