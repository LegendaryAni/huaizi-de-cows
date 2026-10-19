"""Build a non-destructive HD floor layer and physical prop footprints.
Placements replay tools/prepare_scifi_art.py world(), including floor RNG calls.
Original map.png and authored sprites remain untouched.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter
import random, json, hashlib, math

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/sprites/scifi"
SEED = 20261017
W, H = 4096, 2305

def place():
    rng = random.Random(SEED)
    for y in range(0, H, 96):
        for x in range(0, W, 96):
            rng.randrange(4)
    decorations = []
    for i in range(58):
        x = rng.randrange(230, 3860)
        y = rng.randrange(230, 2080)
        if abs(x-2048)<450 and abs(y-1152)<330:
            continue
        kind = rng.choice([0,1,2,4,5,6,7])
        decorations.append((x,y,kind))
    return decorations

def make():
    decorations = place()
    props = {i: Image.open(ASSETS/f"props/prop-{i}.png").convert("RGBA") for i in [0,1,2,4,5,6,7]}
    footprints = []
    for x,y,kind in decorations:
        im = props[kind].getchannel("A")
        # Physical footprint is only the bottom solid base, not transparent overhead art.
        bbox = im.crop((0,64,96,90)).point(lambda v: 255 if v > 80 else 0).getbbox()
        if bbox is None:
            bbox = (23,2,73,22)
        bx0,_,bx1,_ = bbox
        left = x + max(22, 2*bx0+8)
        right = x + min(170, 2*bx1-8)
        top = y + 135
        bottom = y + 175
        if right - left < 40: right = left + 40
        footprints.append({"kind":kind,"rect":[left,top,right-left,bottom-top],
                           "art_rect":[x,y,192,192]})
    artifact = {"version":1,"source_seed":SEED,"map_size":[W,H],
                "generation":"authoritative map composition script RNG placements; alpha-footprint at prop base",
                "obstacles":footprints}
    (ASSETS/"map_obstacles.json").write_text(json.dumps(artifact,ensure_ascii=False,indent=2),encoding="utf8")
    # Improve the coarse 3x floor material at native 4096 pixels with subtle high-frequency
    # brushed steel detail. Preserve the original authored fixtures and layout.
    original = Image.open(ASSETS/"map.png").convert("RGB")
    image = original.copy()
    detail = Image.new("RGBA",(W,H),(0,0,0,0))
    draw = ImageDraw.Draw(detail,"RGBA")
    rng = random.Random(20261019)
    for gy in range(0,H,96):
        for gx in range(0,W,96):
            if (gx+gy//2)%192==0:
                draw.line([(gx+5,gy+3),(min(W-1,gx+91),gy+3)],fill=(102,158,165,14),width=1)
            # Thin brushed-metal scratches are visible at high resolution but never cover art.
            for j in range(4):
                yy=gy+rng.randint(9,84);xx=gx+rng.randint(8,78)
                draw.line([(xx,yy),(min(W-1,xx+rng.randint(4,24)),yy)],
                          fill=(168,184,177,rng.randint(8,18)),width=1)
            if rng.randrange(9)==0:
                px,py=gx+12,gy+12
                draw.ellipse((px,py,px+2,py+2),fill=(45,171,180,45))
    # Keep all prop features from original map intact by compositing low-opacity grain only.
    image = Image.alpha_composite(image.convert("RGBA"),detail)
    image.save(ASSETS/"map_detail.png",optimize=True)
    print("PROPS",len(footprints),"MAP",image.size,
          "MIN_DIST_FROM_SPAWN",round(min(math.hypot((a["rect"][0]+a["rect"][2]/2)-2048,
                        (a["rect"][1]+a["rect"][3]/2)-1152) for a in footprints)),
          "MAP_SHA256",hashlib.sha256((ASSETS/"map_detail.png").read_bytes()).hexdigest())

if __name__=="__main__": make()
