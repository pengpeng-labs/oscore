# Compatibility

[Simplified Chinese](COMPATIBILITY.zh-CN.md)

oscore 0.1.1 requires pplang, pplc, and pptc 0.4.0 plus osbare ABI v1 from
osbare 0.1.1. Its accepted machine environment is the identity-mapped x86-64
environment established by that osbare release.

Source compatibility is guaranteed only for documented v1 functions and
structures. Internal statics, table layouts, error diagnostics, and test-image
composition are not public API.
