# CWL How-To Guides

The Common Workflow Language (CWL) is a standard for describing data analysis workflows.

This collection of how-to guides provides step-by-step instructions to help EO Application Packages developer achieve their goals.

## What you'll Learn

These guides are structured to address common use cases and challenges encountered when working with CWL. 

You'll find practical solutions for tasks such as:

* Creating nested workflows for modular design.
* Using scattering to process multiple inputs in parallel.
* Building conditional workflows that adapt dynamically to inputs.
* Setting up environment variables for runtime configuration.
* Capturing and processing outputs, including JSON and files.

Each guide focuses on specific CWL features, providing clear explanations and actionable examples to help you apply the concepts in your EO Application Packages.

## Who Are These Guides For?

* Beginners: Start with foundational guides that introduce key CWL concepts.
* Intermediate Users: Learn advanced techniques like scattering and conditional workflows.
* Experts: Discover ways to optimize and modularize complex workflows.

## How to Use These Guides

* Identify Your Goal: Each guide is tailored to a specific task or feature in CWL. Browse the list to find the topic you need.
* Follow Step-by-Step Instructions: Every guide includes a practical example, detailed steps, and explanations of the concepts involved.
* Apply and Experiment: Use the examples to build and refine your workflows. Modify the samples to fit your unique requirements.

## Get Started

The Application Packages are found in the repository releases: https://github.com/eoap/how-to/releases

The documentation is available here: https://eoap.github.io/how-to/

### Using taskfile

You can use **Taskfile** to run the workflows on the cluster.

Example: 

```
task capture-json-stdout
```

will run the workflow `capture-json-stdout.cwl`


[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
## Typed CWL examples and validation

The CWL v1.2 examples embed URI and JSON records and band/CRS enums in each
application document. URI inputs use `{value: "https://..."}`. The cases in
`project.toml` include these typed values. No `cwltool --pack` is used.

Run `python scripts/cwl-docs.py --validate` to check metadata, documented ports,
and isolated CWL documents and generate Markdown. This module-local generator
is the equivalent documentation path; transpiler-mate compatibility is untested.
Run `task workflows:kubernetes` in the PDE editor to execute the ten configured
cases using the container's isolated Calrissian. Results, usage reports and logs
are saved below `/calrissian/how-to/<UTC timestamp>/`. A failure stops the suite.
The current user's UID/GID is inherited by Calrissian task pods.

Use the sibling dev-platform-eoap how-to deployment tasks for readiness,
editor/S3 checks, and environment initialization on a selected Kubernetes
context. Published releases include all standalone documents and typed test jobs.

AMD64 Kubernetes acceptance on 11 October 2026 passed all ten workflow cases,
standalone metadata/Markdown validation and deployment lifecycle checks.
The CRS enum value `EPSG4326` binds to rasterio's `EPSG:4326` CLI value.

## Reproducible release acceptance

Install the Python 3.12 environment with `uv pip sync --require-hashes requirements-notebooks.txt`. Run `scripts/check-release.py` and `scripts/cwl-docs.py --validate`, then execute all ten cases with `python scripts/run-workflows.py`. Calrissian is the default; CI uses `--runner cwltool --output /tmp/how-to-acceptance` with Podman. Both use the same typed inputs in `project.toml` and pinned runtime images. Documentation notebooks use those typed jobs as well.
