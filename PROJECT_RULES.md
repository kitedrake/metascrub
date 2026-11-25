# MetaScrub

- Build with `./build.sh` and test with `./test.sh`. Both need Xcode's toolchain (macOS 26 SDK);
  the Command Line Tools alone are not enough.
- omso Builder builds this repository from `omso-build.json` (build, tests, `--self-test`, copy
  into `/Applications/omso`). Keep that file working when build or test commands change, and
  check it with an omso Builder preview or a build that is not installed.
- The remote is the GitHub repository `kitedrake/metascrub`. Commit validated work
  locally; push only when the user asks, and never publish releases without being asked.
- Cleaning must not re-encode content silently. If a path has to re-compress or drop something
  beyond metadata, return a note so the app shows it, and document it in the README table.
- Tests and experiments work on generated fixtures or copies in temporary folders. Never point
  cleaning or saving at the user's own files or at system files in place.
- When adding or changing format support, update the README format table and add a fixture-based
  test that reads, edits (if supported) and cleans the format.
- In-app updates use Sparkle, pinned in `Package.swift`. Only release builds (`UPDATE_FEED_URL` and
  `UPDATE_PUBLIC_KEY` set) contain an updater; keep plain and omso Builder builds without one.
  Releases are annotated `v<version>` tags (push one only when the owner asks); the Release workflow builds and publishes them, and `release.py` in the `software-site` repository is the local fallback, with `VERSION` bumped first.
  After changing Sparkle or `build.sh`, run `sh scripts/test-update.sh metascrub` there. Never commit
  signing keys.
- `scripts/release-ci.sh` is identical in every Kitedrake app repository; change all copies together. Release secrets
  (Apple certificate, notary key, Sparkle key, site token) live only in GitHub secrets, never in files.
