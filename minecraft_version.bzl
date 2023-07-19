load("//minecraft_info.bzl", "MinecraftInfo")

def _library_rules_match(rules):
    for rule in rules:
        # Assert action is always "allow"? That's the only thing appearing in the json
        os_name = rule["os"]["name"]
        # FIXME: Non-linux platform support
        if os_name != "linux":
            return False
    return True


def _minecraft_version_impl(ctx: "context") -> ["provider"]:
    # Convert from dependency to artifact
    # TODO: Should this assert only one output?
    version_manifest = ctx.attrs.version_manifest[DefaultInfo].default_outputs[0]
    requested_version = ctx.attrs.requested_version

    # Get version json
    version_json_artifact = ctx.actions.declare_output(requested_version + ".json")
    def derive_version_json(ctx: "context", dynamic_artifacts, outputs):
        # Read the version manifest and download the version.json we desired
        manifest_json = dynamic_artifacts[version_manifest].read_json()
        for version in manifest_json["versions"]:
            if version["id"] == requested_version:
                ctx.actions.download_file(
                    outputs[version_json_artifact].as_output(),
                    version["url"],
                    sha1=version["sha1"],
                )
                break
    ctx.actions.dynamic_output(
        dynamic=[version_manifest],
        inputs=[],
        outputs=[version_json_artifact],
        f=derive_version_json
    )

    # Crawl version json and get the asset index, jars, mappings, and libs
    asset_index_artifact = ctx.actions.declare_output("asset_index.json")
    client_jar_artifact = ctx.actions.declare_output("client.jar")
    client_mappings_artifact = ctx.actions.declare_output("client.txt")
    server_jar_artifact = ctx.actions.declare_output("server.jar")
    server_mappings_artifact = ctx.actions.declare_output("server.txt")
    libraries_dir_artifact = ctx.actions.declare_output("libraries", dir = True)
    
    def derive_version_json_contents(ctx: "context", dynamic_artifacts, outputs):
        version_json = dynamic_artifacts[version_json_artifact].read_json()
        ctx.actions.download_file(
            outputs[asset_index_artifact].as_output(),
            version_json["assetIndex"]["url"],
            sha1=version_json["assetIndex"]["sha1"],
        )
        ctx.actions.download_file(
            outputs[client_jar_artifact].as_output(),
            version_json["downloads"]["client"]["url"],
            sha1=version_json["downloads"]["client"]["sha1"],
        )
        ctx.actions.download_file(
            outputs[client_mappings_artifact].as_output(),
            version_json["downloads"]["client_mappings"]["url"],
            sha1=version_json["downloads"]["client_mappings"]["sha1"],
        )
        ctx.actions.download_file(
            outputs[server_jar_artifact].as_output(),
            version_json["downloads"]["server"]["url"],
            sha1=version_json["downloads"]["server"]["sha1"],
        )
        ctx.actions.download_file(
            outputs[server_mappings_artifact].as_output(),
            version_json["downloads"]["server_mappings"]["url"],
            sha1=version_json["downloads"]["server_mappings"]["sha1"],
        )
        libraries = {}
        for library in version_json["libraries"]:
            if not _library_rules_match(library.get("rules", [])):
                continue
            lib_name = library["downloads"]["artifact"]["path"]
            libraries[lib_name] = ctx.actions.download_file(
                lib_name,
                library["downloads"]["artifact"]["url"],
                sha1=library["downloads"]["artifact"]["sha1"],
            )
        ctx.actions.symlinked_dir(outputs[libraries_dir_artifact].as_output(), libraries)
    ctx.actions.dynamic_output(
        dynamic=[version_json_artifact],
        inputs=[],
        outputs=[
            client_jar_artifact,
            client_mappings_artifact,
            server_jar_artifact,
            server_mappings_artifact,
            asset_index_artifact,
            libraries_dir_artifact,
        ],
        f=derive_version_json_contents,
    )
    return [
        DefaultInfo(
            default_outputs=[client_jar_artifact, server_jar_artifact],
            sub_targets={
                "client_mappings":  [DefaultInfo(default_output=client_mappings_artifact)],
                "server_mappings":  [DefaultInfo(default_output=server_mappings_artifact)],
                "asset_index":  [DefaultInfo(default_output=asset_index_artifact)],
                "libraries": [DefaultInfo(default_output=libraries_dir_artifact)],
            },
        ),
        MinecraftInfo(
            version_json=version_json_artifact,
            client_jar=client_jar_artifact,
            client_mappings=client_mappings_artifact,
            server_jar=server_jar_artifact,
            server_mappings=server_mappings_artifact,
            asset_index=asset_index_artifact,
            libraries_dir=libraries_dir_artifact,
        ),
    ]

minecraft_version = rule(
    doc = "Given version manifest and a requested version, produces the Minecraft jars as output and a MinecraftInfo provider with all other useful artifacts from the version json",
    impl = _minecraft_version_impl,
    attrs = {
        "version_manifest": attrs.dep(doc = "Dependency whose only output is the version_manifest_v2.json available from Mojang's api"),
        "requested_version": attrs.string(doc = "The requested Minecraft version, as it appears in version_manifest_v2.json"),
    }
)
