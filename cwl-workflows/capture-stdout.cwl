cwlVersion: v1.2

$graph:
- class: Workflow
  id: main
  inputs:
    tif: 
      type: string
  outputs:
    info: 
      outputSource: step-info/info
      type: string
  steps:
    step-info:
      in: 
        geotif: tif
      out: 
      - info
      run:
        "#rio"

- class: CommandLineTool
  id: rio
  requirements:
    NetworkAccess:
      networkAccess: true
    InlineJavascriptRequirement: {}
    DockerRequirement: 
      dockerPull: ghcr.io/eoap/how-to/rio:1.0.0
  baseCommand: rio
  arguments: 
  - info
  - $(inputs.geotif)
  inputs:
    geotif:
      type: string
  stdout: message
  outputs:
    info: 
      type: string
      outputBinding:
        glob: message
        loadContents: true
        outputEval: $(self[0].contents)