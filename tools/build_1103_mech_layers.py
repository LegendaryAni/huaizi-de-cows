"""Generate original large, independently articulated 1103 mech layers.
This script is asset production only; Godot owns all runtime animation.
Canvas: 1200 x 1400, artwork drawn at twice target resolution, downsampled.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
from pathlib import Path
import math, random, json
import numpy as np
W,H,AA=1200,1400,2
ROOT=Path("assets/sprites/ui/runtime/scifi/v3_mech_layers")
ROOT.mkdir(parents=True,exist_ok=True)
PALETTES={
"border":(15,24,29,255),"dark":(28,38,45,255),"steel":(51,66,73,255),
"slate":(70,88,95,255),"shadow":(35,38,36,255),
"gold":(201,137,55,255),"ochre":(172,111,43,255),"yellow":(238,181,75,255),
"highlight":(252,212,125,255),"blue":(82,198,238,255),"navy":(22,72,89,255),
"silver":(170,181,169,255),"black":(8,15,18,255),
"burn":(95,57,34,255)}
def pts(coords):return [(int(x*AA),int(y*AA)) for x,y in coords]
def rect(coords):return tuple(int(v*AA) for v in coords)
def p(draw,coords,fill,outline="border",width=6):
 draw.polygon(pts(coords),fill=PALETTES.get(fill,fill))
 if outline:draw.line(pts(coords+[coords[0]]),fill=PALETTES.get(outline,outline),width=width*AA,joint="curve")
def line(draw,coords,color="steel",width=5):
 draw.line(pts(coords),fill=PALETTES.get(color,color),width=AA*width,joint="curve")
def oval(draw,c,fill,outline=None,width=4):
 draw.ellipse(rect(c),fill=PALETTES.get(fill,fill),outline=PALETTES.get(outline,outline) if outline else None,width=AA*width)
def bolt(draw,x,y,r=6):
 oval(draw,(x-r,y-r,x+r,y+r),"border")
 oval(draw,(x-r+2,y-r+2,x+r-2,y+r-2),"silver")
 line(draw,[(x-r//2,y),(x+r//2,y)],"border",2)
def vent(draw,x,y,w,h):
 p(draw,[(x,y+8),(x+10,y),(x+w-9,y),(x+w,y+8),(x+w-2,y+h),(x+2,y+h)],"black","steel",3)
 for t in range(7,h-8,13):line(draw,[(x+10,y+t),(x+w-10,y+t-1)],"slate",4)
def armor(draw,coords,shade="gold",dark="ochre",trim="highlight"):
 p(draw,coords,shade,"border",7)
 x0=min(x for x,y in coords);x1=max(x for x,y in coords);y0=min(y for x,y in coords);y1=max(y for x,y in coords)
 # Faceted inset, polished top plate and dirty lower strip.
 if x1-x0>35 and y1-y0>35:
  p(draw,[(x0+13,y0+11),(x1-20,y0+16),(x1-31,y0+32),(x0+20,y0+31)],trim,None)
  p(draw,[(x0+14,y1-31),(x1-23,y1-38),(x1-11,y1-14),(x0+14,y1-12)],dark,None)
  line(draw,[(x0+18,y0+39),(x0+16,y1-37)],"burn",3)
def save_layer(name,drawfn):
 im=Image.new("RGBA",(W*AA,H*AA),(0,0,0,0));d=ImageDraw.Draw(im,"RGBA")
 drawfn(d)
 # Warm exhaust stains and scratches integrated only into drawn armor pixels.
 sm=im.resize((W,H),Image.Resampling.LANCZOS)
 # Weathering and metal micrograin, deterministic for repeatable asset builds.
 seed=sum((i+1)*ord(ch) for i,ch in enumerate(name))+1103
 generator=np.random.default_rng(seed)
 arr=np.asarray(sm,dtype=np.uint8).copy()
 coarse=generator.normal(0,7,(H//8,W//8))
 coarse=np.asarray(Image.fromarray(np.float32(coarse)).resize((W,H),Image.Resampling.BILINEAR))
 variation=np.clip(coarse+generator.normal(0,2.7,(H,W)),-17,17)
 rgb=np.asarray(arr[:,:,:3],dtype=np.float32)
 mask=np.asarray(arr[:,:,3]>96)
 rgb[mask]=np.clip(rgb[mask]+variation[mask,None],0,255)
 arr[:,:,:3]=np.uint8(rgb)
 sm=Image.fromarray(arr,'RGBA')
 overlay=Image.new('RGBA',(W,H));d=ImageDraw.Draw(overlay,'RGBA')
 bbox=sm.getchannel('A').getbbox()
 if bbox:
  prng=random.Random(seed)
  x0,y0,x1,y1=bbox
  for t in range(850):
   x=prng.randint(x0,max(x0,x1-1));y=prng.randint(y0,max(y0,y1-1))
   length=prng.randint(5,43)
   rgba=(251,234,182,prng.randint(18,66)) if t%3==0 else (17,25,24,prng.randint(17,58))
   d.line((x,y,x+length,y-prng.randint(0,9)),fill=rgba,width=prng.choice([1,1,2]))
  overlay.putalpha(ImageChops.multiply(overlay.getchannel('A'),sm.getchannel('A')))
  sm=Image.alpha_composite(sm,overlay)
 sm.save(ROOT/(name+".png"),optimize=True)
 print(name, (ROOT/(name+".png")).stat().st_size)
def backpack(d):
 p(d,[(350,320),(435,270),(758,268),(850,330),(875,605),(318,607)],"dark")
 armor(d,[(342,322),(430,305),(453,566),(318,585)],"slate","dark","silver")
 armor(d,[(750,305),(834,325),(884,586),(745,565)],"slate","dark","silver")
 for x in (386,773):
  oval(d,(x-45,270,x+40,357),"black","steel",8)
  oval(d,(x-24,284,x+20,334),"blue","navy",6)
  p(d,[(x-34,316),(x+29,315),(x+34,352),(x-37,353)],"ochre")
 for y in (355,415,480,545):
  line(d,[(355,y),(385,y+8)],"silver",5)
  line(d,[(815,y+8),(841,y)],"silver",5)
def legs(d):
 for side in (-1,1):
  mx=455 if side==-1 else 741
  def shift(v):return (v-455 if side==-1 else v-741)+mx
  # Outer independent leg assemblies: joint / thigh / shin / foot.
  if side==-1:
   c=[(405,710),(534,725),(540,896),(396,914)]
   shin=[(402,887),(550,888),(555,1129),(375,1146)]
   foot=[(361,1115),(526,1105),(564,1223),(515,1255),(324,1253),(313,1202)]
   knee=(450,895)
  else:
   c=[(679,727),(812,709),(833,913),(682,897)]
   shin=[(668,882),(819,888),(850,1151),(672,1130)]
   foot=[(686,1105),(859,1112),(899,1205),(892,1251),(693,1255),(652,1226)]
   knee=(764,896)
  p(d,c,"steel")
  armor(d,c,"gold","ochre","yellow")
  oval(d,(knee[0]-58,knee[1]-47,knee[0]+58,knee[1]+48),"black","slate",9)
  oval(d,(knee[0]-22,knee[1]-22,knee[0]+22,knee[1]+22),"navy","silver",6)
  armor(d,shin,"gold","ochre","yellow")
  p(d,foot,"steel")
  armor(d,foot,"ochre","burn","yellow")
  for tx in [foot[0][0]+18,foot[0][0]+72,foot[0][0]+116]:
   line(d,[(tx,1201),(tx-12,1239)],"border",7)
  # piston articulation
  line(d,[(knee[0]+(35 if side==-1 else -35),960),(knee[0]+(42 if side==-1 else -42),1081)],"silver",12)
  bolt(d,knee[0],knee[1],14)
def torso(d):
 # Main black skeleton behind chest panels and breastplate.
 p(d,[(446,348),(760,355),(845,460),(818,738),(743,813),(420,810),(372,713),(354,448)],"dark","border",15)
 armor(d,[(391,390),(474,356),(753,365),(815,420),(781,577),(429,595)],"gold","ochre","highlight")
 p(d,[(483,421),(708,412),(739,506),(680,564),(494,551),(464,497)],"steel","border",7)
 p(d,[(505,446),(681,439),(707,486),(675,535),(511,533),(484,483)],"navy","black",7)
 p(d,[(525,459),(659,451),(671,483),(641,501),(523,503)],"slate","silver",4)
 p(d,[(543,465),(643,463),(651,479),(536,485)],"blue",None)
 p(d,[(450,588),(744,580),(777,632),(746,741),(691,786),(483,791),(410,741),(420,624)],"steel")
 for x in [446,503,564,627,690,746]:
  p(d,[(x,604),(x+28,607),(x+26,706),(x+1,704)],"dark",None)
 armor(d,[(465,652),(718,650),(741,750),(704,786),(484,784),(450,741)],"ochre","burn","yellow")
 vent(d,526,689,132,46)
 for x,y in [(431,419),(774,418),(458,729),(729,728)]:
  bolt(d,x,y,9)
def left_arm(d):
 # Arm on image left: industrial shoulder armor + elbow and hydraulic forearm.
 p(d,[(325,376),(446,385),(487,500),(423,621),(294,608),(261,491)],"dark")
 oval(d,(275,454,437,618),"black","steel",12)
 armor(d,[(247,373),(368,339),(453,390),(451,532),(396,597),(270,556)],"gold","ochre","yellow")
 p(d,[(267,409),(386,386),(413,439),(387,478),(284,489)],"slate")
 line(d,[(293,417),(375,409)],"blue",12)
 bolt(d,421,507,12)
 armor(d,[(293,563),(430,579),(422,726),(315,765),(259,710)],"steel","dark","silver")
 p(d,[(281,600),(381,590),(406,663),(364,694),(278,669)],"ochre")
 vent(d,324,622,53,43)
 oval(d,(289,711,429,805),"dark","border",8)
 armor(d,[(265,762),(414,764),(428,956),(372,1024),(250,983),(229,913)],"gold","ochre","yellow")
 p(d,[(246,923),(391,925),(389,1000),(273,1001)],"steel")
 bolt(d,298,939,7)
 for y in (819,857,895):line(d,[(269,y),(296,y-2)],"silver",4)
def right_arm(d):
 p(d,[(767,376),(887,389),(950,502),(924,631),(781,616),(747,499)],"dark")
 oval(d,(786,463,942,618),"black","steel",12)
 armor(d,[(775,380),(860,347),(968,384),(990,531),(923,593),(775,535)],"gold","ochre","yellow")
 p(d,[(809,414),(946,411),(950,469),(847,493),(796,456)],"slate")
 line(d,[(835,434),(929,443)],"blue",12)
 bolt(d,795,517,12)
 armor(d,[(814,581),(943,571),(984,727),(922,775),(800,726)],"steel","dark","silver")
 p(d,[(840,612),(929,614),(942,673),(858,697)],"ochre")
 vent(d,855,636,63,50)
 oval(d,(811,719,950,809),"dark","border",8)
 armor(d,[(820,760),(967,750),(996,897),(971,986),(850,1018),(795,939)],"gold","ochre","yellow")
 p(d,[(839,921),(972,918),(961,989),(831,1000)],"steel")
 bolt(d,927,954,9)
 for y in (813,851,888):line(d,[(932,y),(962,y-2)],"silver",4)
def head(d):
 p(d,[(506,231),(693,223),(742,314),(702,403),(506,395),(459,313)],"dark","border",11)
 armor(d,[(492,232),(692,230),(729,294),(712,339),(486,334),(476,293)],"gold","ochre","yellow")
 p(d,[(513,286),(680,283),(696,345),(675,373),(514,373),(493,338)],"steel")
 p(d,[(513,300),(667,300),(682,322),(667,345),(522,346),(506,325)],"navy","black",8)
 p(d,[(523,313),(656,311),(661,328),(525,331)],"blue",None)
 line(d,[(524,338),(657,339)],"silver",5)
 p(d,[(561,348),(628,348),(644,380),(616,399),(568,395),(548,376)],"dark")
 for x in (549,569,590,610,631):line(d,[(x,374),(x+2,386)],"slate",3)
 bolt(d,505,289,7);bolt(d,693,293,7)
def weapon(d):
 # One integrated modular backpack rail, animated separately in rig.
 p(d,[(840,476),(893,461),(1015,572),(1024,684),(977,720),(920,661)],"dark")
 armor(d,[(919,551),(1029,571),(1044,717),(959,727)],"steel","dark","silver")
 for y in [584,618,653,690]:
  line(d,[(972,y),(1018,y+8)],"navy",8)
 p(d,[(1001,559),(1058,562),(1083,602),(1021,611)],"gold")
 p(d,[(1047,563),(1114,571),(1118,596),(1075,610)],"black","blue",5)
def effects(d):
 # Separate emissive masks on chest and under-thrusters.
 for x,y in [(386,325),(772,325),(590,477),(1057,579)]:
  for radius,opacity in ((44,26),(29,49),(14,86)):
   oval(d,(x-radius,y-radius,x+radius,y+radius),(94,214,247,opacity))
for name,fn in [('backpack',backpack),('legs',legs),('torso',torso),('left_arm',left_arm),('right_arm',right_arm),('head',head),('weapon',weapon),('effects',effects)]:
 save_layer(name,fn)
metadata={'canvas':[W,H],'pivot':{'torso':[593,715],'head':[592,349],'left_arm':[405,424],'right_arm':[811,420],'weapon':[915,505],'backpack':[590,540],'legs':[590,915],'effects':[590,540]},'order':['backpack','legs','torso','left_arm','right_arm','weapon','head','effects'],'generated_by':'tools/build_1103_mech_layers.py','original_vector_raster':True,'not_upscaled_96px':True}
(ROOT/'rig.json').write_text(json.dumps(metadata,indent=2),encoding='utf8')
print('RIG_COMPLETE',ROOT)
