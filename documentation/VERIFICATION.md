# Verification record

Executed 2026-10-11 on Windows. Compatibility rendering observed on NVIDIA GeForce RTX 3090, OpenGL 3.3. No performance guarantee for other hardware.

## Automated

- `python tools/test_conversion.py`: **5 tests pass**. Metadata, counts/coordinates, reachability of all 36 original chosen spawns, truncation rejection, source hash and asset provenance.
- `game/tests/integration.gd`: **63 checks, zero failures**, both Godot **4.6.0** and **4.6.3**. Actual physics, source wall collision, partial-block navigation, movement, four species/spawns, sword range/cooldown/occlusion, projectile impact/wall occlusion/mana, consumable limits/exhaustion, enemy damage/cooldown/chasing around a wall, enemy death/collision, player death and fresh-scene restart state.
- Import and single-threaded HTML5 release export completed. Logs are retained here. Tests are excluded from the web package.
- Render capture uses the actual Compatibility renderer. Its camera is moved to a walkable tile near an original wolf spawn and AI is frozen for visual inspection. It is not evidence of a full manual playthrough.

## Browser interaction performed

The local build was served at `127.0.0.1:8060` and opened in the Codex in-app browser:

- WebGL scene loaded; start menu and all four actions were visible.
- Enter dismissed the start screen.
- Key2 displayed spell FX and reduced mana 80→70.
- Clicking the mana potion restored mana 70→80 and reduced charges8→7.
- Initial misplaced modal was corrected and visually rechecked.
- Pointer-lock calls produced **WrongDocumentError** in the embedded browser. Windows Computer Use then stopped the external Firefox attempt because browser URL policy enforcement was unsupported. No further Windows browser input was attempted after that stop.

## Not verified or intentionally omitted

Mouse capture/look in external desktop browsers remains a manual check. Successful WebGL rendering is not proof of working pointer lock. Full manual playthrough, audio listening, low-end performance, cross-browser/mobile testing and clicking Restart interactively are not claimed. Restart's fresh state is tested through scene instantiation.

Other newbie sectors, NPC services, unspecified historical-release fidelity, original combat formulas, literal top-down roof/detail layers, respawn and third-person player rendering are outside the implementation. No public deployment; asset redistribution rights remain unresolved.

## Manual acceptance route

1. Run `serve.ps1`, open localhost in a desktop browser and enter.
2. Verify mouse yaw/pitch, Escape releases cursor and a world click recaptures it.
3. Walk around the chamber walls toward original enemy spawns; verify chasing, sprites and collision.
4. Use1/2 on enemies, including behind walls; use3/4 at full resources and with depleted charges.
5. Die and click Restart; confirm initial health/mana/charges/enemies.
6. Visit an exit: it should show its destination sector while keeping this map loaded.

## Update 2026-10-13

Godot 4.6.3 headless: **132 checks, zero failures** (`test-results-update.log`). Includes 84 reachable enemy spawns, idle wandering, original dagger, minimap, independent music/SFX keys and buttons, looping music, static sign, tiled walls and serialized ceiling. Editor checks instantiate the saved scene BEFORE ready callbacks: explicit textured MultiMesh render nodes have nonempty focus bounds; instance counts match every source GridMap cell; all palette items have named texture previews. GridMap rendering is hidden to avoid duplicate surfaces; physics remains active.

Latest editor visibility correction was verified through saved resources and headless execution only. No desktop control or interactive editor inspection was performed for this correction, as requested. To frame the off-origin source map, select Dungeon/TexturedGeometry and press F with the pointer in the 3D viewport.

## Taller dungeon and classic HUD update

Godot 4.6.3 headless: **140 checks, zero failures**. Saved ceiling and wall height are 4.5 m; bat sprite centers are 1.15 m in runtime and editor previews. HUD has a persistent top-left log (100 entries), fixed equipment and 20 inventory slots at right, with usable health/mana potions sharing actual player charges. Original four-action bottom bar is retained. Tests cover log persistence, inventory button consumption and synchronized bottom-bar quantities. This update was checked without desktop control; no new visual render capture is claimed.

## Continuous HUD frame and editor visibility correction

Floor/Ceiling/Walls GridMaps are now explicitly visible in the saved scene and regenerated scenes. The cached TexturedGeometry parent is hidden to prevent duplicate rendering. Existing scene values were preserved; only these four visibility flags changed. HUD top, right and bottom regions have contiguous opaque backing while the central view stays open. The log texture excludes the original input row containing the baked message icon. No desktop control was used.
