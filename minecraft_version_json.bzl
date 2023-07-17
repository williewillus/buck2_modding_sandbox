def _minecraft_version_json_impl(ctx: "context") -> ["provider"]:
  # Convert from dependency to artifact
  # TODO: Should this assert only one output?
  version_manifest = ctx.attrs.version_manifest[DefaultInfo].default_outputs[0]
  requested_version = ctx.attrs.requested_version
  version_json = ctx.actions.declare_output(requested_version + ".json")
  
  def derive_dynamic_output(ctx: "context", dynamic_artifacts, outputs):
    # Read the version manifest and download the version.json we desired
    manifest_json = dynamic_artifacts[version_manifest].read_json()
    for version in manifest_json["versions"]:
      if version["id"] == requested_version:
        ctx.actions.download_file(
          outputs[version_json].as_output(),
          version["url"],
          sha1=version["sha1"],
        )
        break

  ctx.actions.dynamic_output(dynamic=[version_manifest], inputs=[], outputs=[version_json], f=derive_dynamic_output)
  return [DefaultInfo(default_output = version_json)]

minecraft_version_json = rule(
  doc = "Given the version_manifest_v2 json and a Minecraft version, produces that version's version.json",
  impl = _minecraft_version_json_impl,
  attrs = {
    "version_manifest": attrs.dep(doc = "Dependency whose only output is the version_manifest_v2.json available from Mojang's api"),
    "requested_version": attrs.string(doc = "The requested Minecraft version, as it appears in version_manifest_v2.json"),
  }
)