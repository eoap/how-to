cwlVersion: v1.2
$graph:
- class: Workflow
  id: main
  inputs:
    tif:
      type: '#URI'
      label: URL to a Sentinel-2 TCI GeoTIFF
      doc: URL to a Sentinel-2 True Colour Image GeoTIFF file (TCI.tif)
  outputs:
    preview:
      outputSource: step-convert/preview
      type: File
      label: True Colour Image preview
      doc: True Colour Image preview in PNG format
  steps:
    step-convert:
      in:
        geotif: tif
      out:
      - preview
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
  doc: 'return output file: main.'
- class: CommandLineTool
  id: rio
  label: Rasterio command line tool
  doc: Convert a GeoTIFF file to a PNG file using rio convert
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
  - convert
  - --driver
  - PNG
  - --dtype
  - uint8
  - $(inputs.geotif.value)
  - preview.png
  inputs:
    geotif:
      type: '#URI'
      label: geotif
      doc: geotif.
  outputs:
    preview:
      type: File
      outputBinding:
        glob: preview.png
      label: preview
      doc: preview.
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0
s:codeRepository: https://github.com/eoap/how-to
s:license: https://spdx.org/licenses/CC-BY-SA-4.0.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
