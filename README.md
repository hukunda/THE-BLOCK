# THE BLOCK

Full **10-floor** ASCII first-person game (see `GAME_DESIGN.md`): explore, fight residents, beat each floor’s boss, reach the roof, then pick an **ending**. Same codebase runs on **desktop, mobile exports, and the web** via Godot’s HTML5 export.

## Play in the browser (no Godot on your PC)

GitHub Actions builds the web version and deploys it to **GitHub Pages** whenever `main` is updated.

1. On GitHub: open your repo → **Settings** → **Pages**.
2. Under **Build and deployment** → **Source**, choose **GitHub Actions** (not “Deploy from a branch”).
3. Push this repo to `main` (including `.github/workflows/deploy-web.yml`). The **Actions** tab will run **Deploy Web to GitHub Pages**.
4. When it goes green, Pages shows your site URL — usually:

   **`https://hukunda.github.io/THE-BLOCK/`**

   (replace `hukunda` / `THE-BLOCK` if your username or repo name differs.)

First run can take a few minutes (download Godot + templates). Use **Actions → Deploy Web to GitHub Pages → Re-run** if something fails.

## Play in the browser (export on your own machine)

1. Install **[Godot 4.2+](https://godotengine.org/download)** (standard build with export templates).
2. Open this folder in Godot → **Project → Export…** → add **Web** if prompted → select preset **Web**.
3. Set export path (default in repo: `export/web/index.html`) → **Export Project**.
4. Host the **`export/web/`** folder on any static host (**GitHub Pages**, Netlify, Cloudflare Pages, itch.io “HTML embed”, etc.).

**GitHub Pages:** put the contents of `export/web/` in `docs/` on `main` or enable Pages on a branch and upload that folder. Browsers need **SharedArrayBuffer** only if you enable threads in the export preset; this repo’s preset uses **`thread_support=false`** for wider compatibility.

## Play locally

**F5** in the Godot editor, or export to **Windows / macOS / Linux / Android / iOS** from the same project.

### Prototype: 3D scene → on-screen ASCII

`scenes/proto_3d_ascii.tscn` renders a tiny **SubViewport** (spinning cube + floor), reads `ViewportTexture.get_image()`, and draws **1-bit dithered** text using the same Bayer helper as the main game. In Godot: open that scene → **Project → Run Current Scene** (or set it temporarily as the main scene). Swap `MeshInstance3D` meshes for an imported **GLB** when you are ready.

## Controls

| Action | Keyboard | Gamepad (typical) |
|--------|----------|-------------------|
| Move | W A S D | Left stick |
| Turn | Q / E, ← / → | Right stick / LB / RB |
| Fire | Ctrl (Space also on Web) | A |
| Interact (doors) | F | X |
| Use item slot | R | Y |
| Pause | Esc | Start |

**Touch:** lower-left drag = move/strafe; **<<** / **FIRE** / **USE** / **>>** = turn and actions.

**Victory screen:** keys **1 / 2 / 3** (Leave / Shut down / Stay NG+). Touch: **<<** = Leave, **FIRE** = Shut down, **USE** = Stay.

## How the full game is structured (code)

| Piece | Role |
|--------|------|
| `scripts/floor_catalog.gd` | All 10 floor layouts, boss ids, glitch weights |
| `scripts/block_world.gd` | Player, doors, enemies, bosses, exits, NG+ |
| `scripts/ascii_raycast.gd` | Walls + sprite strips (`@` / boss mass) |
| `scripts/main.gd` | Title, HUD, endings, input |
| `scripts/game_state.gd` | Actions + ending key bindings |

Boss behaviour is **rule-based** (knockback, lag, blink, mirror, roof phases, etc.), not hand-authored cutscenes—aligned with the spec’s “ideas, not just enemies.”

## Fonts

**Noto Sans Mono** (`fonts/NotoSansMono-Regular.ttf`) — [Noto fonts](https://github.com/notofonts/noto-fonts), OFL.

## Honest scope

This is a **complete playable arc** (10 floors, bosses, three endings, NG+) in the spirit of the GDD. It is not a AAA production: audio is minimal, narrative is mostly short system lines, and bosses are **simulation-forward** rather than heavily scripted set-pieces. The architecture is meant to grow (more maps, SFX, music loops, richer boss scripts) without rewriting the core.
