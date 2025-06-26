cwlVersion: v1.2

class: CommandLineTool
id: main
inputs:
  reference:
    type: string
outputs:
  staged:
    type: Directory
    outputBinding:
      glob: .
baseCommand: 
- python
- stage.py
arguments:
- $( inputs.reference )

requirements:
  cwltool:CUDARequirement:
    cudaVersionMin: "11.4"
    cudaComputeCapability: "3.0"
    cudaDeviceCountMin: 1
    cudaDeviceCountMax: 1
  DockerRequirement:
    dockerPull: ghcr.io/terradue/app-package-training-bids23/stage:1.0.0
  ResourceRequirement:
        coresMax: 2
        ramMax: 2000
        
        
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - entryname: stage.py
        entry: |-
          import subprocess
          subprocess.run(["nvidia-smi"])
          subprocess.run(["pip", "install", "cupy-cuda11x"])
          import pystac
          import stac_asset
          import asyncio
          import os
          import sys
          import cupy as cp  # GPU-backed NumPy-like library

          config = stac_asset.Config(warn=True)

          async def main(href: str):
              # STAC reading as before
              item = pystac.read_file(href)
              cwd = os.getcwd()

              # Add a dummy GPU computation (matrix multiplication)
              print("Running a dummy GPU operation...")
              a = cp.random.rand(1000, 1000)
              b = cp.random.rand(1000, 1000)
              cp.dot(a, b)  # Will be run on GPU

              cat = pystac.Catalog(
                  id="catalog",
                  description=f"catalog with staged {item.id}",
                  title=f"catalog with staged {item.id}",
              )
              cat.add_item(item)
              print(cat.describe())

              return cat

          href = sys.argv[1]
          cat = asyncio.run(main(href))
$namespaces:
  cwltool: "http://commonwl.org/cwltool#"