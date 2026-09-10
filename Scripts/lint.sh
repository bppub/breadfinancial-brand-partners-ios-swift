#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

expected_version="${SWIFTLINT_VERSION:-0.65.1}"
actual_version="$(swiftlint version)"
if [[ "$actual_version" != "$expected_version" ]]; then
  echo "::warning::SwiftLint $expected_version is expected; found $actual_version" >&2
fi

swiftlint lint --strict --config .swiftlint.yml Sources
