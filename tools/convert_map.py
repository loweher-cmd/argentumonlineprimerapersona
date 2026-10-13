from pathlib import Path
import struct,json,collections
ROOT=Path(__file__).resolve().parents[1]
RES=ROOT/'references/Recursos'
class Reader:
 def __init__(self,data): self.data=data; self.p=0
 def take(self,fmt):
  s=struct.Struct('<'+fmt); v=s.unpack_from(self.data,self.p); self.p+=s.size; return v[0] if len(v)==1 else list(v)
 def string(self):
  n=self.take('H'); b=self.data[self.p:self.p+n]; self.p+=n; return b.decode('cp1252',errors='replace')
def parse(path):
 r=Reader(path.read_bytes()); first=r.take('i'); five=first==0x324c3557
 counts=r.take('12i') if five else [first]+r.take('10i')
 size=r.take('4h'); meta={}
 for key,fmt in [('name','s'),('backup','B'),('restriction','s'),('music_hi','i'),('music_low','i'),('safe','B'),('zone','s'),('terrain','s'),('ambient','s'),('light','i'),('letter','i'),('level','i'),('extra','i'),('exit','s'),('rain','B'),('snow','B'),('fog','B')]: meta[key]=r.string() if fmt=='s' else r.take(fmt)
 layers=5 if five else 4
 sections=[('blocked','hhB',counts[0])]+[(f'layer{i+1}','hhi',counts[i+1]) for i in range(layers)]
 t=1+layers
 sections += [('triggers','hhh',counts[t]),('particles','hhi',counts[t+2]),('lights','hhiB',counts[t+1]),('objects','hhhh',counts[t+4]),('npcs','hhh',counts[t+3]),('exits','hhhhh',counts[t+5])]
 out={'id':int(path.stem[4:]),'size':size,'meta':meta,'five_layers':five}
 for name,fmt,n in sections:
  assert 0<=n<=100000,(name,n)
  out[name]=[r.take(fmt) for _ in range(n)]
 out['trailing_bytes']=len(r.data)-r.p
 return out
def ini(path):
 result={}; section={}
 for line in path.read_text(encoding='cp1252',errors='replace').splitlines():
  line=line.strip()
  if line.startswith('[') and ']' in line:
   section={};result[line[1:line.index(']')].upper()]=section
  elif '=' in line and not line.startswith(("'",';')):
   k,v=line.split('=',1);section[k.lower()]=v.strip()
 return result
if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser(description='Parse original AO CSM records without changing coordinates.')
 p.add_argument('--map',type=int,default=37)
 p.add_argument('--output',type=Path)
 p.add_argument('--scan',action='store_true')
 args=p.parse_args()
 if args.scan:
  for path in sorted((RES/'Mapas').glob('*.csm')):
   try:
    m=parse(path)
    if 'newb' in m['meta']['name'].lower():print(m['id'],m['meta']['name'],len(m['npcs']),m['trailing_bytes'])
   except (ValueError,struct.error,AssertionError) as error:print('SKIPPED',path.name,str(error))
 else:
  m=parse(RES/'Mapas'/f'mapa{args.map}.csm')
  if args.output:args.output.write_text(json.dumps(m,indent=2))
  else:print(json.dumps({'id':m['id'],'meta':m['meta'],'trailing_bytes':m['trailing_bytes']},indent=2))
