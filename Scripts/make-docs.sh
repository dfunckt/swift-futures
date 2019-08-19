#!/usr/bin/env sh

# Much of this is an adaptation of the corresponding script in swift-nio:
# https://github.com/apple/swift-nio
# ============================================================================

set -e

MODULES=(Futures FuturesSync)

REPO_URL=https://github.com/dfunckt/swift-futures
BASE_URL=https://dfunckt.github.io/swift-futures
OUTPUT_DIR="docs/"

VERSION=$(git describe --abbrev=0 --tags || git rev-parse --abbrev-ref HEAD)

JAZZY_ARGS=(
  --config .jazzy.yml
  --github_url "${REPO_URL}"
  --github-file-prefix "${REPO_URL}/tree/${VERSION}"
  --xcodebuild-arguments USE_SWIFT_RESPONSE_FILE=NO
)

make_module_readme() {
  local readme_path="$1"
  cat > "${readme_path}" <<"EOF"
# Futures

Futures comprises several modules:

EOF
  for m in "${MODULES[@]}"; do
    echo "- [${m}](../${m}/index.html)" >>"${readme_path}"
  done
}

make_module_docs() {
  local module="$1"
  local module_readme="$2"
  args=(
    "${JAZZY_ARGS[@]}"
    --module "${module}"
    --module-version "${VERSION}"
    --title "${module} Reference (${VERSION})"
    --readme "${module_readme}"
    --root-url "${BASE_URL}/${OUTPUT_DIR}${VERSION}/${module}"
    --output "${OUTPUT_DIR}${VERSION}/${module}/"
  )
  jazzy "${args[@]}"
}

publish() {
  local branch_name=$(git rev-parse --abbrev-ref HEAD)
  local git_author=$(git --no-pager show -s --format='%an <%ae>' HEAD)

  git fetch origin +gh-pages:gh-pages
  git checkout gh-pages

  rm -rf "${OUTPUT_DIR}latest"
  cp -r "${OUTPUT_DIR}${VERSION}" "${OUTPUT_DIR}latest"

  git add --all "${OUTPUT_DIR}"

  local latest_url="${OUTPUT_DIR}latest/Futures/index.html"
  echo '<html><head><meta http-equiv="refresh" content="0; url='"${latest_url}"'" /></head></html>' >index.html
  git add index.html

  touch .nojekyll
  git add .nojekyll

  local changes=$(git diff-index --name-only HEAD)
  if test -n "$changes"; then
    git commit --author="${git_author}" -m "Publish API reference for ${VERSION}"
    git push origin gh-pages
  else
    echo "no changes detected"
  fi

  git checkout -f "${branch_name}"
}

mkdir -p "${OUTPUT_DIR}${VERSION}"

for module in "${MODULES[@]}"; do
  readme="${OUTPUT_DIR}${VERSION}/${module}.md"
  make_module_readme "$readme"
  make_module_docs "$module" "$readme"
done

if test -n "$CI"; then
  publish
fi
