# godot-wizardryflee

Wizardry-like **first-person grid dungeon** demo for [Godot 4.7](https://godotengine.org/) (GL Compatibility).  
Keyboard only. **No combat** — when a monster appears, you can only **flee (F)**.

> 戦えないダンジョン。出会ったら、逃げろ。

## Requirements

- Godot **4.7.1-stable** (or install via [mise](https://mise.jdx.dev/) + this repo’s `mise.toml`)
- Linux x86_64 recommended (export preset: `Linux`)

## Quick start (mise)

```bash
git clone https://github.com/bluehive/godot-wizardryflee.git
cd godot-wizardryflee
mise trust && mise install
mise run templates:install   # first time only (~1GB templates)
mise run build               # import + check + Linux export
mise run play                # run exported binary
```

Without mise: open the folder in Godot 4.7.1 Editor, or run the editor binary with `--path .`.

## Controls

| Key | Action |
|-----|--------|
| Enter / Space | Start / return to title |
| WASD / Arrows | Move / turn |
| **F** | **Flee** (encounter only) |
| Esc | Title / quit |

## License

- Code & project assets (except fonts): **MIT** — see `LICENSE`
- Font `assets/fonts/migu-1m-regular.ttf`: **IPA Font License** — see `fonts/README.md`

---

# Design notes (original analysis + MVP)

# WizardryFlee — 解析・設計メモ（実装前）

**ステータス:** MVP 実装済み（P0–P3）。`mise run wf:build` → `mise run wf:play` で確認。  
**ゴール:** 荒い 3D でよい **Wizardry 風グリッドダンジョン** を、キーボードのみで操作するデモ。怪物との遭遇時は **逃走のみ**（戦闘モードなし）。  
**実行環境:** `~/my-project/godot-demos` + mise + 公式 Godot **4.7.1-stable**（既存 Level 1 基盤）。  
**対象マシン制約:** ThinkPad X240 級（~7.5GB RAM / Intel HD 4400）→ 描画は **GL Compatibility**、ジオメトリとライトは最小。

---

## 1. 何を「Wizardry ライク」と呼ぶか（スコープ）

本デモで取り入れる要素と、入れない要素を先に固定する。

### 1.1 入れる（MVP）

| 要素 | 内容 |
|------|------|
| 一人称 3D | ダンジョン内部をカメラ視点で見る |
| グリッド移動 | マス単位で前進・後退・左右旋回（スムーズ補間は短くてよい） |
| キーボードのみ | マウス視点・クリック UI は使わない |
| 小マップ／フロア | 数室〜十数マス程度の 1 フロアで十分 |
| 遭遇 | 特定マス／ランダムで「怪物に出会う」イベント |
| 逃走 | 遭遇中は **逃げる** 操作のみ（自動で戦闘に入らない） |
| 荒い見た目 | CSG／単色メッシュ／最低限のテクスチャで可 |

### 1.2 入れない（明示的に非目標）

| 要素 | 理由 |
|------|------|
| 戦闘（攻撃・魔法・コマンド選択） | ユーザー要件「戦いモードはなし」 |
| レベル／経験値／装備 | デモ範囲外 |
| 複数フロア・町・店 | 時間と負荷 |
| 高品質ライティング・影・パーティクル大量 | マシン性能 |
| セーブ／ロード本格実装 | 後回し可（任意で簡易） |
| ゲームパッド／マウス | キーボードのみ |

**一言で言うと:**  
「マス目ダンジョンを歩き、敵に当たったら **逃げてやり過ごす** 恐怖／探索デモ」であり、RPG 戦闘シミュレータではない。

---

## 2. 参照する Wizardry 的体験（デザインの芯）

クラシック Wizardry の空間感覚のうち、デモで再現する芯:

1. **閉じた石廊** — 正面・左右・後ろが壁か通路かだけが分かる  
2. **タイル単位の意思決定** — 一歩ごとに「進む／曲がる／戻る」  
3. **未知との遭遇** — 廊下の先で突然エンカウント  
4. **リスク回避** — 本デモでは「戦わず逃げる」が唯一の解決  

戦闘 UI の再現は **しない**。遭遇 UI は「名前／一言フレーバー + 逃げる」だけ。

---

## 3. 技術選定（既存スタックとの整合）

### 3.1 エンジン・配置

| 項目 | 方針 |
|------|------|
| エンジン | 公式 Godot 4.7.1-stable（mise ピン済み） |
| レンダラ | `gl_compatibility`（HD 4400 向け） |
| プロジェクトパス案 | `~/my-project/godot-demos/WizardryFlee/` |
| タスク | 親 `godot-demos/mise.toml` を拡張するか、プロジェクト切替 env で `GODOT_PROJECT` を切る |
| スクリプト | GDScript のみ（C# なし） |
| ビルド | `mise run export:linux` 相当 → ユーザーがバイナリ起動で確認 |

**mise 方針（`~/my-project` ルール）:**  
新規シェルは増やさず、タスク追加・`GODOT_PROJECT` 切替で運用。詳細は [mise tasks](https://mise.en.dev/tasks/)。

### 3.2 なぜ 3D でもこのマシンで狙えるか

- ダンジョンは **箱と平面の集合** で足りる（ポリゴン極小）  
- ライトは **Directional 1 + プレイヤー付近の Omni 1** 程度  
- 敵は **色付き PrimitiveMesh / 簡易キャラ** で十分「荒い画像」要件を満たす  
- 画面効果はフルスクリーン ColorRect のフェード程度  

GrokProbe（2D）で確立した **headless import / check / export** の流れをそのまま流用できる。

### 3.3 リスク

| リスク | 緩和 |
|--------|------|
| 3D 初回 import / export が重い | アセットを最小に、テクスチャは 64–128px 級 |
| カメラ酔い | グリッド移動は固定角 90°、補間 0.15–0.25s |
| 遭遇ロジックが複雑化 | ステートマシンを 3 状態に限定（§5） |
| mise の `GODOT_PROJECT` が GrokProbe 固定 | WizardryFlee 用 task か env 上書きを設計に含める |
| ユーザー環境で `mise run play:build` が見えない | **必ず** `cd ~/my-project/godot-demos` してから実行（絶対パス推奨）。別ディレクトリの `mise.toml` を拾っている可能性 |

---

## 4. プレイ体験（プレイヤー視点のシナリオ）

### 4.1 起動〜終了（デモ 3–5 分）

1. タイトル相当（画面中央テキスト）: **Enter / Space で開始**  
2. ダンジョン内。壁は単色、床はグリッドが分かる色分け  
3. 矢印 or WASD で前進・後退・左右回転（キー割当は §6）  
4. 特定マスで遭遇: 画面暗転 or 枠付きパネル  
   - 文言例: 「スライムが立ちはだかった…！」  
   - 操作: **[F] 逃げる** のみ（他キーは無効 or 無視）  
5. 逃走成功: 元のマスに留まる／1 マス下がる／短いメッセージ「逃げ切った」  
6. ゴールマス到達: 「脱出した」でクリア表示 → Enter でタイトル戻し or 終了  

### 4.2 失敗条件（任意・軽量）

- **逃走失敗**は MVP では入れない（常に成功でよい）  
- 後で難易度を足すなら「連続遭遇でスタミナ」等を検討するが、初期実装は **常時逃走成功**  

---

## 5. ゲームステート設計

```text
┌─────────┐  start   ┌──────────┐  encounter  ┌──────────┐
│ Title   │ ───────► │ Explore  │ ──────────► │ Encounter│
└─────────┘          └──────────┘             └────┬─────┘
     ▲                     │                       │ flee
     │                     │ reach goal            ▼
     │               ┌─────▼─────┐          (Explore に戻る)
     └────────────── │ Cleared   │
                     └───────────┘
```

| 状態 | 入力 | 更新 |
|------|------|------|
| `Title` | Enter/Space → Explore | なし |
| `Explore` | 移動・回転（1 コマンドずつ） | グリッド座標・向き・遭遇判定 |
| `Encounter` | **F = 逃げる** のみ | フラグ解除、メッセージ、Explore へ |
| `Cleared` | Enter → Title | なし |

**戦闘状態は存在しない。**

---

## 6. キーボード操作（確定案）

| キー | Explore | Encounter | Title / Cleared |
|------|---------|-----------|-----------------|
| `W` / `↑` | 前進 1 マス | 無効 | — |
| `S` / `↓` | 後退 1 マス | 無効 | — |
| `A` / `←` | 左 90° | 無効 | — |
| `D` / `→` | 右 90° | 無効 | — |
| `F` | （未使用 or ステータス簡易） | **逃げる** | — |
| `Enter` / `Space` | — | — | 開始／戻る |
| `Esc` | タイトルへ（任意） | 無効 | 終了（任意） |

- マウス操作なし  
- 移動中アニメ中は入力キュー 1 つまで（連打でマスを飛ばさない）

---

## 7. ワールド表現

### 7.1 データ

ダンジョンは **2D グリッドのセル種別** で持つ（3D 見た目はセルから生成）。

```text
# 例: 文字マップ（実装時は配列 or リソース）
#########
#....G..#
#.###...#
#S..#..E#
#...#...#
#########

S = スタート, G = ゴール, E = エンカウント固定, . = 通路, # = 壁
```

- **壁セル** … 通行不可。隣接する床側に壁メッシュ  
- **床セル** … 通行可  
- **エンカウント** … 固定マス or 歩数 N ごとの確率（MVP は固定 1–3 マス推奨）  
- **ゴール** … 到達で Clear  

規模目安: **8×8 〜 12×12** 程度（手作業配置でも把握しやすい）。

### 7.2 3D の出し方（荒さ優先の 2 案）

| 方式 | 内容 | 向き不向き |
|------|------|------------|
| **A. ランタイム生成** | マップ配列から `MeshInstance3D` / CSG を生成 | ファイル少・調整容易 → **推奨** |
| **B. 手置きシーン** | Editor で壁を並べる | 見栄えは出るが差分が重い |

推奨は **A**。床は大きな Plane 1 枚 + 壁は隣接関係から薄い Box。  
天井は暗色 Plane で閉じると Wizardry 感が出る。

### 7.3 プレイヤー／カメラ

- `CharacterBody3D` は使わず **論理座標 `(gx, gz)` + 向き `N/E/S/W`** をソース・オブ・トゥルースに  
- `Camera3D` を論理状態へ Tween／手動補間  
- アイの高さは固定（例: 1.5m 相当の単位）  
- 衝突はグリッド判定のみ（物理はほぼ不要）

### 7.4 怪物の見せ方

遭遇中のみ:

- カメラ前方に **色付きカプセル／箱**（「敵」）  
- または画面中央 UI に名前だけ（3D 敵なしでも可）  

MVP 推奨: **UI テキスト + 前方に単色メッシュ 1 体**（どちらも軽量）。

---

## 8. UI

| 画面 | 要素 |
|------|------|
| 探索 HUD | 現在座標・向き（デバッグ兼用で常時表示してよい）、操作ヒント |
| 遭遇 | 半透明パネル、敵名、フレーバー 1 行、`[F] 逃げる` |
| クリア | 「ダンジョンから脱出した」 |

Font は Godot デフォルトで可。日本語表示するなら **Noto 等を 1 ファイル同梱**（またはシステムフォント読み込み）。  
デモ文言は **日本語** を基本とする。

---

## 9. モジュール構成（実装時のファイル案）

```text
WizardryFlee/
├── README.md                 # 本解析（済み）
├── project.godot
├── export_presets.cfg        # Linux（親 mise と揃える）
├── icon.svg
├── assets/                   # 最小テクスチャ（任意）
├── data/
│   └── floor_01.txt          # or floor_01.tres
├── scenes/
│   ├── main.tscn             # ルート（State 管理）
│   ├── dungeon.tscn          # 3D 空間 + Camera
│   └── ui/
│       ├── title.tscn
│       ├── hud.tscn
│       └── encounter.tscn
├── scripts/
│   ├── game_state.gd         # Title/Explore/Encounter/Cleared
│   ├── grid_map.gd           # マップ読込・通行判定
│   ├── dungeon_builder.gd    # グリッド→3D 生成
│   ├── player_controller.gd  # キー入力・移動キュー
│   ├── encounter.gd          # 遭遇開始・逃走
│   └── constants.gd          # キー・寸法・色
└── tools/
    └── smoke_check.gd        # mise check 用
```

依存は **Godot 標準のみ**（アドオンなし）。Level 1 方針と一致。

---

## 10. 実装フェーズ（解析後のロードマップ）

| Phase | 内容 | 完了条件 |
|-------|------|----------|
| **P0** | プロジェクト雛形 + mise の `GODOT_PROJECT` 切替 | `mise run check` / `export:linux` が WizardryFlee で通る |
| **P1** | グリッド移動 + 壁生成 + カメラ | キーボードだけで廊下を歩ける |
| **P2** | 固定エンカウント + 逃走 UI | F で Explore に戻れる |
| **P3** | ゴール＋タイトル／クリア | 一周プレイ可能 |
| **P4** | フレーバー（敵 2–3 種名・色、簡易効果音任意） | 「デモとして見せられる」 |

**戦闘はどの Phase にも入れない。**

---

## 11. mise / Grok 連携（実装時）

### 11.1 親 `mise.toml` への想定追加

現状 `GODOT_PROJECT` は `GrokProbe` 固定。WizardryFlee では例えば:

```toml
# 案 A: タスク単位で上書き
[tasks."wf:export"]
run = "GODOT_PROJECT={{config_root}}/WizardryFlee mise run export:linux"
# 実際は env をタスク内で export して godot を直接呼ぶ方が安全

# 案 B: デフォルト PROJECT を WizardryFlee に切り替え（GrokProbe は別名タスク）
```

推奨: **`wf:*` プレフィックス**で WizardryFlee 専用タスクを足し、GrokProbe は `probe:*` に残す。  
（実装フェーズで `mise.toml` を更新。本 README の段階では未変更。）

### 11.2 Grok の作業ルール

- cwd: `~/my-project/godot-demos`  
- 編集: `WizardryFlee/**`  
- 検証: `mise run …` のみ（バラのシェル増やさない）  
- ユーザー確認: export した Linux バイナリをキーボードでプレイ  

---

## 12. 受け入れ条件（デモ完成の定義）

次をすべて満たせば「荒い 3D Wizardry ライク・逃走デモ」完成とする。

1. [ ] キーボードのみでダンジョンをマス移動・90°回転できる  
2. [ ] 壁に遮られ、マップ外に出ない  
3. [ ] 少なくとも 1 回、怪物遭遇が発生する  
4. [ ] 遭遇中にできることは **逃げる** のみ（攻撃コマンドが存在しない）  
5. [ ] 逃走後、探索に復帰できる  
6. [ ] ゴール到達でクリア表示が出る  
7. [ ] `gl_compatibility` で Linux export が通り、この PC で起動できる  
8. [ ] 見た目は粗くてよいが、**一人称で廊下が認識できる**  

---

## 13. 非機能・性能予算

| 項目 | 予算 |
|------|------|
| 同時 MeshInstance | 目安 200 未満（8×12 壁でも余裕） |
| テクスチャ | 原則なし or 1–2 枚 |
| 目標 FPS | 30 あれば可（60 不要） |
| 解像度 | 1280×720 既定、ウィンドウ可 |
| 音 | なしでも可。入れるなら効果音 2 個まで |

---

## 14. 解析結論

| 問い | 答え |
|------|------|
| この PC + Godot 4.7 で可能か | **可能**（軽量グリッド 3D + UI） |
| Wizardry らしさの核は何か | 一人称マス移動と「廊での遭遇」 |
| 戦闘を捨てて成立するか | **成立する**（逃走＝唯一のインタラクション） |
| 荒い画像で足りるか | **足りる**（空間とルールが伝わればよい） |
| 次に実装すべき最小片 | P0 雛形 → P1 移動 → P2 逃走遭遇 |

**推奨プロダクト名（フォルダ）:** `WizardryFlee`  
**キャッチ:** 「戦えないダンジョン。出会ったら、逃げろ。」

---

## 15. プレイ方法（実装済み）

```bash
cd /home/mevius/my-project/godot-demos
mise run wf:play
# または
./WizardryFlee/Builds/linux/WizardryFlee.x86_64
```

| キー | 動作 |
|------|------|
| Enter / Space | 開始・クリア後タイトルへ |
| W A S D / 矢印 | 前進・左旋回・後退・右旋回 |
| F | 遭遇時のみ：逃げる |
| Esc | タイトル／終了 |

ゴール（金色の床）に到達でクリア。赤い床マスは固定エンカウント（一度逃げるとそのマスは再発生しない）。

再ビルド: `mise run wf:build`

---

*解析＋MVP 実装。戦闘は追加しない。*
