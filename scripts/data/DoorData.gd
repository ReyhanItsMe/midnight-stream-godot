## Registry data tipe dan tekstur pintu horror.
class_name DoorData
extends RefCounted

enum DoorType {
	KAYU_1DAUN,
	KAYU_GANDA,
	BESI_1DAUN,
	BESI_GANDA,
	RUMAH_SAKIT_1DAUN,
	RUMAH_SAKIT_GANDA,
	RUSAK_1DAUN,
	RUSAK_GANDA,
	RANTAI_1DAUN,
	DIPAKU_1DAUN,
	SEL_BESI_1DAUN,
	DARAH_1DAUN,
	TERBUKA_SEDIKIT_1DAUN,
	TERBUKA_MATA_1DAUN
}

const TEXTURES: Dictionary = {
	DoorType.KAYU_1DAUN: "pintu_kayu_1daun.png",
	DoorType.KAYU_GANDA: "pintu_kayu_ganda.png",
	DoorType.BESI_1DAUN: "pintu_besi_1daun.png",
	DoorType.BESI_GANDA: "pintu_besi_ganda.png",
	DoorType.RUMAH_SAKIT_1DAUN: "pintu_rumah_sakit_1daun.png",
	DoorType.RUMAH_SAKIT_GANDA: "pintu_rumah_sakit_ganda.png",
	DoorType.RUSAK_1DAUN: "pintu_rusak_1daun.png",
	DoorType.RUSAK_GANDA: "pintu_rusak_ganda.png",
	DoorType.RANTAI_1DAUN: "pintu_rantai_1daun.png",
	DoorType.DIPAKU_1DAUN: "pintu_dipaku_1daun.png",
	DoorType.SEL_BESI_1DAUN: "pintu_sel_besi_1daun.png",
	DoorType.DARAH_1DAUN: "pintu_darah_1daun.png",
	DoorType.TERBUKA_SEDIKIT_1DAUN: "pintu_terbuka_sedikit_1daun.png",
	DoorType.TERBUKA_MATA_1DAUN: "pintu_terbuka_sedikit_mata_1daun.png"
}

static func get_texture_path(type: DoorType) -> String:
	var file_name: String = TEXTURES.get(type, "pintu_kayu_1daun.png")
	return AssetPaths.Sprites.DOORS_HORROR_DIR + file_name
