class_name Palette
extends RefCounted

# ==============================================================================
# 1. MONOKROM (BLACK, SLATE, GRAY, WHITE)
# ==============================================================================
const BLACK: Color            = Color(0.0, 0.0, 0.0, 1.0)
const BLACK_DEEP: Color       = Color(0.04, 0.05, 0.07, 1.0)
const BLACK_MODAL: Color      = Color(0.05, 0.06, 0.09, 0.98)
const BLACK_CARD: Color       = Color(0.08, 0.09, 0.14, 1.0)

const SLATE_DARK: Color       = Color(0.12, 0.14, 0.20, 1.0)
const SLATE: Color            = Color(0.24, 0.28, 0.38, 0.85)
const SLATE_LIGHT: Color      = Color(0.38, 0.44, 0.58, 1.0)

const GRAY_DARK: Color        = Color(0.22, 0.22, 0.25, 1.0)
const GRAY: Color             = Color(0.50, 0.55, 0.66, 1.0)
const GRAY_LIGHT: Color       = Color(0.72, 0.75, 0.82, 1.0)

const WHITE_OFF: Color        = Color(0.85, 0.88, 0.92, 1.0)
const WHITE_SMOKE: Color      = Color(0.94, 0.95, 0.98, 1.0)
const WHITE: Color            = Color(1.0, 1.0, 1.0, 1.0)

# ==============================================================================
# 2. EMAS & KUNING (GOLD & YELLOW)
# ==============================================================================
const GOLD_DARK: Color        = Color(0.55, 0.45, 0.12, 1.0)
const GOLD: Color             = Color(0.95, 0.82, 0.25, 0.95)
const GOLD_LIGHT: Color       = Color(1.0, 0.92, 0.55, 1.0)
const GOLD_BRIGHT: Color      = Color(1.0, 0.97, 0.75, 1.0)

const YELLOW_DARK: Color      = Color(0.65, 0.52, 0.10, 1.0)
const YELLOW: Color           = Color(0.95, 0.78, 0.20, 1.0)
const YELLOW_LIGHT: Color     = Color(1.0, 0.88, 0.40, 1.0)

# ==============================================================================
# 3. MERAH & ORANYE (RED & ORANGE)
# ==============================================================================
const RED_DEEP: Color         = Color(0.25, 0.06, 0.08, 0.98)
const RED_DARK: Color         = Color(0.55, 0.14, 0.14, 1.0)
const RED: Color              = Color(0.85, 0.22, 0.22, 1.0)
const RED_LIGHT: Color        = Color(0.95, 0.28, 0.28, 1.0)
const RED_BRIGHT: Color       = Color(1.0, 0.45, 0.45, 1.0)

const ORANGE_DARK: Color      = Color(0.60, 0.30, 0.05, 1.0)
const ORANGE: Color           = Color(0.92, 0.48, 0.15, 1.0)
const ORANGE_LIGHT: Color     = Color(1.0, 0.65, 0.35, 1.0)

# ==============================================================================
# 4. HIJAU (GREEN & EMERALD)
# ==============================================================================
const GREEN_DARK: Color       = Color(0.08, 0.32, 0.16, 1.0)
const GREEN: Color            = Color(0.18, 0.68, 0.34, 1.0)
const GREEN_LIGHT: Color      = Color(0.25, 0.88, 0.45, 1.0)
const GREEN_NEON: Color       = Color(0.35, 1.0, 0.55, 1.0)

# ==============================================================================
# 5. BIRU & CYAN (BLUE & TEAL)
# ==============================================================================
const BLUE_DEEP: Color        = Color(0.06, 0.12, 0.22, 1.0)
const BLUE_DARK: Color        = Color(0.12, 0.28, 0.52, 1.0)
const BLUE: Color             = Color(0.22, 0.50, 0.88, 1.0)
const BLUE_LIGHT: Color       = Color(0.45, 0.70, 1.0, 1.0)

const CYAN_DARK: Color        = Color(0.05, 0.35, 0.40, 1.0)
const CYAN: Color             = Color(0.15, 0.75, 0.85, 1.0)
const CYAN_LIGHT: Color       = Color(0.40, 0.90, 0.95, 1.0)

# ==============================================================================
# 6. UNGU & MAGENTA (PURPLE & VIOLET)
# ==============================================================================
const PURPLE_DARK: Color      = Color(0.24, 0.12, 0.38, 1.0)
const PURPLE: Color           = Color(0.55, 0.30, 0.82, 1.0)
const PURPLE_LIGHT: Color     = Color(0.75, 0.52, 0.98, 1.0)

# ==============================================================================
# 7. TRANSPARAN
# ==============================================================================

const TRANSPARENT: Color    = Color(0.0, 0.0, 0.0, 0.0)

# ==============================================================================
# 8. HELPER: GRADASI & TRANSPARANSI DINAMIS
# ==============================================================================

## Membuat variasi warna dengan alpha kustom instan (misal: Palette.alpha(Palette.GOLD, 0.5))
static func alpha(base_color: Color, a_val: float) -> Color:
	var c := base_color
	c.a = clampf(a_val, 0.0, 1.0)
	return c

## Interpolasi warna (Linear Gradient di kode)
static func blend(from_color: Color, to_color: Color, weight: float) -> Color:
	return from_color.lerp(to_color, clampf(weight, 0.0, 1.0))

## Menghasilkan GradientTexture2D instan untuk background bar / panel
static func make_horizontal_gradient(from_col: Color, to_col: Color, w: int = 128, h: int = 16) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([from_col, to_col])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = w
	tex.height = h
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex

