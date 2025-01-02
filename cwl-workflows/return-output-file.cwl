cwlVersion: v1.2

$graph:
- class: Workflow
  id: main
  inputs:
    tif: 
      type: string
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
      run:
        "#rio"

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