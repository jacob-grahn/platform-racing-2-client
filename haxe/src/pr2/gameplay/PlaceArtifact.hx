package pr2.gameplay;

import openfl.events.Event;
import openfl.events.FocusEvent;
import pr2.lobby.dialogs.ConfirmPopup;
import pr2.lobby.dialogs.Popup;
import pr2.lobby.dialogs.UploadingPopup;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.ServerConfig;
import pr2.runtime.FlCheckBox;
import pr2.runtime.FlComboBox;
import pr2.runtime.FlTextInput;
import pr2.runtime.PR2MovieClip;
import pr2.gameplay.SpecialEvent.PlaceArtifactRequest;
import pr2.util.DisplayUtil;

private typedef UploadFactory = String->Map<String, String>->String->(Dynamic->Void)->UploadingPopup;

/**
	Authored artifact-placement prompt shell opened by `SpecialEvent`.
**/
@:allow(pr2.gameplay.PlaceArtifactTest)
class PlaceArtifact extends Popup {
	public static var instance:Null<PlaceArtifact>;
	private static var uploadFactory:UploadFactory = defaultUpload;
	private static var nowSeconds:Void->Int = function():Int return Std.int(Date.now().getTime() / 1000);

	public final request:PlaceArtifactRequest;
	private var art:Null<PR2MovieClip>;
	private var monthSel:Null<FlComboBox>;
	private var daySel:Null<FlComboBox>;
	private var yearSel:Null<FlComboBox>;
	private var hourBox:Null<FlTextInput>;
	private var minBox:Null<FlTextInput>;
	private var meridSel:Null<FlComboBox>;
	private var nowCheck:Null<FlCheckBox>;
	private var placeBinding:Null<Binding>;
	private var cancelBinding:Null<Binding>;
	private var setTime:Int = 0;
	private var overrideSched:Bool = false;
	private var uploading:Null<UploadingPopup>;

	public function new(request:PlaceArtifactRequest) {
		super();
		this.request = request;
		if (PlaceArtifact.instance != null) {
			remove();
			return;
		}
		PlaceArtifact.instance = this;
		art = PR2MovieClip.fromLinkage("PlaceArtifactGraphic", {maxNestedDepth: 6});
		addChild(art);
		wireControls();
		populateOptions(true);
	}

	private function wireControls():Void {
		monthSel = Std.downcast(DisplayUtil.findByName(art, "monthSel"), FlComboBox);
		daySel = Std.downcast(DisplayUtil.findByName(art, "daySel"), FlComboBox);
		yearSel = Std.downcast(DisplayUtil.findByName(art, "yearSel"), FlComboBox);
		hourBox = Std.downcast(DisplayUtil.findByName(art, "hourBox"), FlTextInput);
		minBox = Std.downcast(DisplayUtil.findByName(art, "minBox"), FlTextInput);
		meridSel = Std.downcast(DisplayUtil.findByName(art, "meridSel"), FlComboBox);
		nowCheck = Std.downcast(DisplayUtil.findByName(art, "now_chk"), FlCheckBox);

		if (monthSel != null) monthSel.addEventListener(Event.CHANGE, selChange);
		if (yearSel != null) yearSel.addEventListener(Event.CHANGE, selChange);
		if (hourBox != null) hourBox.addEventListener(FocusEvent.FOCUS_OUT, validateText);
		if (minBox != null) minBox.addEventListener(FocusEvent.FOCUS_OUT, validateText);
		if (nowCheck != null) nowCheck.addEventListener(Event.CHANGE, checkNowBox);
		placeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "place_bt"), clickPlace);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), clickCancel);
	}

	private function populateOptions(first:Bool = false, ?date:Date):Void {
		if (monthSel == null || daySel == null || yearSel == null) {
			return;
		}
		if (date == null) {
			date = Date.now();
		}
		var thisYear = date.getFullYear();
		if (first) {
			yearSel.removeAll();
			for (i in 0...5) {
				var targetYear = thisYear + i;
				yearSel.addItem({label: targetYear, data: targetYear});
			}
			showTime(date);
			return;
		}

		var previousSelected = daySel.selectedIndex;
		daySel.removeAll();
		for (i in 1...29) {
			daySel.addItem({label: i, data: i});
		}
		var selectedMonth = selectedDataInt(monthSel, 0);
		for (i in 29...32) {
			if (selectedMonth != 1) {
				daySel.addItem({label: i, data: i});
				if (i == 30 && (selectedMonth == 3 || selectedMonth == 5 || selectedMonth == 8 || selectedMonth == 10)) {
					break;
				}
			} else if (i == 29) {
				var selectedYear = yearSel.selectedItem == null ? -1 : selectedDataInt(yearSel, -1);
				if (isLeapYear(selectedYear)) {
					daySel.addItem({label: i, data: i});
				}
				break;
			}
		}
		daySel.selectedIndex = previousSelected;
	}

	private function validateText(?_:Dynamic):Void {
		if (hourBox != null) {
			hourBox.text = Std.string(numLimit(toInt(hourBox.text), 1, 12));
		}
		if (minBox != null) {
			var min = numLimit(toInt(minBox.text), 0, 59);
			minBox.text = (min < 10 ? "0" : "") + min;
		}
	}

	private function selChange(_:Event):Void {
		populateOptions();
	}

	private function checkNowBox(_:Event):Void {
		var enabled = nowCheck == null || !nowCheck.selected;
		if (monthSel != null) monthSel.enabled = enabled;
		if (daySel != null) daySel.enabled = enabled;
		if (yearSel != null) yearSel.enabled = enabled;
		if (hourBox != null) hourBox.enabled = enabled;
		if (minBox != null) minBox.enabled = enabled;
		if (meridSel != null) meridSel.enabled = enabled;
	}

	private function showTime(date:Date):Void {
		if (monthSel == null || daySel == null || yearSel == null || hourBox == null || minBox == null || meridSel == null) {
			return;
		}
		var hour = date.getHours();
		var min = date.getMinutes();
		monthSel.selectedIndex = date.getMonth();
		yearSel.selectedIndex = 0;
		populateOptions();
		daySel.selectedIndex = date.getDate() - 1;
		hourBox.text = Std.string(hour == 0 || hour > 12 ? Std.int(Math.abs(hour - 12)) : hour);
		minBox.text = (min < 10 ? "0" : "") + min;
		meridSel.selectedIndex = hour - 12 >= 0 ? 1 : 0;
	}

	private function getDateFromInput():Date {
		validateText();
		var actualHour = toInt(hourBox == null ? null : hourBox.text) + selectedDataInt(meridSel, 0) * 12;
		actualHour = actualHour == 12 ? 0 : actualHour;
		actualHour = actualHour == 24 ? 12 : numLimit(actualHour, 0, 23);
		return new Date(
			selectedDataInt(yearSel, Date.now().getFullYear()),
			selectedDataInt(monthSel, 0),
			selectedDataInt(daySel, 1),
			actualHour,
			numLimit(toInt(minBox == null ? null : minBox.text), 0, 59),
			0
		);
	}

	private function selectedSetTime(nowSeconds:Int):Int {
		var inputSeconds = Std.int(getDateFromInput().getTime() / 1000);
		if ((nowCheck != null && nowCheck.selected) || inputSeconds < nowSeconds) {
			return 0;
		}
		return inputSeconds;
	}

	private function clickPlace():Void {
		setTime = selectedSetTime(nowSeconds());
		var timeStr = setTime > 0 ? "on " + dateTimeStr(setTime) : "now";
		new ConfirmPopup(placeArtifact, "Are you sure you want to place the artifact " + timeStr + "?");
	}

	private function placeArtifact():Void {
		var effectiveSetTime = setTime < nowSeconds() ? 0 : setTime;
		var fields:Map<String, String> = [
			"level_id" => Std.string(request.levelId),
			"x" => Std.string(request.x),
			"y" => Std.string(request.y),
			"rot" => Std.string(request.rot),
			"set_time" => Std.string(effectiveSetTime),
			"override_sched" => overrideSched ? "1" : "0"
		];
		uploading = uploadFactory(ServerConfig.placeArtifactUrl(), fields, "Placing artifact...", handleResponse);
	}

	private function handleResponse(ret:Dynamic):Void {
		if (ret != null && Reflect.field(ret, "success") != true && Reflect.field(ret, "status") == "scheduled") {
			new ConfirmPopup(function():Void {
				overrideSched = true;
				placeArtifact();
			}, "There is already a scheduled artifact placement. Is it OK to replace it with this one?");
			return;
		}
		startFadeOut();
	}

	private function clickCancel():Void {
		startFadeOut();
	}

	override public function remove():Void {
		if (PlaceArtifact.instance == this) {
			PlaceArtifact.instance = null;
		}
		if (monthSel != null) monthSel.removeEventListener(Event.CHANGE, selChange);
		if (yearSel != null) yearSel.removeEventListener(Event.CHANGE, selChange);
		if (hourBox != null) hourBox.removeEventListener(FocusEvent.FOCUS_OUT, validateText);
		if (minBox != null) minBox.removeEventListener(FocusEvent.FOCUS_OUT, validateText);
		if (nowCheck != null) nowCheck.removeEventListener(Event.CHANGE, checkNowBox);
		LobbyArt.unbind(placeBinding);
		LobbyArt.unbind(cancelBinding);
		if (uploading != null) {
			uploading.remove();
			uploading = null;
		}
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private static function selectedDataInt(combo:Null<FlComboBox>, fallback:Int):Int {
		if (combo == null || combo.selectedItem == null) {
			return fallback;
		}
		return toInt(Reflect.field(combo.selectedItem, "data"), fallback);
	}

	private static function toInt(value:Dynamic, fallback:Int = 0):Int {
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Int)) {
			return value;
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	private static function numLimit(value:Int, minimum:Int, maximum:Int):Int {
		return value < minimum ? minimum : (value > maximum ? maximum : value);
	}

	private static function isLeapYear(year:Int):Bool {
		return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
	}

	private static function defaultUpload(url:String, fields:Map<String, String>, label:String, onResult:Dynamic->Void):UploadingPopup {
		return new UploadingPopup(url, fields, label, onResult);
	}

	private static function dateTimeStr(seconds:Int):String {
		var d = Date.fromTime(seconds * 1000.0);
		var hour = d.getHours();
		var merid = hour >= 12 ? "PM" : "AM";
		var hour12 = hour % 12;
		if (hour12 == 0) {
			hour12 = 12;
		}
		return longMonth(d.getMonth()) + " " + d.getDate() + ", " + d.getFullYear() + " " + hour12 + ":"
			+ StringTools.lpad(Std.string(d.getMinutes()), "0", 2) + ":"
			+ StringTools.lpad(Std.string(d.getSeconds()), "0", 2) + " " + merid;
	}

	private static function longMonth(month:Int):String {
		return switch (month) {
			case 0: "January";
			case 1: "February";
			case 2: "March";
			case 3: "April";
			case 4: "May";
			case 5: "June";
			case 6: "July";
			case 7: "August";
			case 8: "September";
			case 9: "October";
			case 10: "November";
			case 11: "December";
			default: "";
		}
	}
}
