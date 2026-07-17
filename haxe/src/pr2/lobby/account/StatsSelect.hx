package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.character.LocalCharacter;

/**
	Port of Flash `ui.StatsSelect`: the speed / acceleration / jumping sliders over
	a shared points budget. The remaining-points readout updates live, and
	individual sliders clamp themselves so the three values never exceed the
	available total (the original `getPointsRemaining` feedback loop).

	The optional level-editor test character mirrors Flash `StatsSelect`: changing
	the sliders immediately updates the live character and can persist the test
	stats through `Settings.LE_TEST_STATS`.
**/
class StatsSelect extends Sprite {
	private var m:Sprite;
	private var remainingBox:Null<TextField>;
	private var speedSlider:StatSlider;
	private var accelSlider:StatSlider;
	private var jumpnSlider:StatSlider;
	private var totalPoints:Int;
	private var localChar:Null<LocalCharacter>;
	public var updateSavedLEStats:Bool = false;

	public function new(tot:Int, speed:Int, accel:Int, jumpn:Int, ?localChar:LocalCharacter) {
		super();
		totalPoints = tot;
		this.localChar = localChar;
		if (totalPoints < speed + accel + jumpn) {
			totalPoints = speed + accel + jumpn;
		}
		m = new Sprite();
		addChild(m);
		var label = new TextField();
		label.x = 2;
		label.y = 2;
		label.width = 122;
		label.height = 15;
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0, true);
		label.text = "Points Remaining:";
		m.addChild(label);
		remainingBox = new TextField();
		remainingBox.name = "textBox";
		remainingBox.x = 130.05;
		remainingBox.y = 2;
		remainingBox.width = 38;
		remainingBox.height = 15;
		remainingBox.selectable = false;
		remainingBox.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), 12, 0, true);
		m.addChild(remainingBox);

		speedSlider = new StatSlider("Speed", this);
		accelSlider = new StatSlider("Acceleration", this);
		jumpnSlider = new StatSlider("Jumping", this);
		speedSlider.setValue(speed);
		accelSlider.setValue(accel);
		jumpnSlider.setValue(jumpn);
		speedSlider.x = accelSlider.x = jumpnSlider.x = 8;
		speedSlider.y = 30;
		accelSlider.y = 70;
		jumpnSlider.y = 110;
		addChild(speedSlider);
		addChild(accelSlider);
		addChild(jumpnSlider);
		updateStatsDisplay();
	}

	public function getPointsRemaining():Int {
		return totalPoints - (speedSlider.value + accelSlider.value + jumpnSlider.value);
	}

	public function updateStatsDisplay():Void {
		if (remainingBox != null) {
			remainingBox.text = Std.string(getPointsRemaining());
		}
		if (localChar != null) {
			localChar.setStats(speedSlider.value, accelSlider.value, jumpnSlider.value);
		}
	}

	public function setStats(speed:Int, accel:Int, jumpn:Int):Void {
		speedSlider.setValue(speed);
		accelSlider.setValue(accel);
		jumpnSlider.setValue(jumpn);
		updateStatsDisplay();
	}

	public function setStatsFromCharacter():Void {
		if (localChar == null) {
			return;
		}
		updateSavedLEStats = false;
		var stats = localChar.stateSnapshot();
		setStats(Math.round(stats.speedStat), Math.round(stats.accelerationStat), Math.round(stats.jumpStat));
	}

	public function noteUserStatChange():Void {
		updateSavedLEStats = true;
	}

	public function saveLEStats():Void {
		if (localChar == null || !localChar.inLE() || !updateSavedLEStats) {
			return;
		}
		Settings.setValue(Settings.LE_TEST_STATS, getStats());
		updateSavedLEStats = false;
	}

	public function getInfoStr():String {
		return speedSlider.value + "`" + accelSlider.value + "`" + jumpnSlider.value;
	}

	public function getStats():{speed:Int, acceleration:Int, jumping:Int} {
		return {speed: speedSlider.value, acceleration: accelSlider.value, jumping: jumpnSlider.value};
	}

	public function remove():Void {
		speedSlider.remove();
		accelSlider.remove();
		jumpnSlider.remove();
		localChar = null;
		if (m != null) {
			if (m.parent != null) m.parent.removeChild(m);
			m = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
