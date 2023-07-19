# What
This repo explores using [Buck 2](https://buck2.build), a Bazel-like build tool from Meta,
to build Minecraft mods.

The goal is to compile a working Fabric example mod, but using Buck 2, without any Gradle
or Loom.

# Why Buck 2
I wanted something with the following properties:
* Reproducible/Auditable: Recent security events have shown that supply chain compromise in
  Minecraft modding is a real and massive risk.
* Efficient: Gradle spinning = not fun.
* Deterministic/Stable: No nuking your cache randomly and praying. The goal is to be
  perfectly reliable.

Buck 2 descends from Buck 1 and further was inspired by Blaze (Bazel's closed-source
sibling). All ofthe build systems in this family value the above properties.

# Why not Bazel?

Of the hermetic Blaze-like build systems, Bazel is ths most mature and widely used, but a
couple reasons made be try Buck 2:

1. Bazel doesn't support dynamic dependencies. That is, taking an artifact as input, and
   based on that artifact's materialized contents, dynamically produce more build targets.
   This is crucial for implementing automated parsing of version.json, downloading assets
   and libraries, etc. The workaround in Bazel is to codegen the build definitions, which
   seems extremely brittle and prone to the same "nuke cache, rerun build multiple times,
   and pray til it works" that I wished to avoid with Gradle.
2. Buck 2 is written in Rust and from my experience using it internally at Meta, it's
   fast. Bazel is written in Java, like Buck 1, which can chug sometimes.
3. I work at Meta, so good old homerism :)

# Needed tools
* Java toolchain
  * Unfortunately, Buck2's Java support is very immature as it has a lot of internal-only
    minutiae. It's probably easier to reimplement the java rules we need ourselves from
    first-principles (aka reading the `javac` manual page).
* jar merging: JarMerger (part of Fabric Loom)
  * Extract, vendor, and build the Java code as part of the mod build, probably
* remapping: TinyRemapper (standalone binary releases on Fabric Maven)
* mappings: Yarn/Intermediary (standalone releases on Fabric Maven)
* Mixin
* IDE project generation: ?
  * See what Brachyura does, probably

# Implementation Notes
Buck 2's documentation can be kind of opaque, so here's some random notes.

Targets are the thing that you can request to be built.

Every target is a rule that has been instantiated with attributes (arguments).

Rules are functions that take the attributes and return providers.

Providers are structs representing the result of the build, for use as inputs to other
rules.

`artifact` values are not actually a compiled thing, they are tokens representing
something that will eventually be compiled or created.

# Other notes:
https://cdn.discordapp.com/attachments/404671932072591380/1130399524955902023/CompilationOfAMod.png

# Scoping and todo
This is an experimental project, so we're going to take some shortcuts:

* Assume Minecraft 1.20.1 or later (no support for manifest/assets/library quirks from
  earlier versions)
* Assume build executes on Linux x86_64 (though make an attempt to be portable by using
  tools written in pure Java, for example)
* No multiloader or mojmap/parchment support
* Ok to vendor or manually write out dependencies instead of parsing maven POM's

- [x] version manifest and version json parsing
- [x] asset downloading
  - ish, buck2 seems to open tons of fd's which can make the download flaky
- [x] Library downloading
- [ ] Client/server jar merge
- [ ] Remap to intermediary
- [ ] Remap to named
- [ ] Build mod against named (no mixins)
- [ ] Support mixins
- [ ] Process resources (insert mixin refmap name)
- [ ] Remap to intermediary
- [ ] Assemble final jar
- [ ] Make sure final jar seems to run

Main goal accomplished by here! Stretch goals:
- [ ] Demonstrate consuming intermediary-mapped deps
- [ ] IDE project generation
- [ ] Access Widener support
- [ ] Mojmap support
- [ ] Make the interface nicer to use as an "end user"
