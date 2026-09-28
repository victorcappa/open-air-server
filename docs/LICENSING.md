# Licensing

Air Server is distributed under GPL-3.0-or-later because it is a modified
version of Popyachsa AirPlay and links to the GPL UxPlay engine.

## What remains GPL

- The patched UxPlay engine in `third_party/uxplay`.
- The FFI layers in `airplay-lib-sys` and `airplay-lib`.
- The Rust host application in `app`.
- Modifications and packaging scripts used to build the distributed application.

Distributing a binary requires making the corresponding source available under
the GPL, preserving copyright and license notices, and providing the GPL text.
The application bundle copies the license into its Resources directory.

## Separate components

Independent tools or services can use their own licenses only when they are
genuinely separate works and do not form a combined derivative program with the
GPL engine. Merely moving tightly coupled code into another process is not an
automatic license exception. Obtain legal advice before distributing a mixed
proprietary/GPL product.

Unmodified system/runtime dependencies retain their own terms, including:

- GStreamer and GLib: LGPL.
- OpenSSL: Apache-2.0.
- Rust dependencies: primarily MIT/Apache-2.0.
- The optional Windows mDNS shim: MIT/public-domain components.

The full credit chain is in [NOTICE](../NOTICE). Upstream notices must remain
present in forks and redistributed builds.

This document records the project's compliance approach; it is not legal advice.
