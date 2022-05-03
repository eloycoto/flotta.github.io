#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOC_PATH="$SCRIPT_DIR/../documentation"
TMP_DIR="$(mktemp -d)"
echo "Using TMP_DIR: $tmpdir"
# Create fake GOPATH
export GOPATH="${TMP_DIR}/go"
export GO111MODULE="on"
GOROOT="$(go env GOROOT)"
export GOROOT
GOBIN="${TMP_DIR}/bin"
export GOBIN

go install fybrik.io/crdoc@v0.6.1

get_docs_for_version() {
  local readonly doc_version=$1
  local readonly git_version=$2
  echo "Verstion to download: $doc_version"
  rm -rf $TMP_DIR/flotta-operator || exit 1
  git clone https://github.com/project-flotta/flotta-operator -b $git_version --depth 1 $TMP_DIR/flotta-operator

  $GOBIN/crdoc \
    --resources $TMP_DIR/flotta-operator/config/crd/bases/ \
    --output $DOC_PATH/$doc_version/operations/crd.md \
    --template $SCRIPT_DIR/templates/frontmatter.tmpl
}

main() {
  echo "Main folder: $SCRIPT_DIR"
  echo "List current versions: "

  VERSIONS=$(ls -1 $DOC_PATH)

  for version in $VERSIONS; do
    GIT_VERSION=$version
    if [ "$version" == "latest" ]; then
      GIT_VERSION="main"
    fi
    echo -e "\t - $version"
    get_docs_for_version $version $GIT_VERSION
  done
}

main
