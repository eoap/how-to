cwlVersion: v1.2
$graph:
- class: Workflow
  id: main
  inputs:
    tif:
      type: '#URI'
      label: tif
      doc: tif.
  outputs:
    info:
      outputSource: step-info/info
      type: string
      label: info
      doc: info.
  steps:
    step-info:
      in:
        geotif: tif
      out:
      - info
      run: '#rio'
  requirements:
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    SchemaDefRequirement:
      types:
      - name: '#URI'
        type: record
        fields:
        - name: value
          type: string
          doc: URI of the remote resource.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - red
        - green
        - blue
      - name: '#CRS'
        type: enum
        symbols:
        - native
        - EPSG4326
      - name: '#JSONDocument'
        type: record
        fields:
        - name: value
          type: string
          doc: Serialized JSON object.
  label: main
  doc: 'capture stdout: main.'
- class: CommandLineTool
  id: rio
  requirements:
    NetworkAccess:
      networkAccess: true
    InlineJavascriptRequirement: {}
    DockerRequirement:
      dockerPull: ghcr.io/eoap/how-to/rio:1.0.0
    SchemaDefRequirement:
      types:
      - name: '#URI'
        type: record
        fields:
        - name: value
          type: string
          doc: URI of the remote resource.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - red
        - green
        - blue
      - name: '#CRS'
        type: enum
        symbols:
        - native
        - EPSG4326
      - name: '#JSONDocument'
        type: record
        fields:
        - name: value
          type: string
          doc: Serialized JSON object.
    ResourceRequirement:
      coresMin: 1
      ramMin: 2048
  baseCommand: rio
  arguments:
  - info
  - $(inputs.geotif.value)
  inputs:
    geotif:
      type: '#URI'
      label: geotif
      doc: geotif.
  stdout: message
  outputs:
    info:
      type: string
      outputBinding:
        glob: message
        loadContents: true
        outputEval: $(self[0].contents)
      label: info
      doc: info.
  label: rio
  doc: 'capture stdout: rio.'
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
s:codeRepository: https://github.com/eoap/how-to
s:license: https://spdx.org/licenses/CC-BY-SA-4.0.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
