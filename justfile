# This justfile requires https://github.com/casey/just

# Load environment variables from `.env` file.
set dotenv-load
# Fail the script if the env file is not found.
set dotenv-required

project_dir := justfile_directory()
git_commit := `git rev-parse --short HEAD`
docker_tag := "${ELECTRUM_VERSION}"

# print available targetgit_commits
[group("project-agnostic")]
default:
    @just --list --justfile {{justfile()}}

# evaluate and print all just variables
[group("project-agnostic")]
evaluate:
    @just --evaluate

# print system information such as OS and architecture
[group("project-agnostic")]
system-info:
  @echo "architecture: {{arch()}}"
  @echo "os: {{os()}}"
  @echo "os family: {{os_family()}}"


# create a docker image (no cache)
[group("docker")]
docker-build-no-cache:
  @just build `date -u +"%Y-%m-%dT%H:%M:%SZ"`

alias build := docker-build

# create a docker image
[group("docker")]
docker-build build_date='1970-01-01T00:00:00Z':
  @docker build \
    --build-arg BUILD_DATE={{build_date}} \
    --build-arg ELECTRUM_VERSION=${ELECTRUM_VERSION} \
    --build-arg ELECTRUM_CHECKSUM_SHA512=${ELECTRUM_CHECKSUM_SHA512} \
    --build-arg VCS_REF="{{git_commit}}" \
    --tag "${DOCKER_IMAGE_NAME}:{{docker_tag}}" .

# size of the docker image
[group("docker")]
docker-image-size:
    @docker images "$DOCKER_IMAGE_NAME"

[group("docker")]
docker-tag:
  docker tag "${DOCKER_IMAGE_NAME}:{{docker_tag}}" "${DOCKER_IMAGE_NAME}:latest"

# run the docker image
[group("docker")]
docker-run:
    @echo "Running container from docker image ..."
    @docker run \
      --rm \
      --name electrum-daemon \
      --publish "${ELECTRUM_RPCPORT}:${ELECTRUM_RPCPORT}" \
      --env ELECTRUM_NETWORK=${ELECTRUM_NETWORK} \
      --env ELECTRUM_RPCPORT=${ELECTRUM_RPCPORT} \
      "${DOCKER_IMAGE_NAME}:{{docker_tag}}"

# run the docker image and start shell
[group("docker")]
docker-run-shell:
    @echo "Running container from docker image with shell..."
    @docker run \
      --rm \
      --entrypoint="/bin/ash" \
      -it "${DOCKER_IMAGE_NAME}:{{docker_tag}}"

[group("docker")]
docker-compose-up *args='':
  @docker compose up --build {{args}}

[group("docker")]
docker-compose-up-dry-run:
  DRY_RUN=true just docker-compose-up

[group("development")]
info:
  @echo "Docker Image: ${DOCKER_IMAGE_NAME}:{{docker_tag}}"
  @echo "Electrum Version: ${ELECTRUM_VERSION}"
