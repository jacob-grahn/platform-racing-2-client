package pr2.runtime;

/**
	Maps the font face names baked into the original PR2 Flash assets onto the
	free, redistributable fonts embedded in this build.

	The Flash SWF embedded Verdana / Arial / Times (proprietary Microsoft fonts)
	plus the custom `Gwibble` and `FontAwesome` faces. We can't legally ship the
	Microsoft fonts, so we substitute metric-compatible free fonts:

	  - Verdana*           -> DejaVu Sans   (DejaVu descends from Bitstream Vera,
	                                         which Jiggmin already used as a fallback)
	  - ArialMT            -> Liberation Sans
	  - TimesNewRomanPSMT  -> Liberation Serif

	`Gwibble` and `FontAwesome` are embedded as-is (their internal family names
	already match the catalog face names).

	Each weight of DejaVu is embedded under its own family name
	("DejaVu Sans Bold", "DejaVu Sans Italic", ...) so the resolved face already
	carries the weight/style. Callers should therefore use `resolve()` for the
	family and `isBold()` / `isItalic()` only when they still need the flags for
	layout; the embedded outlines are exact, so no faux bold/italic synthesis is
	required.
**/
class FontResolver {
	/**
		Default face used when an element omits one. The original code passed
		`"_sans"` here; route it through the same DejaVu substitute for a
		consistent look across hand-written and catalog-driven text.
	**/
	public static inline final DEFAULT:String = "DejaVu Sans";

	static final MAP:Map<String, String> = [
		// Verdana family -> DejaVu Sans (distinct embedded family per weight)
		"Verdana" => "DejaVu Sans",
		"Verdana-Bold" => "DejaVu Sans Bold",
		"Verdana-Italic" => "DejaVu Sans Italic",
		"Verdana-BoldItalic" => "DejaVu Sans Bold Italic",
		// Arial / Times -> Liberation (metric-compatible)
		"ArialMT" => "Liberation Sans",
		"TimesNewRomanPSMT" => "Liberation Serif",
		// Custom faces, embedded under their own names
		"Gwibble" => "Gwibble",
		"FontAwesome" => "FontAwesome",
		// OpenFL device-font aliases
		"_sans" => "DejaVu Sans",
		"_serif" => "Liberation Serif",
	];

	/**
		Resolve an original PR2 face name to an embedded family name. Unknown
		faces (including the lowercase `gwibble*` variant used by a few assets)
		fall back to a sensible family rather than a missing font.
	**/
	public static function resolve(face:String):String {
		if (face == null || face == "") {
			return DEFAULT;
		}
		var mapped = MAP.get(face);
		if (mapped != null) {
			return mapped;
		}
		// Normalize stray variants, e.g. "gwibble*", "gwibble".
		var lower = face.toLowerCase();
		if (lower.indexOf("gwibble") >= 0) {
			return "Gwibble";
		}
		if (lower.indexOf("fontawesome") >= 0) {
			return "FontAwesome";
		}
		if (lower.indexOf("times") >= 0) {
			return "Liberation Serif";
		}
		if (lower.indexOf("arial") >= 0) {
			return "Liberation Sans";
		}
		// Verdana and anything else maps to the workhorse sans.
		return DEFAULT;
	}
}
