load("//minecraft_info.bzl", "MinecraftInfo")

def _assets_impl(ctx: AnalysisContext):
    version = ctx.attrs.minecraft_version
    asset_index_artifact = version[MinecraftInfo].asset_index

    assets_dir_artifact = ctx.actions.declare_output("assets", dir=True)
    def derive_assets(ctx: AnalysisContext, dynamic_artifacts, outputs):
        asset_index = dynamic_artifacts[asset_index_artifact].read_json()

        downloads = {}
        # XXX: is the pretty name used in modern versions? if so, how?
        for _name, inner in asset_index["objects"].items():
            hash = inner["hash"]
            sharded_hash = hash[0:2] + "/" + hash
            download_name = "objects/" + sharded_hash

            # XXX: We are downloading to a path based on the sharded_hash.
            # The asset index has duplicate files for the same pretty name, so we might
            # encounter duplicates, which needs handling.
            if download_name not in downloads:
                downloads[download_name] = ctx.actions.download_file(
                    download_name,
                    "https://resources.download.minecraft.net/" + sharded_hash,
                    sha1=hash,
                )
        # Gather up all the downloads into a directory
        ctx.actions.symlinked_dir(
            outputs[assets_dir_artifact].as_output(),
            downloads,
        )

    ctx.actions.dynamic_output(
        dynamic=[asset_index_artifact],
        inputs=[],
        outputs=[assets_dir_artifact.as_output()],
        f=derive_assets,
    )
    return [
        DefaultInfo(default_output=assets_dir_artifact)
    ]

minecraft_assets = rule(
    doc = "Given a minecraft_version(), downloads all of the remote assets (sounds and textures) needed to run that version and returns them as a directory artifact.",
    impl = _assets_impl,
    attrs = {
        "minecraft_version": attrs.dep(providers = [MinecraftInfo], doc = "A minecraft_version() target whose assets should be downloaded")
    },
)
