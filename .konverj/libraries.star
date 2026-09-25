# The libraries this repository may import, and nothing else.
#
# A separate file because it has to be read *before* evaluation: the libraries
# it names are what evaluation loads. library() is the entire vocabulary here
# and load() is refused, so reading this list cannot itself pull code from
# anywhere.

library(
    name = "shared",
    repo = "https://github.com/imonirulislam/konverj-dsl-lib.git",
    # A full commit hash, never a branch or a tag — either can be moved to
    # point at different code under the same name. Konverj checks this out and
    # compares HEAD against it afterwards. Upgrading is an edit here, which is
    # a reviewable commit.
    commit = "e1324a255a0e6ccac1e084b43fa0cb4283e05711",
)
