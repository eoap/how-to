"""Ensure local/candidate runtime preparation retains shared staging and schemas."""

from copy import deepcopy
from pathlib import Path

import yaml

from how_to.release import replace_processing_image

ROOT = Path(__file__).parents[1]


def test_mastering_runtime_reuse_is_not_replaced():
    source = ROOT / "cwl-workflows/custom-types.cwl"
    document = yaml.safe_load(source.read_text())
    original = deepcopy(document)
    assert replace_processing_image(document, "localhost/how-to-rio:test") == 0
    assert document == original


def test_candidate_rewrite_retains_shared_imports_and_other_images():
    source = ROOT / "cwl-workflows/nested-workflow.cwl"
    original_bytes = source.read_bytes()
    document = yaml.safe_load(original_bytes)
    before = yaml.safe_dump(document)
    count = replace_processing_image(document, "localhost/how-to-rio:test")
    after = yaml.safe_dump(document)
    assert count == 2
    assert "localhost/how-to-rio:test" in after
    assert "docker.io/curlimages/curl@sha256:" in after
    assert (
        "$import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml" in after
    )
    assert "ghcr.io/eoap/how-to/rio@sha256:" not in after
    assert source.read_bytes() == original_bytes
    assert before != after
