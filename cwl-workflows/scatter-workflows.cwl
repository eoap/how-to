cwlVersion: v1.2

$graph:
- class: Workflow
  id: main
  requirements: 
    SubworkflowFeatureRequirement: {}
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    ScatterFeatureRequirement: {}
  inputs:
    stac-items: 
      type: string[]
    bands:
      type: string[]
      default: ["red", "green", "blue"]
  outputs:
    rgb-tif:
      outputSource: step_rgb_composite/rgb-tif
      type: File[]
  steps:
    step_rgb_composite:
      in: 
        stac-item: stac-items
        bands: bands
      out: 
      - rgb-tif
      run:
        "#rgb-composite"
      scatter: stac-item
      scatterMethod: dotproduct

- class: Workflow
  id: rgb-composite
  requirements: 
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    ScatterFeatureRequirement: {}
  inputs:
    stac-item: 
      type: string
    bands:
      type: string[]
  outputs:
    rgb-tif:
      outputSource: step_color/rgb
      type: File
  steps:
    step_curl:
      in: 
        stac_item: stac-item
        common_band_name: bands
      out: 
      - hrefs
      run:
        "#stac"
      scatter: common_band_name
      scatterMethod: dotproduct
    step_stack:
      in:
        tiffs: 
          source: step_curl/hrefs
      out:
      - stacked
      run:
        "#rio_stack"
    step_color:
      in:
        stacked:
          source: step_stack/stacked
      out:
      - rgb
      run:
        "#rio_color"

- class: CommandLineTool
  id: stac
  requirements:
    DockerRequirement: 
      dockerPull: docker.io/curlimages/curl:latest
  baseCommand: curl
  stdout: message
  arguments: 
  - $( inputs.stac_item )
  inputs:
    stac_item:
      type: string
    common_band_name:
      type: string
  outputs:
    hrefs: 
      type: string
      outputBinding:
        glob: message
        loadContents: true
        outputEval: |
          ${
            const assets = JSON.parse(self[0].contents).assets;
            const bandKey = Object.keys(assets).find(key =>
              assets[key]['eo:bands'] &&
              assets[key]['eo:bands'].length === 1 &&
              assets[key]['eo:bands'].some(band => band.common_name === inputs.common_band_name)
            );
            if (!bandKey) {
              throw new Error(`No valid asset found for band: ${inputs.common_band_name}`);
            }
            return assets[bandKey].href;
          }
- class: CommandLineTool
  id: rio_stack
  requirements:
    DockerRequirement: 
      dockerPull: ghcr.io/eoap/how-to/rio:1.0.0
    EnvVarRequirement:
      envDef:
        GDAL_TIFF_INTERNAL_MASK: YES
        GDAL_HTTP_MERGE_CONSECUTIVE_RANGES: YES
        CPL_VSIL_CURL_ALLOWED_EXTENSIONS: ".tif"
  baseCommand: rio
  arguments:
  - stack
  - valueFrom: |
      ${  
        var arr = [];
        for(var i=0; i<inputs.tiffs.length; i++) {
            arr.push(inputs.tiffs[i]); 
        }
        return arr; 
        }
  - stacked.tif
  inputs:
    tiffs:
      type: string[]
  outputs:
    stacked:
      type: File
      outputBinding:
        glob: stacked.tif
- class: CommandLineTool
  id: rio_color
  requirements:
    DockerRequirement: 
      dockerPull: ghcr.io/eoap/how-to/rio:1.0.0
  baseCommand: rio
  arguments:
  - color
  - -j
  - "-1"
  - --out-dtype 
  - uint8
  - $( inputs.stacked.path )
  - rgb.tif
  - "gamma 3 0.95, sigmoidal rgb 35 0.13"
  inputs:
    stacked:
      type: File
  outputs:
    rgb:
      type: File
      outputBinding:
        glob: rgb.tif