"""Prepare standalone release documents using the accepted published runtime digest."""

import argparse
import re
from pathlib import Path

import yaml

from how_to.release import replace_processing_image

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--image", required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
if not re.fullmatch(r"ghcr\.io/eoap/how-to/rio@sha256:[a-f0-9]{64}", args.image):
    parser.error("A published How-To runtime digest is required")
root = Path(__file__).resolve().parents[1]
args.output.mkdir(parents=True, exist_ok=True)
for source in sorted((root / "cwl-workflows").glob("*.cwl")):
    document = yaml.safe_load(source.read_text())
    replace_processing_image(document, args.image)
    (args.output / source.name).write_text(yaml.safe_dump(document, sort_keys=False))
