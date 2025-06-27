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
          import sys
          import os
          import asyncio

          # Verify GPU presence with nvidia-smi
          subprocess.run(["nvidia-smi"])

          # Install dependencies (you can add more if needed)
          subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "tensorflow"])
          import tensorflow as tf
          from tensorflow.keras import layers, models
          async def main(href: str):
              

              # Minimal TensorFlow GPU test training on 10 MNIST samples

              # Check GPU availability
              gpus = tf.config.list_physical_devices('GPU')
              if gpus:
                  print("✅ GPU is available")
              else:
                  print("❌ GPU is NOT available")

              # Load MNIST data, but only 10 samples
              (x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
              x_train, y_train = x_train[:10], y_train[:10]
              x_test, y_test = x_test[:10], y_test[:10]

              x_train = x_train / 255.0
              x_test = x_test / 255.0

              x_train = x_train[..., tf.newaxis]
              x_test = x_test[..., tf.newaxis]

              # Build simple model
              model = models.Sequential([
                  layers.Input(shape=(28, 28, 1)),
                  layers.Flatten(),
                  layers.Dense(32, activation='relu'),
                  layers.Dense(10, activation='softmax')
              ])

              model.compile(optimizer='adam',
                            loss='sparse_categorical_crossentropy',
                            metrics=['accuracy'])

              # Train model (3 epochs, batch size 2)
              model.fit(x_train, y_train, epochs=3, batch_size=2)

              # Evaluate on test samples
              test_loss, test_acc = model.evaluate(x_test, y_test)
              print(f"Test accuracy on 10 samples: {test_acc:.4f}")

              return test_acc

          href = sys.argv[1]
          test_acc = asyncio.run(main(href))
$namespaces:
  cwltool: "http://commonwl.org/cwltool#"
