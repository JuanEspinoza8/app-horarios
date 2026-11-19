"""
Genera el ícono de la app (assets/icon/): un reloj blanco sobre azul.

  icon.png      1024x1024, ícono completo (Android viejo / legacy)
  icon_fg.png   1024x1024, solo el reloj con fondo transparente (adaptive icon)

Después: dart run flutter_launcher_icons
Uso: python scripts/gen-icon.py
"""
import math
import os

from PIL import Image, ImageDraw

AZUL = (30, 90, 168, 255)  # #1E5AA8, mismo color semilla que el tema
BLANCO = (255, 255, 255, 255)
NARANJA = (255, 183, 77, 255)
S = 1024
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "icon")


def reloj(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float):
    w = r * 0.13
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=BLANCO, width=int(w))
    # marcas de las horas
    for h in range(12):
        a = math.radians(h * 30)
        r1, r2 = r * 0.72, r * (0.84 if h % 3 else 0.80)
        d.line(
            [cx + r1 * math.sin(a), cy - r1 * math.cos(a), cx + r2 * math.sin(a), cy - r2 * math.cos(a)],
            fill=BLANCO,
            width=int(w * (0.55 if h % 3 else 0.8)),
        )
    # agujas: 4 y algo (horas extra) en naranja, minutero blanco
    def aguja(grados, largo, color, ancho):
        a = math.radians(grados)
        d.line([cx, cy, cx + largo * math.sin(a), cy - largo * math.cos(a)], fill=color, width=int(ancho))

    aguja(0, r * 0.62, BLANCO, w * 0.75)
    aguja(125, r * 0.45, NARANJA, w * 0.9)
    d.ellipse([cx - w * 0.75, cy - w * 0.75, cx + w * 0.75, cy + w * 0.75], fill=BLANCO)


def main():
    os.makedirs(OUT, exist_ok=True)

    full = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(full)
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=AZUL)
    reloj(d, S / 2, S / 2, S * 0.33)
    full.save(os.path.join(OUT, "icon.png"))

    # Adaptive: el contenido tiene que caber en el 66% central (zona segura).
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    reloj(ImageDraw.Draw(fg), S / 2, S / 2, S * 0.24)
    fg.save(os.path.join(OUT, "icon_fg.png"))
    print("OK ->", os.path.relpath(OUT, os.path.join(HERE, "..")))


if __name__ == "__main__":
    main()
