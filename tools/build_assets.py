from convert_map import *
from PIL import Image,ImageDraw
import hashlib,shutil,argparse,subprocess

def convert(map_id=37):
 out=ROOT/'game'; assets=out/'assets'; assets.mkdir(parents=True,exist_ok=True)
 m=parse(RES/'Mapas'/f'mapa{map_id}.csm')
 for key,value in m.items():
  if isinstance(value,list) and key!='size':
   assert all(1<=r[0]<=100 and 1<=r[1]<=100 for r in value),key
 grh=ini(RES/'init/graficos.ini')['GRAPHICS']; bodies=ini(RES/'init/cuerpos.dat'); molds=ini(RES/'init/moldes.ini'); npcs=ini(RES/'Dat/npcs.dat')
 sheets={}; manifest={}
 def sheet(n):
  if n not in sheets:sheets[n]=Image.open(RES/'Graficos'/f'{n}.png').convert('RGBA')
  return sheets[n]
 def save_crop(name,n,rect,key_black=True):
  im=sheet(n).crop(rect)
  if key_black:
   im.putdata([(r,g,b,0 if r==g==b==0 else a) for r,g,b,a in im.getdata()])
  im.save(assets/(name+'.png'));manifest[name]={'file':f'Graficos/{n}.png','rect':rect}
  return 'res://assets/'+name+'.png'
 def frames(index):
  v=grh['grh'+str(index)].split('-');count=int(v[0])
  return [int(q) for q in v[1:count+1]] if count>1 else [index]
 def graphic(index):
  name=f'grh_{index}'
  if name not in manifest:
   v=list(map(int,grh['grh'+str(frames(index)[0])].split('-')));_,n,x,y,w,h=v
   save_crop(name,n,(x,y,x+w,y+h))
  return 'res://assets/'+name+'.png'
 def body(index,label):
  b=bodies['BODY'+str(index)]; result=[]
  if int(b.get('std',0)):
   mold=molds['MOLDE'+b['std']];x,y,w,h=[int(mold[k]) for k in ['x','y','width','height']]
   for d in range(4):
    result.append([save_crop(f'{label}_{d}_{f}',int(b['filenum']),(x+f*w,y+d*h,x+(f+1)*w,y+(d+1)*h)) for f in range(int(mold[f'dir{d+1}']))])
  else:
   for d in [3,1,4,2]:result.append([graphic(i) for i in frames(int(b['walk'+str(d)]))])
  return {'directions':result,'fps':18*float(b.get('speed',1)),'body':index}
 enemies={}
 for id,kind in [(500,'wolf'),(502,'snake'),(506,'bat'),(509,'scorpion')]:
  n=npcs['NPC'+str(id)];enemies[kind]={'npc_id':id,'name':{'wolf':'Lobo','snake':'Serpiente','bat':'Murcielago','scorpion':'Escorpion'}[kind]}
  for field,state in [('body','walk'),('bodyidle','idle'),('ataque1','attack')]:enemies[kind][state]=body(int(n[field]),f'{kind}_{state}')
  enemies[kind].update({'hp':int(n['maxhp']),'damage':int(n['maxhit']),'speed':{'wolf':2.3,'snake':1.5,'bat':2.6,'scorpion':1.7}[kind]})
 m['textures']={str(i):graphic(i) for i in set(r[2] for r in m['layer1']+m['layer2'])}
 # Original dungeon masonry, tiled in world space rather than stretching a mural.
 save_crop('wall',5095,(512,288,640,416),False)
 m['wall_texture']='res://assets/wall.png'
 m['enemies']=enemies;m['spawn']=[73,80]
 m['enemy_spawns']=[{'x':x,'y':y,'kind':k} for x,y,n in m['npcs'] for k,v in enemies.items() if n==v['npc_id']]
 m['icons']=[graphic(i) for i in [5603,74714,28748,28754]]
 m['weapon']={'object_id':15,'grh':5603,'name':'Daga'}
 m['equipment']=[{'name':'Daga','icon':graphic(5603),'slot':'Arma'},{'name':'Armadura de Paladin Imperial','icon':graphic(19474),'slot':'Armadura'}]
 m['spell_frames']=[graphic(i) for i in frames(275)]
 m['paladin']=body(344,'paladin')
 # Non-wall scenery: preserve on floor-facing billboards; structural art becomes geometry.
 structural={i for i in set(r[2] for r in m['layer3']) if int(grh['grh'+str(frames(i)[0])].split('-')[1])==5095}
 m['decorations']=[{'x':x,'y':y,'texture':graphic(i)} for x,y,i in m['layer3'] if i not in structural]
 for name,id in [('magic',16),('sword',136)]:
  shutil.copy2(RES/'wav'/f'{id}.wav',assets/f'{name}.wav');manifest[name]={'file':f'wav/{id}.wav'}
 # Reuse original AO interface art, with all transformations recorded.
 def interface(name,source,rect=None):
  im=Image.open(RES/'interface'/source).convert('RGBA')
  if rect:im=im.crop(rect)
  im.save(assets/f'{name}.png')
  manifest[name]={'file':'interface/'+source,'rect':rect}
 interface('ui_frame','es_ventanaprincipal.bmp',(0,148,754,768))
 interface('ui_slot','es_centroinventario.bmp',(0,35,247,325))
 interface('ui_health','es_barradevida.bmp')
 interface('ui_mana','es_barrademana.bmp')
 interface('ui_leather','es_ventanaprincipal.bmp',(770,40,970,105))
 interface('ui_logo','es_ventanaprincipal.bmp',(6,0,117,29))
 interface('ui_log','es_ventanaprincipal.bmp',(0,30,634,119)) # Exclude original chat-entry row and its baked message icon.
 for state in ['default','over','off']:
  source=f'es_boton-aceptar-{state}.bmp'
  im=Image.open(RES/'interface'/source).convert('RGBA')
  # Retain the metal frame; replace its baked ACCEPT label with a blank source strip.
  blank=im.copy()
  for x in range(24,108):blank.paste(im.crop((24,0,25,28)),(x,0))
  name='ui_button_'+state
  blank.save(assets/f'{name}.png')
  manifest[name]={'file':'interface/'+source,'transformation':'columns24:108 replaced with original blank column24; border retained'}
 shutil.copy2(RES/'BabelUI/static/media/Cardo-Regular..ttf',assets/'ui_font.ttf')
 manifest['ui_font']={'file':'BabelUI/static/media/Cardo-Regular..ttf'}
 shutil.copy2(RES/'OGG/ost_7.ogg',assets/'dungeon_music.ogg')
 manifest['dungeon_music']={'file':'OGG/ost_7.ogg','reference':'map37 music_numberLow=7; client PlayCurrentMapMusic resolves ost_7.ogg'}
 m['music']='res://assets/dungeon_music.ogg'
 # Additional prototype encounters, deterministic and separate from historical spawns.
 import random
 rng=random.Random(37)
 flags={(x,y):v for x,y,v in m['blocked']}
 walk={(x,y) for x,y,_ in m['layer1'] if flags.get((x,y),0)&15!=15}
 reachable={tuple(m['spawn'])}; pending=list(reachable)
 directions=[(0,-1),(1,0),(0,1),(-1,0)]
 while pending:
  a=pending.pop()
  for i,(dx,dy) in enumerate(directions):
   b=(a[0]+dx,a[1]+dy)
   if b in walk and b not in reachable and not flags.get(a,0)&(1<<i) and not flags.get(b,0)&(1<<((i+2)%4)):
    reachable.add(b);pending.append(b)
 occupied=[(v['x'],v['y']) for v in m['enemy_spawns']]
 candidates=sorted(reachable);rng.shuffle(candidates)
 extra=[]
 for x,y in candidates:
  if (x-m['spawn'][0])**2+(y-m['spawn'][1])**2<64:continue
  if any((x-a)**2+(y-b)**2<9 for a,b in occupied):continue
  extra.append({'x':x,'y':y,'kind':['bat','snake','scorpion','wolf'][len(extra)%4],'original':False})
  occupied.append((x,y))
  if len(extra)==48:break
 assert len(extra)==48
 m['extra_enemy_spawns']=extra
 m['source_sha256']=hashlib.sha256((RES/'Mapas'/f'mapa{map_id}.csm').read_bytes()).hexdigest()
 (out/'data/dungeon.json').write_text(json.dumps(m,ensure_ascii=True,separators=(',',':')))
 (ROOT/'docs/asset_manifest.json').write_text(json.dumps(manifest,indent=2))
 versions={p.name:subprocess.check_output(['git','-C',str(p),'rev-parse','HEAD'],text=True).strip() for p in (ROOT/'references').iterdir() if (p/'.git').exists()}
 (ROOT/'docs/source_revisions.json').write_text(json.dumps(versions,indent=2))
 shutil.copy2(RES/'license.txt',ROOT/'docs/ASSET_LICENSE.txt')
 print(f'Converted map {map_id}: {len(m["enemy_spawns"])} enemies, {len(manifest)} assets; {m["trailing_bytes"]} unconsumed source bytes recorded.')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--map',type=int,default=37);convert(p.parse_args().map)
