# Helpers that belong to this repository alone.
#
# The split is deliberate: anything several repositories share moves to the
# library, anything only this one needs stays here. This file is loaded by a
# plain path because it is part of the repository; the library is loaded by
# "@shared//..." because it is not.

def deployment(id, name, project, environment, release, port, site_env, description = ""):
    """One container, converged back to this declaration whenever it drifts."""
    return deploy_resource(
        id = id,
        name = name,
        project = project,
        description = description,
        environment = environment,
        # The image is whichever build has been promoted into this
        # environment, pinned by digest at the moment of approval. Naming the
        # pipeline rather than a digest is what makes this a deployment.
        release = release,
        auto_heal = "aggressive",
        restart = "unless-stopped",
        # Container port to host port — the reverse of docker run -p, because
        # the container port is the stable half.
        ports = {"80": port},
        env = {"SITE_ENV": site_env},
        labels = {"app": project, "owner": "platform"},
    )

def ladder(project, prefix):
    """dev takes anything, staging records who sent it, prod needs a second person."""
    environment(
        id = prefix + "-dev",
        name = "dev",
        project = project,
        description = "Where a build lands to be looked at. No gate — that is the point of dev.",
        ordinal = 0,
    )
    environment(
        id = prefix + "-staging",
        name = "staging",
        project = project,
        description = "Gated, but the reviewer may be the author.",
        requires_approval = True,
        min_approvers = 1,
        allow_self_approval = True,
        ordinal = 1,
    )
    environment(
        id = prefix + "-prod",
        name = "prod",
        project = project,
        description = "Nothing reaches it without a second person saying so.",
        requires_approval = True,
        min_approvers = 1,
        # allow_self_approval is absent, which means false. Spelled by
        # omission rather than written out: the safe value should not depend
        # on an author remembering it.
        ordinal = 2,
    )
