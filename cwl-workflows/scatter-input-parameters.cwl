cwlVersion: v1.2
$graph:
- class: Workflow
  id: main
  requirements:
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    ScatterFeatureRequirement: {}
    MultipleInputFeatureRequirement: {}
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
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
  inputs:
    stac-item:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: stac item
      doc: stac item.
    red-band:
      type: '#SpectralBand'
      default: red
      label: red band
      doc: red band.
    green-band:
      type: '#SpectralBand'
      default: green
      label: green band
      doc: green band.
    blue-band:
      type: '#SpectralBand'
      default: blue
      label: blue band
      doc: blue band.
  outputs:
    rgb-tif:
      outputSource: step_color/rgb
      type: File
      label: rgb tif
      doc: rgb tif.
  steps:
    step_curl:
      in:
        stac_item: stac-item
        common_band_name:
        - red-band
        - green-band
        - blue-band
      out:
      - hrefs
      run: '#stac'
      scatter: common_band_name
      scatterMethod: dotproduct
    step_stack:
      in:
        tiffs:
          source: step_curl/hrefs
      out:
      - stacked
      run: '#rio_stack'
    step_color:
      in:
        stacked:
          source: step_stack/stacked
      out:
      - rgb
      run: '#rio_color'
  label: main
  doc: 'scatter input parameters: main.'
- class: CommandLineTool
  id: stac
  requirements:
    DockerRequirement:
      dockerPull: docker.io/curlimages/curl@sha256:58adaa4e8dca9c988bae2aba4ab3434a0bb2da16bbe3f92dec39ec7785166777
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
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
  baseCommand: curl
  stdout: message
  arguments:
  - --fail
  - --location
  - --retry
  - '3'
  - $( inputs.stac_item.value )
  inputs:
    stac_item:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: stac item
      doc: stac item.
    common_band_name:
      type: '#SpectralBand'
      label: common band name
      doc: common band name.
  outputs:
    hrefs:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      outputBinding:
        glob: message
        loadContents: true
        outputEval: |
          ${
            var assets = JSON.parse(self[0].contents).assets;
            var keys = Object.keys(assets);
            var bandKey = null;
            for (var i = 0; i < keys.length; i++) {
              var bands = assets[keys[i]]["eo:bands"];
              if (bands && bands.length === 1 && bands[0].common_name === inputs.common_band_name) {
                bandKey = keys[i];
                break;
              }
            }
            if (!bandKey) { throw new Error("No valid asset found for band: " + inputs.common_band_name); }
            return {value: assets[bandKey].href};
          }
      label: hrefs
      doc: hrefs.
  label: stac
  doc: 'scatter input parameters: stac.'
- class: CommandLineTool
  id: rio_stack
  requirements:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/how-to/rio@sha256:f4b2273ca2383bbf63c14966ad1ee25b35ccd72f73e33339951fdbe894732dbf
    EnvVarRequirement:
      envDef:
        GDAL_TIFF_INTERNAL_MASK: 'YES'
        GDAL_HTTP_MERGE_CONSECUTIVE_RANGES: 'YES'
        CPL_VSIL_CURL_ALLOWED_EXTENSIONS: .tif
    InitialWorkDirRequirement:
      listing:
      - entryname: run.sh
        entry: |-
          #!/bin/bash
          rio stack $@
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
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
  baseCommand:
  - /bin/bash
  - run.sh
  arguments:
  - valueFrom: "${  \n  var arr = [];\n  for(var i=0; i<inputs.tiffs.length; i++) {\n      arr.push(inputs.tiffs[i].value);\
      \ \n  }\n  return arr; \n  }\n"
  - stacked.tif
  inputs:
    tiffs:
      type:
        type: array
        items: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: tiffs
      doc: tiffs.
  outputs:
    stacked:
      type: File
      outputBinding:
        glob: stacked.tif
      label: stacked
      doc: stacked.
  label: rio stack
  doc: 'scatter input parameters: rio stack.'
- class: CommandLineTool
  id: rio_color
  requirements:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/how-to/rio@sha256:f4b2273ca2383bbf63c14966ad1ee25b35ccd72f73e33339951fdbe894732dbf
    InitialWorkDirRequirement:
      listing:
      - entryname: run.sh
        entry: |-
          #!/bin/bash
          rio color -j -1 --out-dtype uint8 $1 rgb.tif "gamma 3 0.95, sigmoidal rgb 35 0.13"
    InlineJavascriptRequirement: {}
    NetworkAccess:
      networkAccess: true
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
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
      ramMin: 4096
  baseCommand:
  - /bin/bash
  - run.sh
  arguments:
  - $( inputs.stacked.path )
  inputs:
    stacked:
      type: File
      label: stacked
      doc: stacked.
  outputs:
    rgb:
      type: File
      outputBinding:
        glob: rgb.tif
      label: rgb
      doc: rgb.
  label: rio color
  doc: 'scatter input parameters: rio color.'
$namespaces:
  s: https://schema.org/
s:softwareVersion: 2.0.0
s:codeRepository: https://github.com/eoap/how-to
s:license: https://spdx.org/licenses/CC-BY-SA-4.0.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
