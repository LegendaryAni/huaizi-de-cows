"""Deterministic extraction/composition of existing and image_gen assets.

Does not draw actor poses or create replacement sprite artwork. Source project is read-only.
"""
from pathlib import Path
from PIL import Image, ImageEnhance
import hashlib, importlib.util, json, random, shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:/Users/legendaryAni/Documents/ChatGPT/New project/assets')
GENERATED = Path(r'C:/Users/legendaryAni/.codex/generated_images/01a147f0-8f64-7362-b1d3-122759ed855f')
PANEL = GENERATED / 'exec-a811da7c-8663-4848-bc63-ca22cc2c9f2b.png'
ICONS = GENERATED / 'exec-d0c79b8f-87ab-417c-802c-5ea13585a286.png'
OUT = ROOT / 'assets/sprites/scifi'
UI = ROOT / 'assets/sprites/ui/runtime/scifi'
FX = ROOT / 'assets/sprites/vfx/runtime/scifi'
RAW = ROOT / 'assets/source/scifi'
EVIDENCE = ROOT / '.codex/validation/scifi-v02/assets'
IDS = ['1103', '2101', '2106', '2103', '2105', '3101']
DIRS = ['e', 'se', 's', 'sw', 'w', 'nw', 'n', 'ne']
ROWS = [2, 1, 0, 7, 6, 5, 4, 3]
manifest = {'version': '0.2', 'source_project': str(SOURCE.parent),
            'direction_rows': dict(zip(DIRS, ROWS)), 'files': [], 'actors': {}}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def copy(src, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    manifest['files'].append({'source': str(src), 'runtime': dest.relative_to(ROOT).as_posix(),
                              'source_sha256': sha(src), 'sha256': sha(dest)})

def ninepatch(image, size, border=16):
    result = Image.new('RGBA', size)
    sw, sh = image.size
    xs, ys = [0, border, sw-border, sw], [0, border, sh-border, sh]
    xd, yd = [0, border, size[0]-border, size[0]], [0, border, size[1]-border, size[1]]
    for row in range(3):
        for col in range(3):
            part = image.crop((xs[col], ys[row], xs[col+1], ys[row+1]))
            part = part.resize((xd[col+1]-xd[col], yd[row+1]-yd[row]), Image.Resampling.NEAREST)
            result.alpha_composite(part, (xd[col], yd[row]))
    return result

def fit(image, size, inset=4):
    bbox = image.getbbox()
    if not bbox:
        raise ValueError('Empty asset')
    body = image.crop(bbox)
    body.thumbnail((size[0]-inset*2, size[1]-inset*2), Image.Resampling.NEAREST)
    result = Image.new('RGBA', size)
    result.alpha_composite(body, ((size[0]-body.width)//2, (size[1]-body.height)//2))
    return result

def actors():
    player = json.loads((SOURCE/'animation-manifest.json').read_text('utf8'))
    enemies = json.loads((SOURCE/'enemy-animation-manifest.json').read_text('utf8'))
    gallery = Image.new('RGBA', (8*128, len(IDS)*128), '#121b20')
    for unit_index, dex in enumerate(IDS):
        meta = (player if dex == '1103' else enemies)[dex]
        folder = OUT/'units'/dex
        folder.mkdir(parents=True, exist_ok=True)
        copy(SOURCE/'units'/dex/'portrait.png', folder/'portrait.png')
        ext, sub, animations = [], [], []
        for action, info in meta['a'].items():
            copy(SOURCE/'units'/dex/(action+'.png'), folder/(action+'.png'))
            image = Image.open(folder/(action+'.png')).convert('RGBA')
            if image.size != (info['w']*info['n'], info['h']*info['r']):
                raise ValueError(f'Invalid sheet geometry: {dex}/{action}')
            ext_id = action.lower()
            ext.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/scifi/units/{dex}/{action}.png" id="{ext_id}"]')
            for direction, row in zip(DIRS, ROWS):
                frame_lines = []
                for col in range(info['n']):
                    x, y = col*info['w'], row*info['h']
                    frame = image.crop((x, y, x+info['w'], y+info['h']))
                    box = frame.getbbox()
                    if not box or min(box[0], box[1], info['w']-box[2], info['h']-box[3]) <= 0:
                        raise ValueError(f'Empty/edge frame: {dex}/{action}/{row}/{col}')
                    key = f'{ext_id}_{direction}_{col}'
                    sub.append(f'[sub_resource type="AtlasTexture" id="{key}"]\natlas = ExtResource("{ext_id}")\nregion = Rect2({x}, {y}, {info["w"]}, {info["h"]})')
                    frame_lines.append('{"duration": %s, "texture": SubResource("%s")}' % (float(info['d'][col]), key))
                    if action == 'Walk' and col == 0:
                        frame = frame.resize((128,128), Image.Resampling.NEAREST)
                        gallery.alpha_composite(frame, (DIRS.index(direction)*128, unit_index*128))
                animations.append('{"frames": [%s], "loop": %s, "name": &"%s_%s", "speed": 60.0}' %
                                  (', '.join(frame_lines), 'false' if action in ['Faint','Hurt'] else 'true', ext_id, direction))
        text = f'[gd_resource type="SpriteFrames" load_steps={len(ext)+len(sub)+1} format=3]\n\n'
        text += '\n\n'.join(ext+sub)+'\n\n[resource]\nanimations = ['+',\n'.join(animations)+']\n'
        (folder/'frames.tres').write_text(text, 'utf8')
        for alias in ['Walk', 'Idle']:
            (folder/(alias+'.spriteframes.tres')).write_text(text, 'utf8')
        manifest['actors'][dex] = meta
    gallery.save(EVIDENCE/'directions.png')

def interface():
    copy(PANEL, RAW/'panel-generated.png')
    copy(ICONS, RAW/'icons-generated.png')
    reference = ROOT/'assets/sprites/ui/reference_crops/scifi'
    reference.mkdir(parents=True, exist_ok=True)
    panel = Image.open(PANEL).convert('RGBA').resize((256,256),Image.Resampling.NEAREST)
    for name, size in [('panel',(256,256)),('card',(256,384)),('button',(256,80)),('bar_frame',(256,40))]:
        image = ninepatch(panel,size,16)
        image.save(UI/(name+'.png'))
        image.save(reference/(name+'_ref.png'))
    Image.new('RGBA',(16,16),'#ffffff').save(UI/'bar_fill.png')
    module = importlib.util.spec_from_file_location('sprite_processor',Path.home()/'.codex/skills/generate2dsprite/scripts/generate2dsprite.py')
    processor = importlib.util.module_from_spec(module)
    module.loader.exec_module(processor)
    image = processor.remove_bg_magenta(Image.open(ICONS).convert('RGBA'),32,80)
    names = ['rail','grenade','blade','arc','thermal','frost','dash','pulse','shield','repair','xp','credits','explosion','smoke','impact','repair_fx']
    gallery = Image.new('RGBA',(4*96,4*96),'#121b20')
    for index, name in enumerate(names):
        row,col = divmod(index,4)
        cell=image.crop((round(col*image.width/4),round(row*image.height/4),round((col+1)*image.width/4),round((row+1)*image.height/4)))
        asset=fit(cell,(64,64),5)
        asset.save(UI/('icon_'+name+'.png'))
        gallery.alpha_composite(asset.resize((96,96),Image.Resampling.NEAREST),(col*96,row*96))
        if name in ['blade','xp','explosion','smoke','impact','repair_fx']:
            asset.save(FX/(('repair' if name=='repair_fx' else name)+'.png'))
    gallery.save(EVIDENCE/'equipment-icons.png')
    projectiles=Image.open(SOURCE/'fx/projectile.png').convert('RGBA')
    for name,row,col in [('rail',0,2),('grenade',1,2),('arc',4,1),('thermal',2,2),('frost',3,2),('enemy',5,2)]:
        fit(projectiles.crop((col*24,row*24,(col+1)*24,(row+1)*24)),(48,48),4).save(FX/(name+'.png'))
    # Detached effect art comes from existing impact sheet; no procedural replacement sprites.
    impacts=Image.open(SOURCE/'fx/impact.png').convert('RGBA')
    for name,row in [('pulse',4),('shield',3),('dash',0)]:
        fit(impacts.crop((32,row*32,64,(row+1)*32)),(64,64),4).save(FX/(name+'.png'))

def world():
    rng=random.Random(20261017)
    tiles=[ImageEnhance.Brightness(Image.open(SOURCE/'terrain'/f'floor-0-{i}.png').convert('RGBA')).enhance(0.58).resize((96,96),Image.Resampling.NEAREST) for i in range(4)]
    result=Image.new('RGBA',(4096,2305))
    for y in range(0,2305,96):
        for x in range(0,4096,96):
            result.alpha_composite(tiles[rng.randrange(4)],(x,y))
    props=[]
    for i in range(12):
        src=SOURCE/'props'/f'prop-{i}.png'
        copy(src,OUT/'props'/src.name)
        props.append(Image.open(src).convert('RGBA'))
    # Composition uses finished authored props. Outer crate fence makes arena limits visible.
    crate=props[0].resize((96,96),Image.Resampling.NEAREST)
    for x in range(-24,4096,72):
        for y in [-35,2240]:
            result.alpha_composite(crate,(x,y))
    for y in range(40,2240,72):
        for x in [-35,4030]:
            result.alpha_composite(crate,(x,y))
    for i in range(58):
        x,y=rng.randrange(230,3860),rng.randrange(230,2080)
        if abs(x-2048)<450 and abs(y-1152)<330:
            continue
        prop=props[rng.choice([0,1,2,4,5,6,7])].resize((192,192),Image.Resampling.NEAREST)
        result.alpha_composite(prop,(x,y))
    result.save(OUT/'map.png')
    result.resize((1024,576),Image.Resampling.NEAREST).save(EVIDENCE/'map-preview.png')

if __name__=='__main__':
    for directory in [OUT,UI,FX,RAW,EVIDENCE]:
        directory.mkdir(parents=True,exist_ok=True)
    actors();interface();world()
    manifest['derived_assets']=[{'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p)} for d in [OUT,UI,FX] for p in d.rglob('*') if p.is_file() and p.suffix in ['.png','.tres']]
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf8')
    print(json.dumps({'actors':len(IDS),'runtime_assets':len(manifest['derived_assets']),'source_files':len(manifest['files']),'evidence':str(EVIDENCE)},ensure_ascii=False))
