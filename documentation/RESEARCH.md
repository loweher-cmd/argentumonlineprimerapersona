# Research and conversion report

Research date: 2026-10-11. Exact source revisions are in `source_revisions.json`. All five requested repositories were cloned with Git under `references`, outside the Godot project, and left unmodified.

## Map identity

| Map | Embedded CSM name | Independent client index |
|---|---|---|
| **37** | **Newbie Dungeon** | `init/namemapa.dat:108` |
| 167 | Dungeon Newbie Sur | `namemapa.dat:192` |
| 168 | Dungeon Newbie Central. | `namemapa.dat:155` |
| 264 | Dungeon Newbie | `namemapa.dat:566` |

The name is not unique. Map **37** is the selected playable sector: its name, newbie restriction (`1`), zone (`DUNGEON`), welcome sign and four requested enemy species agree. Its 74 exits lead to sectors 168 and 264. This does not establish which historical release the user's recollection refers to. The prototype explicitly uses the pinned current ao-org map 37, not an arbitrary dungeon, not the entire newbie complex, and not a certified reconstruction of an unspecified historical release. Map 264 is another valid named candidate, not an interchangeable filename.

Map 37 contains 7,390 blocked records: 7,388 full blocks, north-only at (76,85), south-only at (76,86). It has 7,163 layer-1 entries, 189 layer-2, 723 layer-3, 317 layer-4, no triggers, four lights, no particles, 67 NPCs, one object and 74 exits. The only object is **OBJ2462**, the welcome sign at (76,85), not a door. All 36 selected enemies are reachable from **(73,80)**; this is a chosen safe original cell, not a claimed original account spawn. `map37-original.png` reconstructs the original graphical layers for offline inspection; it is not a gameplay minimap.

## Format and reviewed utilities

Primary format source: server `Codigo/FileIO.bas`, types near lines 72–163 and `CargarMapaFormatoCSM` near 1588. Cross-checks: client `CODIGO/Recursos.bas`, WorldEditor map I/O, and LambdaClass `server/apps/arena/lib/arena/map/csm_parser.ex`.

All binary numbers are little-endian: VB Integer is signed 16-bit, Long signed 32-bit, Byte unsigned 8-bit. Strings have a 16-bit byte-length prefix followed by encoded bytes. Coordinates are **1-based** and remain so throughout conversion.

Legacy CSM header has **11 int32 counts**: blocked, four layers, triggers, lights, particles, NPCs, objects, exits. The newer signature `0x324C3557` precedes 12 counts with five layers. Four int16 map bounds follow, then variable metadata: name, backup, restriction, music, safe flag, zone, terrain, ambient, light, letter, level, extra, exit string and rain/snow/fog.

| Section order | Record fields | Bytes |
|---|---|---|
| Blocked | x:i16, y:i16, sides:u8 | 5 |
| Each graphic layer | x:i16, y:i16, grh:i32 | 8 |
| Triggers | x:i16, y:i16, trigger:i16 | 6 |
| Particles | x:i16, y:i16, index:i32 | 8 |
| Lights | x:i16, y:i16, color:i32, range:u8 | 9 |
| Objects | x:i16, y:i16, object:i16, quantity:i16 | 8 |
| NPCs | x:i16, y:i16, npc:i16 | 6 |
| Exits | x:i16, y:i16, map:i16, dest-x:i16, dest-y:i16 | 10 |

Blocking bits are N=1, E=2, S=4, W=8. Flags 16/32/64 have other GM/water/tree meanings; they are not automatically solid walls. Map 37 uses only 15, 1 and 4. The parser retains all flags; generalized gameplay conversion of water/tree maps remains outside this prototype.

**Source irregularity:** map37.csm contains **27,972 bytes after the declared sections**. The parser records this instead of claiming strict EOF equality. The server loader and reviewed LambdaClass parser consume declared sections; LambdaClass returns remaining bytes. A newer original-client test requires exact EOF and would flag this snapshot. The origin of the tail has not been proven (possibly stale bytes after an older rewrite); it is not used to invent more records. Recognizable NPC/object/exit data, valid coordinates, sector connections and graphical reconstruction support the decoded layout. Truncation is rejected; empty other maps are reported by the scanner.

Tools investigated before writing the converter:

- LambdaClass `csm_parser.ex`: same field order. Its comment says 10 counts, but its actual pattern correctly reads 11. It covers the legacy four-layer layout and does not need to become a runtime dependency.
- LambdaClass `client/scripts/generateNpcRawBodies.mjs`: resolves NPC/body/mold animation data. That repository now labels its TypeScript client frozen and uses Rust/Bevy for the production client.
- Original `Recursos.bas`: reads text graphics/body/mold/weapon/FX indices. Those indices avoid reverse engineering alternative binary IND files for this task.
- WorldEditor map I/O: useful format reference, but the original VB environment is unnecessary for conversion.

Chosen pipeline: independent Python CSM reader (`convert_map.py`) plus Pillow extraction (`build_assets.py`), emitting JSON/PNG/WAV. No original game code is copied into the runtime. No VB, Elixir, database or source checkout is needed to play.

## Verified sprites, items and effects

`graficos.ini` static entries use `GrhN=1-file-x-y-width-height`; animated entries hold frame count, frame IDs and duration. Bodies either use four Walk indices or Std + FileNum. Molds define origin, frame dimensions and row counts. Original mold row order is **south, north, west, east** (`Recursos.bas:1545–1548`). Runtime chooses the directional row relative to enemy heading and camera, with body speed converted to `18 * Speed` FPS. Assets keep nearest filtering and alpha; exact black is keyed transparent where applicable. Every crop is listed in `asset_manifest.json`.

| Enemy | NPC | Walk / idle / attack body | Sheet |
|---|---|---|---|
| Wolf | 500 | 4372 / 4373 / 4371 | 4746.png |
| Snake | 502 | 4194 / 4195 / 4193 | 4785.png |
| Bat | 506 | 4340 / 4340 / 4339 | 4755.png |
| Scorpion | 509 | 4335 / 4334 / 4333 | 4757.png |

These come from actual DAT lookups. Other bat definitions exist, but selected map-37 spawns use NPC506. Filtering yields 10 wolves, 10 bats, 10 scorpions and six snakes; other NPCs are excluded, not replaced with new spawns.

Paladin is a class combined with race/equipment, not one universal body. **OBJ1580 Imperial Paladin Armor** maps human/elf appearance to **body344**; other races have other bodies. Body344 is exported for reference, but the first-person camera does not render a third-person player body.

Sword: **OBJ164 Espada Corta**, icon **Grh588**, weapon animation **155**, `ARMA155` = Std2 / sheet2060. The first-person effect animates the original icon; it is not an original first-person arm animation. Sound **136.wav** is explicitly `SwordClash` in server `Declares.bas:540`.

Magic: **HECHIZO1 Dardo Magico**, icon **74714**, FX15 → **Grh275** → frames **266–273**, sound **16.wav**. Travel particle 186 is identified but not ported; the prototype moves an original-FX billboard. Damage 28 is prototype balance, not the original spell formula.

Potions: **OBJ38 Vida → Grh28748**, **OBJ37 Mana → Grh28754**.

Floor indices come directly from layer 1. For example Grh7721 is sheet5095 at (544,288), size32×32. Vertical walls use a documented crop from the same original dungeon wall sheet **5095.png**, rectangle **(80,56)–(160,112)**. This is an explicit first-person adaptation.

## Geometry and rendering rules

1. **GridMap + MeshLibrary selected:** repeated two-metre cells, reusable floor textures and wall boxes, built-in collision and compatibility renderer.
2. Procedural ArrayMesh was considered for tighter batching/exposed faces, but adds unnecessary UV and collision complexity here. GDScript builds the GridMaps directly from data; no manual redrawing.
3. No plugin needed. 4. No Blender needed.

Layer1: original per-cell floor texture on walkable cells. Full blocked cells adjacent to them: 3m-high wall boxes; interior solid mass is not rendered. Original openings remain. Cardinal-only blocks create thin edge collision and remove the graph edge; both source and destination-side flags are checked. Navigation has no diagonals. Sheet5095 layer3 architectural art becomes geometry instead of billboards; four other layer3 entries remain original decorative billboards. Layers2/4 are preserved in JSON but not drawn literally. Ceiling is a simple dark plane. Source light/trigger records are retained; rendering uses ambient/directional light plus one shadowless player light rather than the original light simulation.

External exit cells display their original destination number but stay in this map. There are no interactive doors because no door object is present in the selected map. No rooms or additional monster species were invented.

See `VERIFICATION.md` for exact tests and remaining manual checks; browser mouse capture is not claimed as tested.

## Requested first-person update

The additional 48 spawns are prototype additions requested by the user, separate from the 36 original spawns in JSON. Common dagger OBJ 15 / Grh 5603 replaces the sword icon. The original map music number 7 resolves to OGG/ost_7.ogg. HUD uses original es_ventanaprincipal/es_centroinventario, health/mana bars and Cardo font; provenance is recorded in asset_manifest.json. Walls repeat a masonry crop; ceiling repeats floor cells. These are first-person adaptations, not original 2D layouts.
