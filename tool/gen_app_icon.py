from PIL import Image, ImageDraw

size = 1024
# Full bleed candy icon (legacy / iOS / web)
full = Image.new("RGBA", (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(full)
for y in range(size):
    t = y / (size - 1)
    r, g, b = 0xFF, int(0x2A + (0x7E - 0x2A) * t), int(0x6D + (0x40 - 0x6D) * t)
    draw.line([(0, y), (size, y)], fill=(r, g, b, 255))


def paint_mai(draw_ctx, cx, cy, face_r):
    draw_ctx.ellipse([cx - face_r, cy - face_r, cx + face_r, cy + face_r], fill=(255, 42, 109, 255))
    draw_ctx.ellipse(
        [cx - face_r + 40, cy - face_r + 50, cx + face_r - 40, cy + int(face_r * 0.25)],
        fill=(255, 90, 140, 255),
    )
    er, ex, ey = int(face_r * 0.18), int(face_r * 0.35), int(-face_r * 0.13)
    draw_ctx.ellipse([cx - ex - er, cy + ey - er, cx - ex + er, cy + ey + er], fill=(255, 244, 232, 255))
    draw_ctx.ellipse([cx + ex - er, cy + ey - er, cx + ex + er, cy + ey + er], fill=(255, 244, 232, 255))
    pr = int(er * 0.4)
    draw_ctx.ellipse(
        [cx - ex - pr + 8, cy + ey - pr + 6, cx - ex + pr + 8, cy + ey + pr + 6],
        fill=(30, 34, 41, 255),
    )
    draw_ctx.ellipse(
        [cx + ex - pr + 8, cy + ey - pr + 6, cx + ex + pr + 8, cy + ey + pr + 6],
        fill=(30, 34, 41, 255),
    )
    arc_r = int(face_r * 0.45)
    draw_ctx.arc(
        [cx - arc_r, cy + int(face_r * 0.12), cx + arc_r, cy + int(face_r * 0.7)],
        start=20,
        end=160,
        fill=(255, 244, 232, 255),
        width=max(18, int(face_r * 0.09)),
    )
    br = int(face_r * 0.13)
    draw_ctx.ellipse([cx - int(face_r * 0.65), cy + int(face_r * 0.16), cx - int(face_r * 0.38), cy + int(face_r * 0.35)], fill=(255, 154, 168, 200))
    draw_ctx.ellipse([cx + int(face_r * 0.38), cy + int(face_r * 0.16), cx + int(face_r * 0.65), cy + int(face_r * 0.35)], fill=(255, 154, 168, 200))


paint_mai(draw, size // 2, size // 2, 310)
full.convert("RGB").save(r"e:\mai_an_learning\assets\images\branding\app_icon.png", "PNG")

# Adaptive foreground: transparent + face inset for safe zone (~66%)
fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
paint_mai(ImageDraw.Draw(fg), size // 2, size // 2, 280)
fg.save(r"e:\mai_an_learning\assets\images\branding\app_icon_foreground.png", "PNG")
print("icons ready")
