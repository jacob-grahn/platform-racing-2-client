package pr2.ui;

/**
	Pure port of the tab-positioning math in Flash `ui.TabsHolder.populateTabs`,
	pulled out so it can be unit-tested without instantiating real tab art.

	Tabs are laid out left-to-right, each placed at the running sum of the prior
	tab widths. If the row is wider than the pane (`maxW`), the tabs are
	overlapped: every tab after the first is pulled left by `tabW * i`, where
	`tabW = (totalWidth - maxW) / (tabCount - 1)`. This is what produces the
	original lobby's compressed, fanned-out tab strip.
**/
class TabLayout {
	private function new() {}

	public static function positions(widths:Array<Float>, maxW:Float):Array<Float> {
		var xs:Array<Float> = [];
		var tabX:Float = 0;
		for (w in widths) {
			xs.push(tabX);
			tabX += w;
		}

		var total = tabX;
		if (total > maxW && widths.length > 1) {
			var tabW = (total - maxW) / (widths.length - 1);
			for (i in 1...xs.length) {
				xs[i] -= tabW * i;
			}
		}
		return xs;
	}

	/** Total width of the laid-out (uncompressed) tab row. */
	public static function totalWidth(widths:Array<Float>):Float {
		var total:Float = 0;
		for (w in widths) {
			total += w;
		}
		return total;
	}
}
