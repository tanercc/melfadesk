# MelfaDesk trial build

A throwaway trial of a RustDesk 1.5.3 build with a fixed name and fixed settings. Not a product, not signed, not for customers.

- `custom.json` is the configuration, `custom.txt` the same content signed by `sign-custom.mjs`. The private key is not in this repository.
- Changed in the source: the public key that verifies `custom.txt` (`src/common.rs`) and the names in `flutter/windows/runner/Runner.rc`.
- `.github/workflows/melfadesk-windows.yml` builds Windows x64 only, without the virtual display and printer drivers.
