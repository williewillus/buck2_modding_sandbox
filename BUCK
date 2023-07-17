# A list of available rules and their signatures can be found here: https://buck2.build/docs/api/rules/
load("//minecraft_version_json.bzl", "minecraft_version_json")

# We have to update the sha1 of this file whenever mc updates anyways so let's just iterate with a
# static one for now.
# For ease of use might want to encourage people just download this once anyways since it doesn't change often...
export_file(
  name = 'version_manifest_v2.json',
)

minecraft_version_json(
  name = "1.20.1.json",
  version_manifest = ":version_manifest_v2.json",
  requested_version = "1.20.1",
)

minecraft_version_json(
  name = "1.19.4.json",
  version_manifest = ":version_manifest_v2.json",
  requested_version = "1.19.4",
)

minecraft_version_json(
  name = "broken.json",
  version_manifest = ":version_manifest_v2.json",
  requested_version = "aerjhetkjh",
)

# Idea: Rule that takes version json and gives all the stuff you'd want from it (exposed through e.g. VanillaVersionProvider).
# The game binaries, all libraries (in a subdir), the assets, etc.