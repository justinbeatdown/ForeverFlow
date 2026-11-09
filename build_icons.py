from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parent / "ForeverFlow" / "Media"
source = Image.open(ROOT / "OfficialCircle.tga").convert("RGBA")
# Crop only the castle, quest banner, compass and glowing path from the
# approved logo. At 30px, the full logo's lettering is unreadable.
scene = source.crop((69, 7, 189, 127)).resize((224, 224), Image.Resampling.LANCZOS)
scene = ImageEnhance.Contrast(scene).enhance(1.2)
scene = ImageEnhance.Sharpness(scene).enhance(1.25)

badge = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
draw = ImageDraw.Draw(badge)
draw.ellipse((12, 12, 244, 244), fill=(11, 13, 23, 255),
             outline=(203, 129, 31, 255), width=9)
mask = Image.new("L", (224, 224), 0)
ImageDraw.Draw(mask).ellipse((0, 0, 223, 223), fill=255)
badge.paste(scene, (16, 16), mask)
draw = ImageDraw.Draw(badge)
draw.ellipse((12, 12, 244, 244), outline=(253, 183, 60, 255), width=7)
draw.ellipse((19, 19, 237, 237), outline=(70, 36, 12, 215), width=3)
badge.save(ROOT / "GuideLogoSmall.tga", compression=None)

minimap = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
minimap.paste(badge.resize((232, 232), Image.Resampling.LANCZOS), (12, 12))
minimap.save(ROOT / "MinimapIconRound.tga", compression=None)
