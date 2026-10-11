# Define custom input types

The standalone `cwl-workflows/custom-types.cwl` defines a URI record, a BBox record, and CRS and spectral-band enums inside SchemaDefRequirement. No external type file is needed. The URI record carries a STAC item URL in `value`; BBox carries west, south, east, north coordinates in `bbox` and `CRS84` in `crs`.

The example crops green and near-infrared bands from three real Sentinel-2 acquisitions around Lake Almanor, California, computes NDWI and an Otsu water mask, and returns a STAC catalog containing the masks. The job is `cwl-workflows/custom-types.yaml`; the same inputs are registered in `project.toml` for CI and Kubernetes acceptance.

```bash
python scripts/run-workflows.py --case custom-types-test
```

To run with a local Podman runtime:

```bash
python scripts/run-workflows.py --runner cwltool --case custom-types-test --output /tmp/how-to-acceptance
```

Band values must be `green` or `nir`, and the bounding-box CRS must be `CRS84`. CWL validates the records and enums before processing. Raster processing uses immutable container image digests.
