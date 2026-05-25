from PIL import Image, ImageDraw, ImageFont
import os

BG = (13, 27, 42)       # #0D1B2A — dark navy
ACCENT = (0, 180, 216)  # cyan/teal accent

script_dir = os.path.dirname(os.path.abspath(__file__))
icon_src = os.path.join(script_dir, "icon.png")
out_dir = os.path.join(script_dir, "..", "..", "build", "store_assets")
os.makedirs(out_dir, exist_ok=True)

src = Image.open(icon_src).convert("RGBA")

# --- 1. App icon 512x512 (no transparency, Play Store requirement) ---
app_icon = Image.new("RGB", (512, 512), BG)
icon_size = 420
resized = src.resize((icon_size, icon_size), Image.LANCZOS)
offset = (512 - icon_size) // 2
app_icon.paste(resized, (offset, offset), resized)
app_icon_path = os.path.join(out_dir, "app_icon_512.png")
app_icon.save(app_icon_path, "PNG")
print(f"Saved: {app_icon_path}")

# --- 2. Feature graphic 1024x500 ---
fg = Image.new("RGB", (1024, 500), BG)
draw = ImageDraw.Draw(fg)

# Subtle accent bar at top
draw.rectangle([0, 0, 1024, 4], fill=ACCENT)

# Place icon on the left side
icon_fg_size = 260
icon_fg = src.resize((icon_fg_size, icon_fg_size), Image.LANCZOS)
icon_x = 100
icon_y = (500 - icon_fg_size) // 2
fg.paste(icon_fg, (icon_x, icon_y), icon_fg)

# App name text
try:
    font_large = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 72)
    font_small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 28)
except:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

text_x = 420
draw.text((text_x, 140), "SoundSync", fill=(255, 255, 255), font=font_large)
draw.text((text_x, 230), "Real-time Sound Transit tracking", fill=ACCENT, font=font_small)
draw.text((text_x, 272), "for the Seattle area.", fill=ACCENT, font=font_small)

fg_path = os.path.join(out_dir, "feature_graphic_1024x500.png")
fg.save(fg_path, "PNG")
print(f"Saved: {fg_path}")

print("Done! Files are in mobile/build/store_assets/")
