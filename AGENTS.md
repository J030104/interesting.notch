# Development builds

For app changes and development workflow changes, use a read-only subagent when available to independently review the change and run the relevant checks. For workflow changes, include the commit selection, artifact verification, and relaunch conditions in that review. Address the findings before reporting the result.

When a task calls for a runnable preview, commit the intended changes and run `bash scripts/interesting.notch-dev.sh`. This publishes the commit to a dedicated branch in the public repository. Use `--verify-only` when the task calls for a build without a relaunch.

If the shell cannot reach GitHub, use the connected GitHub tools to publish the same commit to `codex/notch-build/<full-commit-sha>`. The branch push starts the build workflow. Track that run through completion and verify the downloaded archive checksum, app signature, and embedded revision before launching the app. Keep the previous app available for rollback.

Report which CI checks passed and which interactions were observed in the running app.
