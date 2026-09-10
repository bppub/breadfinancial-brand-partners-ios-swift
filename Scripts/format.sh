#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

expected_version="${SWIFT_FORMAT_VERSION:-603.0.0}"
actual_version="$(swift-format --version | awk '{print $NF}')"
if [[ "$actual_version" != "$expected_version" ]]; then
  echo "::warning::swift-format $expected_version is expected; found $actual_version" >&2
fi

if [[ "${1:-}" == "--check" ]]; then
  swift-format lint --strict --recursive --configuration .swift-format Sources
else
  swift-format format --in-place --recursive --configuration .swift-format Sources
fi
