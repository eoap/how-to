cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 2.0.0
$graph:
- class: Workflow
  id: main
  label: Water bodies detection based on NDWI and otsu threshold
  doc: Water bodies detection based on NDWI and otsu threshold applied to Sentinel-2
    COG STAC items
  requirements:
    ScatterFeatureRequirement: {}
    SubworkflowFeatureRequirement: {}
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    NetworkAccess:
      networkAccess: true
  inputs:
    aoi:
      label: area of interest
      doc: area of interest as a bounding box
      type: '#BBox'
    stac_items:
      label: Sentinel-2 STAC items
      doc: list of Sentinel-2 COG STAC items
      type:
        items: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
        type: array
    bands:
      label: bands used for the NDWI
      doc: bands used for the NDWI
      type:
        type: array
        items: '#SpectralBand'
      default:
      - green
      - nir
  outputs:
  - id: stac_catalog
    outputSource:
    - node_stac/stac_catalog
    type: Directory
    label: stac catalog
    doc: stac catalog for water-body detection.
  steps:
    node_water_bodies:
      run: '#detect_water_body'
      in:
        item: stac_items
        aoi: aoi
        bands: bands
      out:
      - detected_water_body
      scatter: item
      scatterMethod: dotproduct
    node_stac:
      run: '#stac'
      in:
        item: stac_items
        rasters:
          source: node_water_bodies/detected_water_body
      out:
      - stac_catalog
- class: Workflow
  id: detect_water_body
  label: Water body detection based on NDWI and otsu threshold
  doc: Water body detection based on NDWI and otsu threshold
  requirements:
    ScatterFeatureRequirement: {}
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    NetworkAccess:
      networkAccess: true
  inputs:
    aoi:
      doc: area of interest as a bounding box
      type: '#BBox'
      label: aoi
    bands:
      doc: bands used for the NDWI
      type:
        type: array
        items: '#SpectralBand'
      label: bands
    item:
      doc: STAC item
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: item
  outputs:
  - id: detected_water_body
    outputSource:
    - node_otsu/binary_mask_item
    type: File
    label: detected water body
    doc: detected water body for water-body detection.
  steps:
    node_crop:
      run: '#crop'
      in:
        item: item
        aoi: aoi
        band: bands
      out:
      - cropped
      scatter: band
      scatterMethod: dotproduct
    node_normalized_difference:
      run: '#norm_diff'
      in:
        rasters:
          source: node_crop/cropped
      out:
      - ndwi
    node_otsu:
      run: '#otsu'
      in:
        raster:
          source: node_normalized_difference/ndwi
      out:
      - binary_mask_item
- class: CommandLineTool
  id: crop
  requirements:
    InlineJavascriptRequirement: {}
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PYTHONPATH: /app
    ResourceRequirement:
      coresMin: 1
      coresMax: 1
      ramMin: 2048
      ramMax: 2048
    NetworkAccess:
      networkAccess: true
  hints:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/mastering-app-package/crop@sha256:324a0735cc4998f3f790c0e9b7a7df28e8ce8987d5f0798bd2d63c0e72d17dca
  baseCommand:
  - python
  - -m
  - app
  arguments:
  - --epsg
  - valueFrom: "${\n  var crsToEpsg = {\n    \"CRS84\": \"EPSG:4326\",\n    \"CRS84h\"\
      : \"EPSG:4979\"\n  };\n  return crsToEpsg[inputs.aoi.crs] || \"EPSG:4326\";\n\
      }\n"
  inputs:
    item:
      type: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      inputBinding:
        prefix: --input-item
        valueFrom: $( inputs.item.value )
      label: item
      doc: item for water-body detection.
    aoi:
      type: '#BBox'
      inputBinding:
        prefix: --aoi
        valueFrom: '${ return inputs.aoi.bbox.join(","); }

          '
      label: aoi
      doc: aoi for water-body detection.
    band:
      type: '#SpectralBand'
      inputBinding:
        prefix: --band
      label: band
      doc: band for water-body detection.
  outputs:
    cropped:
      outputBinding:
        glob: '*.tif'
      type: File
      label: cropped
      doc: cropped for water-body detection.
  label: crop
  doc: 'Water-body processing step: crop.'
- class: CommandLineTool
  id: norm_diff
  requirements:
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PYTHONPATH: /app
    ResourceRequirement:
      coresMin: 1
      coresMax: 1
      ramMin: 2048
      ramMax: 2048
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    NetworkAccess:
      networkAccess: true
  hints:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/mastering-app-package/norm_diff@sha256:632991ef2c15e98c46cfa1ac7dd35a638bbe4e5c434d7503a76cf3570b17383f
  baseCommand:
  - python
  - -m
  - app
  arguments: []
  inputs:
    rasters:
      type: File[]
      inputBinding:
        position: 1
      label: rasters
      doc: rasters for water-body detection.
  outputs:
    ndwi:
      outputBinding:
        glob: '*.tif'
      type: File
      label: ndwi
      doc: ndwi for water-body detection.
  label: norm_diff
  doc: 'Water-body processing step: norm_diff.'
- class: CommandLineTool
  id: otsu
  requirements:
    InlineJavascriptRequirement: {}
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PYTHONPATH: /app
    ResourceRequirement:
      coresMin: 1
      coresMax: 1
      ramMin: 2048
      ramMax: 2048
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    NetworkAccess:
      networkAccess: true
  hints:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/mastering-app-package/otsu@sha256:0541948f46a7a1a9f30f17973b7833482660f085700ccc98bb743a35a37dabae
  baseCommand:
  - python
  - -m
  - app
  arguments: []
  inputs:
    raster:
      type: File
      inputBinding:
        position: 1
      label: raster
      doc: raster for water-body detection.
  outputs:
    binary_mask_item:
      outputBinding:
        glob: '*.tif'
      type: File
      label: binary mask item
      doc: binary mask item for water-body detection.
  label: otsu
  doc: 'Water-body processing step: otsu.'
- class: CommandLineTool
  id: stac
  requirements:
    InlineJavascriptRequirement: {}
    SchemaDefRequirement:
      types:
      - $import: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml
      - name: '#CRS'
        type: enum
        symbols:
        - CRS84
      - name: '#BBox'
        type: record
        fields:
        - name: bbox
          type:
            type: array
            items: double
          doc: West, south, east, north coordinates in longitude and latitude.
        - name: crs
          type: '#CRS'
          doc: OGC CRS84 longitude and latitude.
      - name: '#SpectralBand'
        type: enum
        symbols:
        - green
        - nir
    EnvVarRequirement:
      envDef:
        PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PYTHONPATH: /app
    ResourceRequirement:
      coresMin: 1
      coresMax: 1
      ramMin: 2048
      ramMax: 2048
    NetworkAccess:
      networkAccess: true
  hints:
    DockerRequirement:
      dockerPull: ghcr.io/eoap/mastering-app-package/stac@sha256:e2ee1914cd06a0abc369034a8c8ef9ecf9b8e872b2efbc864d41c741e9faa392
  baseCommand:
  - python
  - -m
  - app
  arguments:
  - valueFrom: ${ var arr = []; for(var i=0; i<inputs.item.length; i++) { arr.push("--input-item");
      arr.push(inputs.item[i].value); } return arr; }
  inputs:
    item:
      type:
        type: array
        items: https://raw.githubusercontent.com/eoap/schemas/main/string_format.yaml#URI
      label: item
      doc: item for water-body detection.
    rasters:
      type:
        type: array
        items: File
        inputBinding:
          prefix: --water-body
      label: rasters
      doc: rasters for water-body detection.
  outputs:
    stac_catalog:
      outputBinding:
        glob: .
      type: Directory
      label: stac catalog
      doc: stac catalog for water-body detection.
  label: stac
  doc: 'Water-body processing step: stac.'
s:codeRepository: https://github.com/eoap/how-to
s:author:
- class: s:Person
  s:name: Fabrice Brito
  s:email: fabrice.brito@terradue.com
s:license: https://spdx.org/licenses/CC-BY-SA-4.0.html
