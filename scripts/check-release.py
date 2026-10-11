"""Check that distributed teaching packages match the release metadata."""
import json
from pathlib import Path
import re
import tomllib
import yaml

root = Path(__file__).resolve().parents[1]
version = json.loads((root / 'codemeta.json').read_text())['version']
assert re.fullmatch(r'\d+\.\d+\.\d+', version), version
project = tomllib.loads((root / 'project.toml').read_text())
assert project['project']['version'] == version
assert sum(len(w.get('tests', [])) for w in project['workflows']) == 10
files = sorted((root / 'cwl-workflows').glob('*.cwl'))
assert len(files) == 9
for path in files:
    document = yaml.safe_load(path.read_text())
    assert document['cwlVersion'] == 'v1.2'
    assert document['s:softwareVersion'] == version
    def check(value):
        if isinstance(value, dict):
            if 'dockerPull' in value:
                assert re.search(r'@sha256:[a-f0-9]{64}$', value['dockerPull']), value['dockerPull']
            for child in value.values(): check(child)
        elif isinstance(value, list):
            for child in value: check(child)
    check(document)
print(f'{len(files)} standalone release packages match {version}; ten cases and immutable images verified')
