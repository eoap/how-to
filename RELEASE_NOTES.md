## CWL How-To 2.0.0

The nine CWL v1.2 teaching packages now use typed URI/JSON records and band/CRS enums, embedded definitions, described ports, and validated application metadata. This changes the input contract from the earlier 1.0.0 examples. Use the updated typed cases in project.toml.

The Python 3.12 teaching environment is hash-locked. Runtime images are pinned by digest. The existing validated rio image is republished as 2.0.0 without rebuilding its contents; no runtime dependency upgrade is claimed.

Release acceptance validates all nine standalone packages and generated Markdown, executes all ten cases with real Sentinel-2 data, and builds documentation strictly. The same cases run on Kubernetes with the PDE's isolated Calrissian runtime. AMD64 is the validated architecture.

Release assets are the unchanged validated CWL documents, project.toml cases, locked Python requirements, and SHA256SUMS. Composition does not use cwltool packing. Publication runs only by explicit dispatch from main after acceptance passes.
