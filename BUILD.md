# Building Air Server

The supported target for the first release is Apple Silicon macOS.

```bash
git clone --recurse-submodules https://github.com/victorcappa/open-air-server.git
cd open-air-server
./scripts/doctor-macos.sh
./scripts/build-macos-arm64.sh
```

The output is an ad-hoc-signed, self-contained application at:

```text
build/macos/dist/Air Server.app
```

See [docs/BUILD_MACOS.md](docs/BUILD_MACOS.md) for dependencies, version
requirements and verification boundaries. The original cross-platform upstream
instructions remain available at
[docs/upstream/POPYACHSA_BUILD.md](docs/upstream/POPYACHSA_BUILD.md) for source
provenance; they are not the release procedure for this fork.
