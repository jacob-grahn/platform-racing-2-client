package pr2.lobby.account;

import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.runtime.PR2MovieClip;

/**
	Port of Flash `ui.StatsSelect`: the speed / acceleration / jumping sliders over
	a shared points budget. The remaining-points readout updates live, and
	individual sliders clamp themselves so the three values never exceed the
	available total (the original `getPointsRemaining` feedback loop).

	The level-editor test-character hookup (`localChar`) is omitted — the lobby
	Account tab always constructs `StatsSelect` with no live character.
**/
class StatsSelect extends Sprite {
	private var m:PR2MovieClip;
	private var remainingBox:Null<TextField>;
	private var speedSlider:StatSlider;
	private var accelSlider:StatSlider;
	private var jumpnSlider:StatSlider;
	private var totalPoints:Int;

	public function new(tot:Int, speed:Int, accel:Int, jumpn:Int) {
		super();
		totalPoints = tot;
		if (totalPoints < speed + accel + jumpn) {
			totalPoints = speed + accel + jumpn;
		}
		m = PR2MovieClip.fromLinkage("PointsRemainingGraphic", {maxNestedDepth: 4});
		addChild(m);
		remainingBox = LobbyArt.text(m, "textBox");

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
	}

	public function setStats(speed:Int, accel:Int, jumpn:Int):Void {
		speedSlider.setValue(speed);
		accelSlider.setValue(accel);
		jumpnSlider.setValue(jumpn);
		updateStatsDisplay();
	}

	public function getInfoStr():String {
		return speedSlider.value + "`" + accelSlider.value + "`" + jumpnSlider.value;
	}

	public function remove():Void {
		speedSlider.remove();
		accelSlider.remove();
		jumpnSlider.remove();
		if (m != null) {
			m.dispose();
			m = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
