cwlVersion: v1.2
$graph:
- class: Workflow
  id: main
  requirements:
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
  inputs:
    stac-item:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: stac item
      doc: stac item.
    common-band-name:
      type: '#SpectralBand'
      label: common band name
      doc: common band name.
  outputs:
    preview:
      outputSource: step_translate/preview
      type: File
      label: preview
      doc: preview.
    json_output:
      outputSource: step_stac/asset
      type: '#JSONDocument'
      label: json output
      doc: json output.
  steps:
    step_stac:
      in:
        stac_item: stac-item
      out:
      - asset
      run: '#stac'
    step_translate:
      in:
        asset:
          source: step_stac/asset
        common_band_name: common-band-name
      out:
      - preview
      run: '#rio'
  label: main
  doc: 'capture json stdout: main.'
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
  arguments:
  - --fail
  - --location
  - --retry
  - '3'
  - -s
  - $( inputs.stac_item.value )
  inputs:
    stac_item:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: stac item
      doc: stac item.
  stdout: message
  outputs:
    asset:
      type: '#JSONDocument'
      outputBinding:
        glob: message
        loadContents: true
        outputEval: '${ return {value: JSON.stringify(JSON.parse(self[0].contents).assets)}; }'
      label: asset
      doc: asset.
  label: stac
  doc: 'capture json stdout: stac.'
- class: CommandLineTool
  id: rio
  requirements:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/how-to/rio@sha256:f4b2273ca2383bbf63c14966ad1ee25b35ccd72f73e33339951fdbe894732dbf
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
  baseCommand: rio
  arguments:
  - convert
  - --driver
  - PNG
  - --dtype
  - uint8
  - valueFrom: |
      ${
        var assets = JSON.parse(inputs.asset.value);
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
        return assets[bandKey].href;
      }
  - valueFrom: |
      ${
          return inputs.common_band_name + ".png";
      }
  inputs:
    asset:
      type: '#JSONDocument'
      label: asset
      doc: asset.
    common_band_name:
      type: '#SpectralBand'
      label: common band name
      doc: common band name.
  outputs:
    preview:
      type: File
      outputBinding:
        glob: '*.png'
      label: preview
      doc: preview.
  label: rio
  doc: 'capture json stdout: rio.'
$namespaces:
  s: https://schema.org/
s:softwareVersion: 2.0.0
s:codeRepository: https://github.com/eoap/how-to
s:license: https://spdx.org/licenses/CC-BY-SA-4.0.html
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
