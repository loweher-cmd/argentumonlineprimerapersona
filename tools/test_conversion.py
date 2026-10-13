"""Independent checks of the source conversion, not a snapshot of generated JSON."""
import unittest, tempfile, hashlib
from pathlib import Path
from collections import deque,Counter
from convert_map import parse,RES,ROOT,ini

class SourceTests(unittest.TestCase):
 def setUp(self): self.m=parse(RES/'Mapas/mapa37.csm')
 def test_identity_and_graph(self):
  self.assertEqual(self.m['meta']['name'],'Newbie Dungeon')
  self.assertEqual(self.m['meta']['restriction'],'1')
  self.assertEqual({r[2] for r in self.m['exits']},{168,264})
  self.assertEqual(parse(RES/'Mapas/mapa264.csm')['meta']['name'],'Dungeon Newbie')
 def test_records_and_alignment(self):
  self.assertEqual(len(self.m['blocked']),7390)
  self.assertEqual(Counter(r[2] for r in self.m['blocked']),{15:7388,1:1,4:1})
  self.assertEqual(self.m['objects'],[[76,85,2462,1]])
  self.assertEqual(len(self.m['exits']),74)
  for key in ['blocked','layer1','layer2','layer3','layer4','objects','npcs','exits']:
   self.assertTrue(all(1<=r[0]<=100 and 1<=r[1]<=100 for r in self.m[key]),key)
 def test_reachable_enemies(self):
  flags={(x,y):v for x,y,v in self.m['blocked']}
  walk={(x,y) for x,y,_ in self.m['layer1'] if flags.get((x,y),0)&15!=15}
  visited={(73,80)}; todo=deque(visited)
  dirs=[(0,-1),(1,0),(0,1),(-1,0)]
  while todo:
   a=todo.popleft()
   for i,(dx,dy) in enumerate(dirs):
    b=(a[0]+dx,a[1]+dy)
    if b in walk and b not in visited and not flags.get(a,0)&(1<<i) and not flags.get(b,0)&(1<<((i+2)%4)):
     visited.add(b);todo.append(b)
  allowed=[(x,y) for x,y,n in self.m['npcs'] if n in (500,502,506,509)]
  self.assertEqual(len(allowed),36)
  self.assertTrue(all(c in visited for c in allowed))
 def test_truncated_source_rejected(self):
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp)/'mapa37.csm';path.write_bytes((RES/'Mapas/mapa37.csm').read_bytes()[:100])
   with self.assertRaises(Exception):parse(path)
 def test_asset_traceability(self):
  import json
  manifest=json.loads((ROOT/'docs/asset_manifest.json').read_text())
  for name,record in manifest.items():self.assertTrue((RES/record['file']).is_file(),name)
  data=json.loads((ROOT/'game/data/dungeon.json').read_text())
  self.assertEqual(data['source_sha256'],hashlib.sha256((RES/'Mapas/mapa37.csm').read_bytes()).hexdigest())
  self.assertEqual([v['npc_id'] for v in data['enemies'].values()],[500,502,506,509])

if __name__=='__main__':unittest.main(verbosity=2)
