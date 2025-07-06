import argparse
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("input")
parser.add_argument("output")
parargs = parser.parse_args()

thumbnail = Image.open(parargs.input)
print("current size:", thumbnail.size)
thumbnail_resized = thumbnail.resize((144, 144), Image.Resampling.LANCZOS)
thumbnail_resized.save(parargs.output, quality=95)
