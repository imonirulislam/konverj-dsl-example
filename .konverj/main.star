# The entry point. One file, with everything else reached through load().
#
# Per-file evaluation would force cross-file references back to strings, and
# strings are what this language is here to remove: `snapshot(compile)` below
# is the configuration itself, not its name.

load("@shared//base.star", "on_push", "script", "standard")
load("lib/site.star", "deployment", "ladder")

# No parent: is written anywhere. A parentless project lands in whichever
# project this repository is attached to, so the file never hard-codes the
# attachment point and the same repository can be attached twice.
project(
    id = "web",
    name = "Web",
    description = "The site. A diamond chain, three environments, three containers.",
)

project(
    id = "api",
    name = "API",
    description = "A second app in the same repository, sharing the same library.",
)

# ── web: a diamond ─────────────────────────────────────────────────────────
#
# Compile fans out to two checks, and Package joins them back together. One
# chain run has exactly one Compile in it, so Lint and Unit tests are held to
# the same revision and there is no second Compile to pick by mistake.

compile = on_push(
    id = "web-compile",
    name = "Compile",
    project = "web",
    description = "Builds the bundle the rest of the chain reads.",
    steps = [script("assemble", """
set -eu
rm -rf build && mkdir -p build
printf 'site built in %s\n' "$(pwd)" > build/site.txt
printf '{"app":"web","pages":1}\n' > build/manifest.json
echo "assembled $(wc -l < build/site.txt) line(s)"
""")],
    artifact_rules = ["build/** => site.zip"],
)

lint = standard(
    id = "web-lint",
    name = "Lint",
    project = "web",
    description = "Gates, and hands over nothing — so its edge is a snapshot.",
    depends_on = [snapshot(compile)],
    steps = [script("lint", "echo 'no lint errors'")],
)

# A test runner that reports failures and still exits zero would otherwise
# pass the chain. stop_build is off so the whole report reaches the log first.
unit = standard(
    id = "web-unit",
    name = "Unit tests",
    project = "web",
    depends_on = [snapshot(compile)],
    steps = [script("test", "echo '12 passed, 0 failed'")],
    failure_conditions = [{
        "kind": "regex",
        "pattern": "[1-9][0-9]* failed",
        "message": "unit tests reported failures",
        "stop_build": False,
    }],
)

# Three parents, which is what closes the diamond. The bundle comes from
# Compile, which built it — taking it from Unit tests would force that build
# to republish bytes it never produced.
#
# The Compile edge is drawn in the Chains tab even though the longer path
# through Unit tests implies the waiting: waiting is implied by a path,
# copying files is not.
package = standard(
    id = "web-package",
    name = "Package",
    project = "web",
    description = "Joins the two checks back together and names what the chain produced.",
    depends_on = [
        artifact(compile, artifacts = "site.zip!** => build"),
        snapshot(lint),
        snapshot(unit),
    ],
    steps = [script("package", """
set -eu
test -s build/site.txt
test -s build/manifest.json
mkdir -p out
printf '{"app":"web","bundle_sha256":"%s"}\n' \
  "$(sha256sum build/site.txt | cut -d' ' -f1)" > out/release.json
echo "packaged web from a diamond of 4 builds"
""")],
    artifact_rules = ["out/release.json"],
)

# ── api: the same helper, a straight line ──────────────────────────────────

api_compile = on_push(
    id = "api-compile",
    name = "Compile",
    project = "api",
    steps = [script("assemble", "echo 'api assembled'")],
)

standard(
    id = "api-test",
    name = "Tests",
    project = "api",
    depends_on = [snapshot(api_compile)],
    steps = [script("test", "echo 'api tests passed'")],
)

# ── where web runs ─────────────────────────────────────────────────────────

ladder("web", "web")

# One install evaluates this differently from another without branching in
# git, which is what a configuration reaching for something like a region
# actually needs.
region = ctx.param("REGION", default = "local")

deployment(
    id = "web-dev",
    name = "web (dev)",
    project = "web",
    environment = "web-dev",
    release = "web-package",
    port = "8082",
    site_env = "dev-" + region,
    description = "Whatever was promoted here last.",
)

deployment(
    id = "web-staging",
    name = "web (staging)",
    project = "web",
    environment = "web-staging",
    release = "web-package",
    port = "8081",
    site_env = "staging-" + region,
)

deployment(
    id = "web-prod",
    name = "web (prod)",
    project = "web",
    environment = "web-prod",
    release = "web-package",
    port = "8083",
    site_env = "prod-" + region,
    description = "The digest here only changes when a second person approves it.",
)
