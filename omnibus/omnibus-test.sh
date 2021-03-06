#!/bin/bash
set -ueo pipefail

channel="${CHANNEL:-unstable}"
product="${PRODUCT:-inspec}"
version="${VERSION:-latest}"

echo "--- Installing $channel $product $version"
package_file="$(/opt/omnibus-toolchain/bin/install-omnibus-product -c "$channel" -P "$product" -v "$version" | tail -n 1)"

echo "--- Verifying omnibus package is signed"
/opt/omnibus-toolchain/bin/check-omnibus-package-signed "$package_file"

sudo rm -f "$package_file"

echo "--- Verifying ownership of package files"

export INSTALL_DIR=/opt/inspec
NONROOT_FILES="$(find "$INSTALL_DIR" ! -user 0 -print)"
if [[ "$NONROOT_FILES" == "" ]]; then
  echo "Packages files are owned by root.  Continuing verification."
else
  echo "Exiting with an error because the following files are not owned by root:"
  echo "$NONROOT_FILES"
  exit 1
fi

echo "--- Running verification for $channel $product $version"

# Set GEM_HOME and GEM_PATH to verify our appbundle inspec shim is correctly
# removing them from the environment while launching from our embedded ruby.
export GEM_HOME=/SHOULD_NOT_EXIST
export GEM_PATH=/SHOULD_NOT_EXIST
export CHEF_LICENSE="accept-no-persist"

inspec version

inspec shell -c platform.family

inspec plugin list
