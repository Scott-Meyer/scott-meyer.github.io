# Keyglass legacy updater

Existing Keyglass v1 installs fetch their updates from `https://scott-meyer.github.io/openflux/`. Keep that path working after the repository move. The [Keyglass project](https://github.com/keyglass-dev/keyglass) publishes to `https://keyglass-dev.github.io/keyglass/`; this site copies that signed output as-is for older clients.

The mirror checks for updates about every six hours. Run **Mirror Keyglass v1 updater** in Actions for an immediate refresh. The job verifies the signed index and file checksums and won't replace the live index with an older one. A signing-key rotation requires updating the trusted public key here before the new index can be mirrored.
