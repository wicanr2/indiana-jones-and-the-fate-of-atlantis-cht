#!/usr/bin/env python3
"""Design two Chinese title graphics for the FOA title screen, styled to match:
  main : 印第安納·瓊斯   -> INDIANA JONES  (heavy, orange->gold gradient, dark outline)
  sub  : 亞特蘭提斯之謎   -> FATE OF ATLANTIS (yellow gradient, italic, dark outline)
Render big then nearest-downscale for crisp retro pixels. Also composite a preview
onto the real title screenshot so the look can be eyeballed before engine work.
"""
from PIL import Image, ImageDraw, ImageFont
import os

FONT = next(p for p in [
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"] if os.path.exists(p))
SCALE = 6

def render(text, ch_h, top, bot, outline, shear):
    H = ch_h*SCALE; pad = 1*SCALE
    font = ImageFont.truetype(FONT, int(H*0.95), index=0)
    tmp = Image.new("RGBA",(10,10)); d=ImageDraw.Draw(tmp)
    bb = d.textbbox((0,0), text, font=font); tw=bb[2]-bb[0]; 
    W = tw+pad*2
    big = Image.new("RGBA",(W,H+pad*2),(0,0,0,0)); db=ImageDraw.Draw(big)
    ox,oy = pad-bb[0], pad-bb[1]
    for dx in range(-SCALE,SCALE+1,SCALE):
        for dy in range(-SCALE,SCALE+1,SCALE):
            if dx or dy: db.text((ox+dx,oy+dy),text,font=font,fill=outline)
    mask=Image.new("L",big.size,0); dm=ImageDraw.Draw(mask); dm.text((ox,oy),text,font=font,fill=255)
    grad=Image.new("RGBA",big.size,(0,0,0,0)); gp=grad.load()
    for y in range(big.size[1]):
        t=y/max(1,big.size[1]-1)
        c=(int(top[0]*(1-t)+bot[0]*t),int(top[1]*(1-t)+bot[1]*t),int(top[2]*(1-t)+bot[2]*t),255)
        for x in range(big.size[0]):
            if mask.getpixel((x,y))>110: gp[x,y]=c
    big=Image.alpha_composite(big,grad)
    if shear:
        w2=big.size[0]+int(big.size[1]*shear)
        big=big.transform((w2,big.size[1]),Image.AFFINE,(1,shear,-big.size[1]*shear,0,1,0),resample=Image.BILINEAR)
    return big.resize((max(1,big.size[0]//SCALE),max(1,big.size[1]//SCALE)),Image.NEAREST)

# main: orange->gold like the INDIANA JONES logo, heavier, tiny slant
main = render("印第安納·瓊斯", 11, (255,150,30), (250,205,0), (70,28,0,255), 0.10)
# sub: yellow italic like FATE OF ATLANTIS
sub  = render("亞特蘭提斯之謎", 10, (255,235,95),(214,150,0), (60,30,0,255), 0.18)
main.save("design_title/cht_main.png"); sub.save("design_title/cht_sub.png")
print("main",main.size,"sub",sub.size)

# ---- preview composite onto the real title screenshot ----
shot = Image.open("screenshots/title/t31.png").convert("RGBA")
# game(320x200) -> screenshot px:  img = 160 + g*3 (x),  180 + g*3 (y)  [scale 3]
def place(layer, gx_center, gy_top):
    L = layer.resize((layer.size[0]*3, layer.size[1]*3), Image.NEAREST)
    ix = int(160 + gx_center*3 - L.size[0]/2); iy = int(180 + gy_top*3)
    shot.alpha_composite(L,(ix,iy))
place(main, 160, 123)
place(sub , 160, 134)
shot.convert("RGB").save("design_title/preview.png")
print("preview saved")

# ---- bake atlantis_title.spr for the engine overlay ----
import struct
GX_C, MAIN_Y, SUB_Y = 160, 123, 134
mx = GX_C - main.size[0]//2; sx = GX_C - sub.size[0]//2
left = min(mx, sx); right = max(mx+main.size[0], sx+sub.size[0])
top = MAIN_Y; bottom = SUB_Y + sub.size[1]
W = right-left; H = bottom-top
canvas = Image.new("RGBA",(W,H),(0,0,0,0))
canvas.alpha_composite(main,(mx-left, MAIN_Y-top))
canvas.alpha_composite(sub ,(sx-left, SUB_Y-top))
px = canvas.load()
with open("game/atlantis_title.spr","wb") as f:
    f.write(struct.pack("<HHHH", left, top, W, H))
    for y in range(H):
        for x in range(W):
            r,g,b,a = px[x,y]
            f.write(struct.pack("BBBB", r,g,b, 255 if a>=128 else 0))
print(f"spr: pos=({left},{top}) size=({W}x{H})  bytes={16+W*H*4}")
