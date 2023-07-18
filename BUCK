load("//minecraft_version.bzl", "minecraft_version")
load("//minecraft_assets.bzl", "minecraft_assets")

# We have to update the sha1 of this file whenever mc updates anyways so let's just iterate with a
# static one for now.
# For ease of use might want to encourage people just download this once anyways since it doesn't change often...
export_file(
    name = 'version_manifest_v2.json',
)

minecraft_version(
    name = "1.20.1",
    version_manifest = ":version_manifest_v2.json",
    requested_version = "1.20.1",
)

minecraft_assets(
    name = "1.20.1-assets",
    minecraft_version = ":1.20.1",
)
