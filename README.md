# konverj-dsl-example

A complete [Konverj](https://github.com/imonirulislam/konverj) configuration,
written in Starlark: two apps, a diamond build chain, a three-rung environment
ladder, three containers, and helpers imported from a shared library.

## Attaching it

```
PROJECT=demo URL=https://github.com/imonirulislam/konverj-dsl-example.git \
  FORMAT=starlark make attach
```

Nothing here names the project it lands in. Every resource is parentless, so
the repository lands wherever it is attached and can be attached twice.

## What is in it

```
.konverj/
├── libraries.star   the shared library, pinned to a commit
├── main.star        the entry point — everything is reached from here
└── lib/site.star    helpers belonging to this repository alone
```

| Resource | Shows |
|---|---|
| `web-compile` → `web-lint`, `web-unit` → `web-package` | a diamond, with one artifact edge and two snapshot edges |
| `api-compile` → `api-test` | a second app sharing the same library helper |
| `web-dev`, `web-staging`, `web-prod` | environments with no gate, a self-approvable gate, and a two-person gate |
| three `deploy_resource`s | containers Konverj converges back to this file when they drift |

## Why Starlark and not YAML

`snapshot(compile)` on line 74 of `main.star` is *the configuration object*,
not its name. Rename `compile` and the reference moves with it; delete it and
evaluation fails at the load rather than at scheduling time. That is the one
real advantage a DSL has over a data format here, and it is why the reference
is a variable.

There is no template resource. A helper is a function — see `lib/site.star`
and the shared library — and Konverj records the **call chain** that produced
each configuration, so "which helper made this" survives the change:

```
@shared//base.star:29 <- @shared//base.star:44 <- .konverj/main.star:31
```

## The library

Helpers several repositories share live in
[konverj-dsl-lib](https://github.com/imonirulislam/konverj-dsl-lib), declared
in `.konverj/libraries.star` and pinned to a commit hash.

Only a full hash pins — a branch or tag can be moved to point at different
code under the same name. Konverj fetches the pin before evaluation and
compares `HEAD` against it afterwards. Upgrading means editing that hash,
which is a reviewable commit here.

A library cannot declare: it defines functions, and this repository decides
which to call. Importing one never changes what this repository contains.

## One install, two answers

```python
region = ctx.param("REGION", default = "local")
```

The same commit evaluates differently in two installs without branching in
git. Set it on the configuration repository's evaluation context.

## Licence

Apache 2.0.
