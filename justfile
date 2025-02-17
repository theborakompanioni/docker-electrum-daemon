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

[group("development")]
docker-build-no-cache:
	@just build `date -u +"%Y-%m-%dT%H:%M:%SZ"`

alias build := docker-build

[group("development")]
docker-build build_date='1970-01-01T00:00:00Z':
	@docker build \
		--build-arg BUILD_DATE={{build_date}} \
		--build-arg ELECTRUM_VERSION=${ELECTRUM_VERSION} \
		--build-arg ELECTRUM_CHECKSUM_SHA512=${ELECTRUM_CHECKSUM_SHA512} \
		--build-arg VCS_REF="{{git_commit}}" \
		--tag "${DOCKER_IMAGE_NAME}:{{docker_tag}}" .

[group("development")]
docker-tag:
	docker tag "${DOCKER_IMAGE_NAME}:{{docker_tag}}" "${DOCKER_IMAGE_NAME}:latest"

[group("development")]
up:
	@docker compose up --build

[group("development")]
info:
	@echo "Docker Image: ${DOCKER_IMAGE_NAME}:{{docker_tag}}"
	@echo "Electrum Version: ${ELECTRUM_VERSION}"
