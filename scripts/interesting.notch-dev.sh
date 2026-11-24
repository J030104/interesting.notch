#!/bin/bash
set -euo pipefail

usage() {
    echo 'Usage: bash scripts/interesting.notch-dev.sh [--verify-only] [commit]'
    echo 'Builds a committed revision on a public GitHub build branch and launches the verified app.'
}

fail() {
    echo "$*" >&2
    exit 1
}

mode=relaunch
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --verify-only) mode=verify; shift ;;
esac
if [[ $# -gt 1 || "${1:-}" == -* ]]; then
    usage >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$(git -C "$script_dir" rev-parse --show-toplevel)"
cd "$root"
if [[ $# -eq 0 ]]; then
    git_status="$(git status --porcelain)"
    [[ -z "$git_status" ]] || fail 'Commit the intended changes first, or pass the commit to build explicitly.'
fi
revision="$(git rev-parse --verify --end-of-options "${1:-HEAD}^{commit}")"
repo=J030104/interesting.notch
workflow=interesting.notch.yml
branch="codex/notch-build/$revision"
artifact=interesting.notch

command -v gh >/dev/null || fail 'Install and authenticate the GitHub CLI (gh) first.'
export GH_PROMPT_DISABLED=1 GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/usr/bin/false
workflow_state="$(gh api "repos/$repo/actions/workflows/$workflow" --jq '.state')" \
    || fail 'GitHub Actions is unavailable to gh. Check connectivity and GitHub CLI authentication.'
[[ "$workflow_state" == active ]] || fail "The $workflow workflow is $workflow_state."

push_result="$(git -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
    push --porcelain --no-follow-tags "https://github.com/$repo.git" "$revision:refs/heads/$branch")"
printf '%s\n' "$push_result"

if [[ "$push_result" == *$'\n=\t'* ]]; then
    # A no-op push creates no event. Dispatch another run for this revision.
    run_id="$(gh api --method POST -H 'X-GitHub-Api-Version: 2026-03-10' \
        "repos/$repo/actions/workflows/$workflow/dispatches" -f "ref=$branch" --jq '.workflow_run_id')"
    [[ "$run_id" =~ ^[0-9]+$ ]] || fail 'GitHub did not return a workflow run ID.'
else
    echo "Waiting for GitHub Actions to register $revision."
    deadline=$((SECONDS + 120))
    while :; do
        run_id="$(gh run list --repo "$repo" --workflow "$workflow" --branch "$branch" \
            --commit "$revision" --event push --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
        if [[ "$run_id" =~ ^[0-9]+$ ]]; then break; fi
        (( SECONDS < deadline )) || fail "No build was queued for $branch. Check the workflow's push trigger."
        sleep 5
    done
fi

run_url="https://github.com/$repo/actions/runs/$run_id"
echo "Waiting for $run_url"
deadline=$((SECONDS + 1200))
while :; do
    details="$(gh run view "$run_id" --repo "$repo" --json headSha,status,conclusion \
        --jq '[.headSha, .status, .conclusion] | @tsv')"
    IFS=$'\t' read -r run_revision status conclusion <<< "$details"
    [[ "$run_revision" == "$revision" ]] || fail "The run is for $run_revision, expected $revision."
    if [[ "$status" == completed ]]; then
        [[ "$conclusion" == success ]] || fail "Build ended with $conclusion. See $run_url"
        break
    fi
    (( SECONDS < deadline )) || fail "Build timed out. See $run_url"
    sleep 10
done

artifact_info="$(gh api "repos/$repo/actions/runs/$run_id/artifacts?name=$artifact" \
    --jq '.artifacts[] | select(.expired == false) | [.id, .digest] | @tsv')"
IFS=$'\t' read -r artifact_id digest <<< "$artifact_info"
if [[ "$artifact_info" == *$'\n'* || ! "$artifact_id" =~ ^[0-9]+$ || ! "$digest" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    fail "No verifiable build artifact is available. See $run_url"
fi

build_dir="$root/build/development"
mkdir -p "$build_dir"
stage="$(mktemp -d "$build_dir/${revision:0:12}-$run_id.XXXXXX")"
keep=false
trap 'if [[ "$keep" == false ]]; then rm -rf -- "$stage"; fi' EXIT

gh api "repos/$repo/actions/artifacts/$artifact_id/zip" > "$stage/artifact.zip"
actual_digest="$(shasum -a 256 "$stage/artifact.zip" | cut -d ' ' -f 1)"
[[ "$digest" == "sha256:$actual_digest" ]] || fail 'GitHub artifact checksum mismatch.'
unzip -p "$stage/artifact.zip" "$artifact.zip" > "$stage/$artifact.zip"
rm -- "$stage/artifact.zip"
ditto -x -k "$stage/$artifact.zip" "$stage"

app="$stage/$artifact.app"
bash "$script_dir/interesting.notch-build.sh" verify "$app" "$revision"
keep=true
echo "Build available at $app"
if [[ "$mode" == relaunch ]]; then
    bash "$script_dir/interesting.notch-build.sh" relaunch "$app" "$revision"
fi
