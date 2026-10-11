"""Run project.toml workflow cases through the container's Calrissian runtime."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tomllib
from datetime import datetime, timezone

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--runner', choices=['calrissian', 'cwltool'], default='calrissian')
parser.add_argument('--output', type=Path, default=Path('/calrissian/how-to'))
parser.add_argument('--case', help='Run one named case')
parser.add_argument('--skip', action='append', default=[], help='Skip an already validated case')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
config = tomllib.loads((root / 'project.toml').read_text())
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
results = args.output / stamp
results.mkdir(parents=True, exist_ok=True)
summary = []
for workflow in config['workflows']:
    for test in workflow.get('tests', []):
        if args.case and args.case != test['name']: continue
        if test['name'] in args.skip: continue
        name = test['name']
        target = results / name
        target.mkdir()
        params = target / 'params.json'
        params.write_text(json.dumps(test['params']))
        cluster = test['execution']['cluster']
        command = ['/opt/calrissian-venv/bin/calrissian', '--max-ram', cluster['max_ram'],
                   '--max-cores', str(cluster['max_cores']), '--pod-serviceaccount', cluster['pod_serviceaccount'],
                   '--tmp-outdir-prefix', str(target / 'job-tmp') + '/', '--outdir', str(target / 'results'),
                   '--usage-report', str(target / 'usage.json'), '--tool-logs-basepath', str(target / 'logs'),
                   str(root / workflow['path']), str(params)]
        if args.runner == 'cwltool':
            command = ['cwltool', '--podman', '--outdir', str(target / 'results'),
                       str(root / workflow['path']), str(params)]
        print(f'Running {name}: {workflow["path"]}', flush=True)
        with (target / 'result.json').open('w') as out, (target / 'execution.log').open('w') as err:
            run = subprocess.run(command, stdout=out, stderr=err, env=os.environ | {'CWLTOOL_OPTIONS':''})
        summary.append({'case':name,'exit_code':run.returncode,'directory':str(target)})
        (results / 'summary.json').write_text(json.dumps(summary, indent=2))
        if run.returncode:
            print((target / 'execution.log').read_text()[-6000:], flush=True)
            raise SystemExit(run.returncode)
        output = json.loads((target / 'result.json').read_text())
        assert output, f'{name}: no outputs'
        def readable(value):
            if isinstance(value,dict):
                if value.get('class')=='File':
                    path=Path(value['location'].removeprefix('file://')); assert path.is_file() and os.access(path,os.R_OK), path
                for child in value.values(): readable(child)
            elif isinstance(value,list):
                for child in value:readable(child)
        readable(output)
        if name == 'custom-types-test':
            import numpy
            import pystac
            import rasterio
            from rasterio.warp import transform_bounds
            catalog_dir = Path(output['stac_catalog']['location'].removeprefix('file://'))
            catalog = pystac.Catalog.from_file(str(catalog_dir / 'catalog.json'))
            items = list(catalog.get_all_items())
            assert len(items) == len(test['params']['stac_items']), 'Missing acquisitions in output catalog'
            for item in items:
                item.make_asset_hrefs_absolute()
                assets = [asset for asset in item.assets.values() if asset.href.endswith('.tif')]
                assert assets, f'{item.id}: no water-mask raster'
                for asset in assets:
                    with rasterio.open(asset.href) as raster:
                        assert raster.crs and raster.count == 1
                        bounds = transform_bounds(raster.crs, 'EPSG:4326', *raster.bounds)
                        expected = test['params']['aoi']['bbox']
                        assert all(abs(actual - target) < 0.02 for actual, target in zip(bounds, expected)), bounds
                        values = set(numpy.unique(raster.read(1)).tolist())
                        assert values == {0, 1}, f'{item.id}: expected land and water, got {values}'
            (target / 'scientific-check.json').write_text(json.dumps({'items': len(items), 'binary_masks': True, 'aoi_matches': True}))
        print(f'PASSED {name}', flush=True)
assert summary, 'No workflow cases selected'
print(f'All {len(summary)} cases passed; evidence: {results}', flush=True)
