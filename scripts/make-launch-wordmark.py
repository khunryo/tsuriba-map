from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "og.png"
OUTPUT = ROOT / "assets" / "shiome-wordmark-transparent.png"
PREVIEW = ROOT / "artifacts" / "shiome-launch-wordmark-preview.png"

# Exact old 潮目 artwork area; excludes the tagline beneath it.
crop = Image.open(SOURCE).convert("RGB").crop((140, 310, 625, 565))
background = crop.filter(ImageFilter.GaussianBlur(30))
logo = Image.new("RGBA", crop.size, (0, 0, 0, 0))

source_pixels = crop.load()
background_pixels = background.load()
output_pixels = logo.load()
for y in range(crop.height):
    for x in range(crop.width):
        source = source_pixels[x, y]
        base = background_pixels[x, y]
        delta = tuple(max(0, source[i] - base[i]) for i in range(3))
        strength = max(delta)
        alpha = max(0, min(255, round((strength - 8) * 255 / 135)))
        if alpha < 5:
            continue
        peak = max(1, strength)
        color = tuple(max(0, min(255, round(channel * 255 / peak))) for channel in delta)
        output_pixels[x, y] = (*color, alpha)

bounds = logo.getbbox()
if not bounds:
    raise RuntimeError("Wordmark extraction produced an empty image")
logo = logo.crop((max(0, bounds[0] - 8), max(0, bounds[1] - 8), min(logo.width, bounds[2] + 8), min(logo.height, bounds[3] + 8)))
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
logo.save(OUTPUT, optimize=True)

launch_background = Image.open(ROOT / "assets" / "launch-bg-portrait-v1.png").convert("RGBA")
preview_width = 420
preview_height = round(launch_background.height * preview_width / launch_background.width)
preview = launch_background.resize((preview_width, preview_height), Image.Resampling.LANCZOS)
logo_width = 147
logo_height = round(logo.height * logo_width / logo.width)
logo_preview = logo.resize((logo_width, logo_height), Image.Resampling.LANCZOS)
preview.alpha_composite(logo_preview, ((preview_width - logo_width) // 2, round(preview_height * 0.29)))
PREVIEW.parent.mkdir(parents=True, exist_ok=True)
preview.convert("RGB").save(PREVIEW, quality=92)

print(f"created {OUTPUT} ({logo.width}x{logo.height})")
print(f"created {PREVIEW} ({preview.width}x{preview.height})")
