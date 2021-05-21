#!/usr/bin/env bash

set -e

git remote set-url origin "https://${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}"

echo "Getting head sha..."

if [[ -z $GITHUB_BASE_REF ]]; then
  HEAD_SHA=$(git rev-parse HEAD^1 || true)
else
  TARGET_BRANCH=${GITHUB_BASE_REF}
  git fetch --depth=1 origin "${TARGET_BRANCH}":"${TARGET_BRANCH}"
  HEAD_SHA=$(git rev-parse "${TARGET_BRANCH}" || true)
fi

if [[ -z $HEAD_SHA ]]; then
  echo "::warning::Unable to determine the head sha: $HEAD_SHA."
  echo "::warning::You seem to be missing 'fetch-depth: 0' or 'fetch-depth: 2'"
  exit 1
else
  echo "Using head sha: $HEAD_SHA..."
  if [[ -z "$INPUT_FILES" ]]; then
    echo "Getting diff..."
    ADDED=$(git diff --diff-filter=A --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    COPIED=$(git diff --diff-filter=C --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    DELETED=$(git diff --diff-filter=D --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    MODIFIED=$(git diff --diff-filter=M --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    RENAMED=$(git diff --diff-filter=R --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    CHANGED=$(git diff --diff-filter=T --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    UNMERGED=$(git diff --diff-filter=U --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    UNKNOWN=$(git diff --diff-filter=X --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    ALL_CHANGED=$(git diff --diff-filter="*ACDMRTUX" --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
    ALL_MODIFIED_FILES=$(git diff --diff-filter="ACM" --name-only "$HEAD_SHA" | tr "\n" "$INPUT_SEPARATOR" | sed -E "s/($INPUT_SEPARATOR)$//")
  else
    ADDED_ARRAY=()
    COPIED_ARRAY=()
    DELETED_ARRAY=()
    MODIFIED_ARRAY=()
    RENAMED_ARRAY=()
    CHANGED_ARRAY=()
    UNMERGED_ARRAY=()
    UNKNOWN_ARRAY=()
    ALL_CHANGED_ARRAY=()
    ALL_MODIFIED_FILES_ARRAY=()
    for path in ${INPUT_FILES}
    do
      echo "Checking for file changes: \"${path}\"..."
      IFS=" "
      # shellcheck disable=SC2207
      ADDED_ARRAY+=($(git diff --diff-filter=A --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      COPIED_ARRAY+=($(git diff --diff-filter=C --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      DELETED_ARRAY+=($(git diff --diff-filter=D --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      MODIFIED_ARRAY+=($(git diff --diff-filter=M --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      RENAMED_ARRAY+=($(git diff --diff-filter=R --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      CHANGED_ARRAY+=($(git diff --diff-filter=T --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      UNMERGED_ARRAY+=($(git diff --diff-filter=U --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      UNKNOWN_ARRAY+=($(git diff --diff-filter=X --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      ALL_CHANGED_ARRAY+=($(git diff --diff-filter="*ACDMRTUX" --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
      # shellcheck disable=SC2207
      ALL_MODIFIED_FILES_ARRAY+=($(git diff --diff-filter="ACM" --name-only "$HEAD_SHA" | grep -E "(${path})" | xargs || true))
    done

    # shellcheck disable=SC2001
    ADDED=$(echo "${ADDED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    COPIED=$(echo "${COPIED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    DELETED=$(echo "${DELETED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    MODIFIED=$(echo "${MODIFIED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    RENAMED=$(echo "${RENAMED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    CHANGED=$(echo "${CHANGED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    UNMERGED=$(echo "${UNMERGED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    UNKNOWN=$(echo "${UNKNOWN_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    ALL_CHANGED=$(echo "${ALL_CHANGED_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
    # shellcheck disable=SC2001
    ALL_MODIFIED_FILES=$(echo "${ALL_MODIFIED_FILES_ARRAY[*]}" | sed 's/  */'"$INPUT_SEPARATOR"'/g')
  fi
fi
echo "Added files: $ADDED"
echo "Copied files: $COPIED"
echo "Deleted files: $DELETED"
echo "Modified files: $MODIFIED"
echo "Renamed files: $RENAMED"
echo "Changed files: $CHANGED"
echo "Unmerged files: $UNMERGED"
echo "Unknown files: $UNKNOWN"
echo "All changed files: $ALL_CHANGED"
echo "All modified files: $ALL_MODIFIED_FILES"

if [[ -n "$INPUT_FILES" ]]; then
  # shellcheck disable=SC2001
  ALL_INPUT_FILES=$(echo "$INPUT_FILES" | tr "\n" " " | xargs)

  echo "Input files: ${ALL_INPUT_FILES[*]}"
  echo "Matching modified files: ${ALL_MODIFIED_FILES[*]}"
  if [[ -n "$ALL_MODIFIED_FILES" ]]; then
    echo "::set-output name=any_changed::true"
  else
    echo "::set-output name=any_changed::false"
  fi
fi

echo "::set-output name=added_files::$ADDED"
echo "::set-output name=copied_files::$COPIED"
echo "::set-output name=deleted_files::$DELETED"
echo "::set-output name=modified_files::$MODIFIED"
echo "::set-output name=renamed_files::$RENAMED"
echo "::set-output name=changed_files::$CHANGED"
echo "::set-output name=unmerged_files::$UNMERGED"
echo "::set-output name=unknown_files::$UNKNOWN"
echo "::set-output name=all_changed_files::$ALL_CHANGED"
echo "::set-output name=all_modified_files::$ALL_MODIFIED_FILES"
