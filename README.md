# Argentum Online en primera persona

Prototipo single-player de Dungeon Newbie en Godot 4.6.3 / Compatibility.

**Jugar:** https://loweher-cmd.github.io/argentumonlineprimerapersona/

Abrir desde un navegador de escritorio con WebGL 2 y pulsar Entrar. WASD mueve, raton mira, Escape libera el cursor. 1 o clic: daga; 2: Dardo Magico; 3: vida; 4: mana. O activa/desactiva musica; P activa/desactiva sonidos. No requiere instalar Godot para jugar.

Incluye mapa 37, 84 enemigos con deambulacion, minimapa, equipo e inventario de pociones, registro de combate y HUD inspirado en AO. Daga ampliada detras de la interfaz y lobos mas grandes.

## Proyecto y web

- `game/project.godot`: proyecto editable. Abrir en Godot 4.6.x y ejecutar F5.
- `docs/`: build web que sirve GitHub Pages desde main.
- `documentation/`: fuentes, atribuciones y licencias de recursos.
- `tools/`: conversores; requieren clones originales en references para regenerar recursos.

Para actualizar la web con las plantillas de Godot 4.6.3 instaladas:

```sh
godot --headless --path game --export-release Web ../docs/index.html
```

142 comprobaciones de integracion pasan en Godot 4.6.3. Ejecutar con `godot --headless --path game --script res://tests/integration.gd`.

## Creditos y licencias

Recursos originales: Argentum Online / Noland Studios y contribuyentes; fuente https://github.com/ao-org/Recursos. Los recursos declaran CC BY-NC-ND 4.0 y condiciones adicionales para material de terceros; el codigo del prototipo no cambia estas condiciones. Recortes y adaptaciones estan documentados en `documentation/asset_manifest.json`. No se concede una licencia adicional de redistribucion o uso comercial. Consultar `documentation/LICENSES.md` y `documentation/ASSET_LICENSE.txt`.

Motor Godot, licencia MIT: https://godotengine.org/license/
