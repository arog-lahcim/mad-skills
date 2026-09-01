#!/usr/bin/env bash
# Re-point release tags that exist on the remote but are not reachable from HEAD
# when a matching chore(release) commit is on the branch (e.g. after a repo rename).
set -euo pipefail

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "No HEAD commit; skipping orphaned tag repair."
  exit 0
fi

repaired=0

while IFS= read -r commit; do
  subject="$(git log -1 --format=%s "$commit")"
  version="$(printf '%s\n' "$subject" | sed -n 's/^chore(release): \([0-9.][0-9.]*\) \[skip ci\].*/\1/p')"
  [[ -n "$version" ]] || continue

  tag="v${version}"
  git rev-parse --verify "refs/tags/${tag}" >/dev/null 2>&1 || continue

  if git merge-base --is-ancestor "$tag" HEAD; then
    continue
  fi

  tag_sha="$(git rev-parse "$tag")"
  if [[ "$tag_sha" == "$commit" ]]; then
    continue
  fi

  echo "Repairing orphaned tag ${tag}: ${tag_sha} -> ${commit}"
  git update-ref "refs/tags/${tag}" "$commit"
  git push origin "refs/tags/${tag}" --force
  repaired=1
done < <(git log --format=%H HEAD --grep='^chore(release):')

if [[ "$repaired" -eq 0 ]]; then
  echo "No orphaned release tags to repair."
fi
