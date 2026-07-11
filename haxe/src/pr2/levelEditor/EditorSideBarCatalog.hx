package pr2.levelEditor;

import pr2.level.ObjectCodes;

typedef EditorSideBarHoverInfo = {
	final title:String;
	final desc:String;
}

/** Static labels and level-background values for the editor sidebars. */
class EditorSideBarCatalog {
	private function new() {}

	public static function hoverInfo(sidebar:String, itemId:String):EditorSideBarHoverInfo {
		return switch (sidebar + ":" + itemId) {
			case "blocks:delete" | "stamps:delete": {title: "Delete Tool", desc: "Click and drag the mouse to delete things with remarkable speed!"};
			case "blocks:basic1": {title: "Basic Block 1", desc: "Normal old every day run of the mill squarish thing that you can stand on."};
			case "blocks:basic2": {title: "Basic Block 2", desc: "Normal old every day run of the mill squarish thing that you can stand on."};
			case "blocks:basic3": {title: "Basic Block 3", desc: "Normal old every day run of the mill squarish thing that you can stand on."};
			case "blocks:basic4": {title: "Basic Block 4", desc: "Normal old every day run of the mill squarish thing that you can stand on."};
			case "blocks:brick": {title: "Brick Block", desc: "A block of poorly mortared bricks that will shatter if it is bumped from below."};
			case "blocks:finish": {title: "Finish Block", desc: "Bumping this marks the end of the race."};
			case "blocks:ice": {title: "Ice Block", desc: "Sliperyyyyiiiee."};
			case "blocks:item": {title: "Item Block", desc: "A block that provides rather lovely and mischievous items when bumped. This can only be used once."};
			case "blocks:infItem": {title: "Infinite Item Block", desc: "This is an item block that will never run out of items."};
			case "blocks:left": {title: "Left Block", desc: "Anyone standing on this will be pushed to the left."};
			case "blocks:right": {title: "Right Block", desc: "Anyone standing on this will be pushed to the right."};
			case "blocks:up": {title: "Up Block", desc: "Anyone who stands on this will be bumped upwards."};
			case "blocks:down": {title: "Down Block", desc: "Anyone who stands on this will have difficulty jumping."};
			case "blocks:teleport": {title: "Teleport Block", desc: "Bump this to be teleported to another one of these with the same color."};
			case "blocks:mine": {title: "Mine Block", desc: "Mines explode rather painfully if you touch them."};
			case "blocks:crumble": {title: "Crumble Block", desc: "This will crumble into pieces if it is hit too hard."};
			case "blocks:vanish": {title: "Vanish Block", desc: "Don't stand for too long, or you'll find yourself falling through the floor."};
			case "blocks:move": {title: "Move Block", desc: "Where will it end up? Nobody knows! Every so often, this will move one space in a random direction. Use sparingly, too many of these can slow the game down."};
			case "blocks:water": {title: "Water Block", desc: "Swim!"};
			case "blocks:rotateR" | "blocks:rotateL": {title: itemId == "rotateR" ? "Rotate Right Block" : "Rotate Left Block", desc: "The wheels on the bus go round and round, round and round, round and round."};
			case "blocks:push": {title: "Push Block", desc: "This block can be pushed around."};
			case "blocks:happy": {title: "Happy Block", desc: "Bump this to increase your stats for the rest of the race."};
			case "blocks:sad": {title: "Sad Block", desc: "Bumping one of these will decrease your stats for the rest of the race."};
			case "blocks:custom": {title: "Custom Stats Block", desc: "Bumping this will set the player's stats to what you specify. The default is 50-50-50."};
			case "blocks:safety": {title: "Safety Net", desc: "Touching this will teleport you back to your last safe location. It's the same as falling off of the course."};
			case "blocks:heart": {title: "Heart Block", desc: "This block grants you one extra heart in Deathmatch mode, and renders you invincible for five fantastic seconds."};
			case "blocks:time": {title: "Time Block", desc: "Adds 10 seconds to your timer."};
			case "blocks:egg": {title: "Egg Minion", desc: "Romps about with evil intent."};
			case "settings:music": {title: "Music", desc: "This song will play by default for users playing your course."};
			case "settings:items": {title: "Items", desc: "These items will be available to players in your course's item boxes."};
			case "settings:hats": {title: "Hats Allowed", desc: "Players may use these hats in your level."};
			case "settings:rank": {title: "Minimum Rank", desc: "Players below this rank will not be able to race on this course."};
			case "settings:gravity": {title: "Gravity Multiplier", desc: "Normal gravity will be multiplied by the number you provide."};
			case "settings:time": {title: "Time Limit", desc: "Racers will have this amount of seconds to complete this course. Enter 0 for infinite time."};
			case "settings:mode": {title: "Game Mode", desc: "Each game mode has a different goal and method of winning."};
			case "settings:sfcm": {title: "Chance of Cowboy Mode", desc: "Super Flying Cowboy Mode will appear this often out of 100."};
			case "settings:pass": {title: "Secret Password", desc: "This password lets players play your course while unpublished."};
			case "stamps:brush": {title: "Draw Menu", desc: "Switch to the draw menu to draw custom backgrounds."};
			case "stamps:text": {title: "Text", desc: "Compose prose with style."};
			case "tools:landscape": {title: "Landscape Mode", desc: "Switch to the landscape toolbar."};
			case "tools:brush": {title: "Brush", desc: "Draw things, yay!"};
			case "tools:eraser": {title: "Eraser", desc: "Erase the things you have drawn, yay!"};
			case "tools:size": {title: "Size Picker", desc: "Change the size of the brush and eraser."};
			case "tools:color": {title: "Color Picker", desc: "Choose your color with wisdom."};
			default: {title: "", desc: ""};
		}
	}

	public static function backgroundSpec(itemId:String):Null<{code:Int, color:Int}> {
		return switch (itemId) {
			case "bg1": {code: ObjectCodes.BG1Code, color: 8172673};
			case "bg2": {code: ObjectCodes.BG2Code, color: 13283754};
			case "bg3": {code: ObjectCodes.BG3Code, color: 528392};
			case "bg4": {code: ObjectCodes.BG4Code, color: 14731448};
			case "bg5": {code: ObjectCodes.BG5Code, color: 0};
			case "bg6": {code: ObjectCodes.BG6Code, color: 0};
			case "bg7": {code: ObjectCodes.BG7Code, color: 0};
			default: null;
		}
	}
}
