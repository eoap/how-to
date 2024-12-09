cwlVersion: v1.2

$graph:
- class: Workflow
  id: main
  inputs:
    tif: 
      type: string
  outputs:
    preview: 
      outputSource: step-convert/preview
      type: File
  steps:
    step-convert:
      in: 
        geotif: tif
      out: 
      - preview
      run:
        "#rio"

- class: CommandLineTool
  id: rio
  requirements:
    NetworkAccess:
      networkAccess: true
    InlineJavascriptRequirement: {}
    DockerRequirement: 
      dockerPull: ghcr.io/eoap/how-to/how-to-container:1.1.0
  baseCommand: rio
  arguments: 
  - convert
  - --driver
  - PNG 
  - --dtype
  - uint8
  - $(inputs.geotif)
  - preview.png
  inputs:
    geotif:
      type: string
  outputs:
    preview: 
      type: File
      outputBinding:
        glob: preview.png