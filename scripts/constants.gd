class_name WFConstants
extends Object

## Shared constants for WizardryFlee.

const CELL_SIZE := 3.0
const WALL_HEIGHT := 2.8
const EYE_HEIGHT := 1.45
const MOVE_TIME := 0.18
const TURN_TIME := 0.16

## Facing: 0=N(-Z), 1=E(+X), 2=S(+Z), 3=W(-X)
const DIR_FORWARD := [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]

# Camera looks down local -Z. Yaw for N/E/S/W world axes.
const DIR_YAW := [0.0, -PI * 0.5, PI, PI * 0.5]

const FONT_PATH := "res://assets/fonts/migu-1m-regular.ttf"

const MONSTERS := [
	{"name": "スライム", "flavor": "ぬるぬるした影が立ちはだかった…", "color": Color(0.35, 0.85, 0.4)},
	{"name": "骸骨兵", "flavor": "朽ちた骨がカタカタと鳴る。", "color": Color(0.9, 0.9, 0.85)},
	{"name": "影の獣", "flavor": "闇そのものが牙を剥いた。", "color": Color(0.35, 0.2, 0.55)},
]
