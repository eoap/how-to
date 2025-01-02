cwlVersion: v1.2

$graph:
- class: Workflow
  id: main
  requirements: 
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
  inputs:
    stac-item: 
      type: string
    common-band-name:
      type: string
  outputs:
    preview:
      outputSource: step_translate/preview
      type: File
    json_output:
      outputSource: step_stac/asset
      type: Any
  steps:
    step_stac:
      in: 
        stac_item: stac-item
      out: 
      - asset
      run:
        "#stac"
    step_translate:
      in:
        asset: 
          source: step_stac/asset
        common_band_name: common-band-name        
      out: 
      - preview
      run: 
        "#rio"

- class: CommandLineTool
  id: stac
  requirements:
    DockerRequirement: 
      dockerPull: docker.io/curlimages/curl:latest
  baseCommand: curl
  arguments: 
  - -s
  - $( inputs.stac_item )
  inputs:
    stac_item:
      type: string
  stdout: message
  outputs:
    asset: 
      type: Any
      outputBinding:
        glob: message
        loadContents: true
        outputEval: ${ return JSON.parse(self[0].contents).assets; }
- class: CommandLineTool
  id: rio
  requirements:
    DockerRequirement: 
      dockerPull: ghcr.io/eoap/how-to/rio:1.0.0
  baseCommand: rio
  arguments:
  - convert 
  - --driver
  - PNG 
  - --dtype
  - uint8
  - valueFrom: |
      ${
          let redKey = Object.keys(inputs.asset).find(key => 
              inputs.asset[key]['eo:bands'] && 
              inputs.asset[key]['eo:bands'].length === 1 &&
              inputs.asset[key]['eo:bands'].some(band => band.common_name === inputs.common_band_name)
          );
          return inputs.asset[redKey].href;
      }
  - valueFrom: |
      ${
          return inputs.common_band_name + ".png";
      }
  inputs:
    asset:
      type: Any
    common_band_name:
      type: string
  outputs:
    preview: 
      type: File
      outputBinding:
        glob: "*.png"