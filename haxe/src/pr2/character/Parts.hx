package pr2.character;

import pr2.net.ServerConfig;

/**
	Port of the Flash top-level `Parts` class: the static catalogue of every
	hat/head/body/feet part — their ids, display names, flavour descriptions, and
	"how to obtain" text — plus the helpers that validate a part type/id and look
	those values up.

	The Flash original reached its arrays/strings through dynamic
	`Parts['VARS_' + type]` / `Parts[type + '_ARRAY']` access; here the per-type
	data is selected with explicit switches and the desc/obtain text is keyed by
	the same `TYPE_NAME` strings the original built (e.g. `HAT_EXP`).
**/
class Parts {
	public static inline var GREATEST_ID:Int = 50;
	public static final TYPES = ["HAT", "HEAD", "BODY", "FEET"];

	// The var-name suffix for each id (id-1 indexed), matching Flash VARS_*.
	private static final VARS_HAT = [
		"NONE", "EXP", "KONG", "PROP", "COWBOY", "CROWN", "SANTA", "PARTY", "TOP", "JUMP_START", "MOON", "THIEF", "JIGG", "ARTIFACT", "JELLYFISH", "CHEESE"
	];
	private static final VARS_HEAD = [
		"CLASSIC", "TIRED", "SMILER", "FLOWER", "CLASSIC_GIRL", "GOOF", "DOWNER", "BALLOON", "WORM", "UNICORN", "BIRD", "SUN", "CANDY", "INVISIBLE",
		"FOOTBALL_HELMET", "BASKETBALL", "STICK", "CAT", "ELEPHANT", "ANT", "ASTRONAUT", "ALIEN", "DINO", "ARMOR", "FAIRY", "GINGERBREAD", "BUBBLE", "KING",
		"QUEEN", "SIR", "VERY_INVISIBLE", "TACO", "SLENDER", "SANTA", "FROST_DJINN", "REINDEER", "CROCODILE", "VALENTINE", "BUNNY", "GECKO", "BAT", "SEA",
		"BREW", "JACKOLANTERN", "XMAS", "SNOWMAN", "BLOBFISH", "TURKEY", "DOG", "GLADIATOR"
	];
	private static final VARS_BODY = [
		"CLASSIC", "STRAP", "DRESS", "PEC", "GUT", "COLLAR", "MISS_PR2", "BELT", "SNAKE", "BIRD", "INVISIBLE", "BEE", "STICK", "CAT", "CAR", "ELEPHANT",
		"ANT", "ASTRONAUT", "ALIEN", "GALAXY", "BUBBLE", "DINO", "ARMOR", "FAIRY", "GINGERBREAD", "KING", "QUEEN", "SIR", "FRED", "VERY_INVISIBLE", "TACO",
		"SLENDER", "", "SANTA", "FROST_DJINN", "REINDEER", "CROCODILE", "VALENTINE", "BUNNY", "GECKO", "BAT", "SEA", "BREW", "", "XMAS", "SNOWMAN", "",
		"TURKEY", "DOG", "GLADIATOR"
	];
	private static final VARS_FEET = [
		"CLASSIC", "HEEL", "LOAFER", "CLEAT", "MAGNET", "TINY", "SANDAL", "BARE", "NICE", "BIRD", "INVISIBLE", "STICK", "CAT", "TIRE", "ELEPHANT", "ANT",
		"ASTRONAUT", "ALIEN", "GALAXY", "DINO", "ARMOR", "FAIRY", "GINGERBREAD", "KING", "QUEEN", "SIR", "VERY_INVISIBLE", "BUBBLE", "TACO", "SLENDER", "",
		"", "", "SANTA", "FROST_DJINN", "REINDEER", "CROCODILE", "VALENTINE", "BUNNY", "GECKO", "BAT", "SEA", "BREW", "", "XMAS", "SNOWMAN", "", "TURKEY",
		"DOG", "GLADIATOR"
	];

	// Owned-part id lists (gaps removed), matching Flash *_ARRAY. Note HAT_ARRAY
	// omits HAT_NONE (1): a player always "owns" no-hat, it just is not selectable.
	private static final HAT_ARRAY = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
	private static final HEAD_ARRAY = [for (i in 1...51) i];
	private static final BODY_ARRAY = [for (i in 1...51) if (i != 33 && i != 44 && i != 47) i];
	private static final FEET_ARRAY = [for (i in 1...51) if (i != 31 && i != 32 && i != 33 && i != 44 && i != 47) i];

	public static final HAT_NAMES_ARRAY = [
		"", "EXP", "Kongregate", "Propeller", "Cowboy", "Crown", "Santa", "Party", "Top", "Jump Start", "Moon", "Thief", "Jigg", "Artifact", "Jellyfish",
		"Cheese"
	];
	public static final HEAD_NAMES_ARRAY = [
		"Classic", "Tired", "Smiling", "Flower", "Lady", "Goof", "Downer", "Balloon", "Worm", "Unicorn", "Giant Bird", "Cool Sun", "Candy", "Invisible",
		"Helmet", "Basketball", "Stick", "Cat", "Elephant", "Ant", "Astronaut", "Alien", "Dino", "Armor", "Fairy", "Gingerbread", "Bubble", "Wise King",
		"Wise Queen", "Sir", "Very Invisible", "Taco", "Slender", "Santa", "Frost Djinn", "Reindeer", "Crocodile", "Valentine", "Bunny", "Gecko", "Bat",
		"Sea", "Brew", "Jack-o'-Lantern", "Star", "Snowman", "Blobfish", "Turkey", "Dog", "Gladiator"
	];
	public static final BODY_NAMES_ARRAY = [
		"Classic", "Strap", "Dress", "Pec", "Gut", "Collar", "Miss PR2", "Belt", "Snake", "Giant Bird", "Invisible", "Bee", "Stick", "Cat", "Car",
		"Elephant", "Ant", "Astronaut", "Alien", "Galaxy", "Bubble", "Dino", "Armor", "Fairy", "Gingerbread", "Wise King", "Wise Queen", "Sir", "Fred",
		"Very Invisible", "Taco", "Slender", "", "Santa", "Frost Djinn", "Reindeer", "Crocodile", "Valentine", "Bunny", "Gecko", "Bat", "Sea", "Brew", "",
		"Christmas Tree", "Snowman", "", "Turkey", "Dog", "Gladiator"
	];
	public static final FEET_NAMES_ARRAY = [
		"Classic", "Heel", "Loafer", "Cleat", "Magnet", "Tiny", "Sandal", "Bare", "Nice", "Giant Bird", "Invisible", "Stick", "Cat", "Tire", "Elephant",
		"Ant", "Astronaut", "Alien", "Galaxy", "Dino", "Armor", "Fairy", "Gingerbread", "Wise King", "Wise Queen", "Sir", "Very Invisible", "Bubble", "Taco",
		"Slender", "", "", "", "Santa", "Frost Djinn", "Reindeer", "Crocodile", "Valentine", "Bunny", "Gecko", "Bat", "Sea", "Brew", "", "Present", "Snowman",
		"", "Turkey", "Dog", "Gladiator"
	];

	private static var descByKey:Null<Map<String, String>> = null;
	private static var obtainByKey:Null<Map<String, String>> = null;

	private function new() {}

	/** Normalises a (possibly epic `E`-prefixed) part type, or `null` if invalid. */
	public static function validateType(type:String):Null<String> {
		type = type.toUpperCase();
		if (type != "HAT" && type != "HEAD" && type != "BODY" && type != "FEET" && type != "EHAT" && type != "EHEAD" && type != "EBODY" && type != "EFEET") {
			return null;
		}
		if (type.charAt(0) == "E") {
			type = type.substr(1);
		}
		return type;
	}

	/** Returns the `TYPE_VARNAME` key for a valid part, or `null` if the id is not real. */
	public static function verifyPart(type:String, id:Int):Null<String> {
		var t = validateType(type);
		if (t == null) {
			return null;
		}
		if (id < 1
			|| id > GREATEST_ID
			|| (t == "HAT" && id > 16)
			|| (t == "BODY" && id == 33)
			|| (t == "FEET" && id > 30 && id < 34)
			|| ((t == "BODY" || t == "FEET") && (id == 44 || id == 47))) {
			return null;
		}
		return t + "_" + vars(t)[id - 1];
	}

	/** The list of owned part ids for a type (gaps removed), or `null` for a bad type. */
	public static function getPartArray(type:String):Null<Array<Int>> {
		var t = validateType(type);
		return switch (t) {
			case "HAT": HAT_ARRAY;
			case "HEAD": HEAD_ARRAY;
			case "BODY": BODY_ARRAY;
			case "FEET": FEET_ARRAY;
			default: null;
		}
	}

	/** Display name for a part (without the type prefix). */
	public static function getName(type:String, id:Int):String {
		var t = validateType(type);
		var arr = switch (t) {
			case "HAT": HAT_NAMES_ARRAY;
			case "HEAD": HEAD_NAMES_ARRAY;
			case "BODY": BODY_NAMES_ARRAY;
			case "FEET": FEET_NAMES_ARRAY;
			default: null;
		}
		if (arr == null || id < 1 || id > arr.length) {
			return "";
		}
		return arr[id - 1];
	}

	/** Flavour description, or `null` if the part is not real. */
	public static function getDesc(type:String, id:Int):Null<String> {
		var key = verifyPart(type, id);
		return key == null ? null : descMap().get(key);
	}

	/** "How to obtain" text, or `null` if the part is not real. */
	public static function getObtain(type:String, id:Int):Null<String> {
		var key = verifyPart(type, id);
		return key == null ? null : obtainMap().get(key);
	}

	/** Plural type label used in catalogue headings (HATS/HEADS/BODIES/FEET). */
	public static function getPlural(type:String):String {
		var t = validateType(type);
		if (t == "HAT" || t == "HEAD") {
			return t + "S";
		}
		if (t == "BODY") {
			return "BODIES";
		}
		return t == null ? "" : t;
	}

	private static function vars(type:String):Array<String> {
		return switch (type) {
			case "HAT": VARS_HAT;
			case "HEAD": VARS_HEAD;
			case "BODY": VARS_BODY;
			case "FEET": VARS_FEET;
			default: [];
		}
	}

	private static function descMap():Map<String, String> {
		if (descByKey == null) {
			descByKey = buildDescMap();
		}
		return descByKey;
	}

	private static function obtainMap():Map<String, String> {
		if (obtainByKey == null) {
			obtainByKey = buildObtainMap();
		}
		return obtainByKey;
	}

	private static function contestsLink():String {
		return 'Won in contests. <u><font color="#0000FF"><a href="${ServerConfig.DEFAULT_HOST}/contests" target="_blank">Here\'s some more information!</a></font></u>';
	}

	private static function buildDescMap():Map<String, String> {
		var m = new Map<String, String>();
		// hats
		m.set("HAT_EXP", "If you finish a race with this hat, it will increase your EXP gain by 100%!");
		m.set("HAT_KONG", "If you finish a race with this hat, it will increase your GP gain by 100%!");
		m.set("HAT_PROP", "Hold up while wearing this hat to float!");
		m.set("HAT_COWBOY", "Fly, cowboy, fly!");
		m.set("HAT_CROWN", "Wear this hat to become immune to mines, laser guns, and swords!");
		m.set("HAT_SANTA", "Briefly freezes the blocks you stand on!");
		m.set("HAT_PARTY", "Wear this hat to become immune to lightning!");
		m.set("HAT_TOP", "Stroll through vanish blocks with class!");
		m.set("HAT_JUMP_START", "Waiting is slow! Start racing right away.");
		m.set("HAT_MOON", "Soar to new heights by defying the laws of gravity!");
		m.set("HAT_THIEF", "Steal other player's hats --even crowns!");
		m.set("HAT_JIGG", "Bounce on the heads of your opponents!");
		m.set("HAT_ARTIFACT", "Leave your opponents in the dust for a glorious 30 seconds.");
		m.set("HAT_JELLYFISH", "Give nearby opponents a nasty sting!");
		m.set("HAT_CHEESE", "Turn crumble blocks into feta cheese --break through with record speed!");
		// heads
		m.set("HEAD_CLASSIC", "Rock it old school.");
		m.set("HEAD_TIRED", "Did you stay up late playing PR2?");
		m.set("HEAD_SMILER", "Glad to be here!");
		m.set("HEAD_FLOWER", "Spring's finest flower.");
		m.set("HEAD_CLASSIC_GIRL", "Girls are way cooler.");
		m.set("HEAD_GOOF", "The funny one of the bunch.");
		m.set("HEAD_DOWNER", "Cheer up!");
		m.set("HEAD_BALLOON", "So happy you might float away!");
		m.set("HEAD_WORM", "Squiggly.");
		m.set("HEAD_UNICORN", "Pretty mythical, if you ask me.");
		m.set("HEAD_BIRD", "Squawk!");
		m.set("HEAD_SUN", "It's always a nice day with this head around.");
		m.set("HEAD_CANDY", "Pretty sweet, if you ask me.");
		m.set("HEAD_INVISIBLE", "Wow, where'd you go?");
		m.set("HEAD_FOOTBALL_HELMET", "Hike!");
		m.set("HEAD_BASKETBALL", "He shoots, he scores!");
		m.set("HEAD_STICK", "Satisfy your inner doodler.");
		m.set("HEAD_CAT", "Meow!");
		m.set("HEAD_ELEPHANT", "Trumpet!");
		m.set("HEAD_ANT", "...crawl?");
		m.set("HEAD_ASTRONAUT", "That's one small step for man... one giant leap for mankind.");
		m.set("HEAD_ALIEN", "You surely, maybe, definitely come in peace.");
		m.set("HEAD_DINO", "ROAR!");
		m.set("HEAD_ARMOR", "Disclaimer: This won't make you a knight.");
		m.set("HEAD_FAIRY", "Pretty magical, if you ask me.");
		m.set("HEAD_GINGERBREAD", "Pretty tasty, if you ask me.");
		m.set("HEAD_BUBBLE", "Pop!");
		m.set("HEAD_KING", "The most benevolent monarch PR2 has ever seen.");
		m.set("HEAD_QUEEN", "The real brains of the royal family.");
		m.set("HEAD_SIR", "Ever so fancy.");
		m.set("HEAD_VERY_INVISIBLE", "Okay, this time I really can't see you...");
		m.set("HEAD_TACO", "It doesn't even have to be a Tuesday!");
		m.set("HEAD_SLENDER", "How many pages do I have?");
		m.set("HEAD_SANTA", "Ho ho ho!");
		m.set("HEAD_FROST_DJINN", "A higher being of great power.");
		m.set("HEAD_REINDEER", "Rudolph has been dethroned as the most famous reindeer of all.");
		m.set("HEAD_CROCODILE", "Your opponents had better run in a zig-zag pattern to escape you!");
		m.set("HEAD_VALENTINE", "\"Ahhh! Girls have cooties!! And it's Valentine's Day!!!\"");
		m.set("HEAD_BUNNY", "No easter eggs here!");
		m.set("HEAD_GECKO", "...slither?");
		m.set("HEAD_BAT", "...echolocate?");
		m.set("HEAD_SEA", "We got the spirit, you got to hear it, under the sea!");
		m.set("HEAD_BREW", "Hydration is key.");
		m.set("HEAD_JACKOLANTERN", "Spook your friends!");
		m.set("HEAD_XMAS", "Twinkle twinkle...");
		m.set("HEAD_SNOWMAN", "Channel your inner frosty.");
		m.set("HEAD_BLOBFISH", "The world's most misunderstood fish.");
		m.set("HEAD_TURKEY", "Gobble, gobble!");
		m.set("HEAD_DOG", "WOOF BARK BORK");
		m.set("HEAD_GLADIATOR", "The toughest gladiator in all of Ancient Rome.");
		// bodies
		m.set("BODY_CLASSIC", "Rock it old school.");
		m.set("BODY_STRAP", "Strapping!");
		m.set("BODY_DRESS", "Very dressy.");
		m.set("BODY_PEC", "Do you even lift?");
		m.set("BODY_GUT", "Couch potato.");
		m.set("BODY_COLLAR", "Dracula would be proud.");
		m.set("BODY_MISS_PR2", "You won the pageant!");
		m.set("BODY_BELT", "How you keep your pants up, especially when performing. It's incredible.");
		m.set("BODY_SNAKE", "Ssssssquiggly.");
		m.set("BODY_BIRD", "Squawk!");
		m.set("BODY_INVISIBLE", "Wow, where'd you go?");
		m.set("BODY_BEE", "Bzzzzzz!");
		m.set("BODY_STICK", "Satisfy your inner doodler.");
		m.set("BODY_CAT", "Meow!");
		m.set("BODY_CAR", "Vroom vroom! Beep beep!");
		m.set("BODY_ELEPHANT", "Trumpet!");
		m.set("BODY_ANT", "...crawl?");
		m.set("BODY_ASTRONAUT", "That's one small step for man... one giant leap for mankind.");
		m.set("BODY_ALIEN", "You surely, maybe, <i>definitely</i> come in peace.");
		m.set("BODY_GALAXY", "The power of the cosmos, at your disposal.");
		m.set("BODY_BUBBLE", "Pop!");
		m.set("BODY_DINO", "ROAR!");
		m.set("BODY_ARMOR", "Disclaimer: This won't make you a knight.");
		m.set("BODY_FAIRY", "Pretty magical, if you ask me.");
		m.set("BODY_GINGERBREAD", "Pretty tasty, if you ask me.");
		m.set("BODY_KING", "The most benevolent monarch PR2 has ever seen.");
		m.set("BODY_QUEEN", "The real brains of the royal family.");
		m.set("BODY_SIR", "Ever so fancy.");
		m.set("BODY_FRED", "Hi, I'm Fred the Giant Cactus. I'll be seeng you around!");
		m.set("BODY_VERY_INVISIBLE", "Okay, this time I <i>really</i> can't see you...");
		m.set("BODY_TACO", "It doesn't even have to be a Tuesday!");
		m.set("BODY_SLENDER", "How many pages do I have?");
		m.set("BODY_SANTA", "Ho ho ho!");
		m.set("BODY_FROST_DJINN", "A higher being of great power.");
		m.set("BODY_REINDEER", "Rudolph has been dethroned as the most famous reindeer of all.");
		m.set("BODY_CROCODILE", "Your opponents had better run in a zig-zag pattern to escape you!");
		m.set("BODY_VALENTINE", "\"Ahhh! Girls have cooties!! And it's Valentine's Day!!!\"");
		m.set("BODY_BUNNY", "No easter eggs here!");
		m.set("BODY_GECKO", "...slither?");
		m.set("BODY_BAT", "...echolocate?");
		m.set("BODY_SEA", "We got the spirit, you got to hear it, under the sea!");
		m.set("BODY_BREW", "Hydration is key.");
		m.set("BODY_XMAS", "Oh Christmas tree, oh Christmas tree...");
		m.set("BODY_SNOWMAN", "Channel your inner frosty.");
		m.set("BODY_TURKEY", "Gobble, gobble!");
		m.set("BODY_DOG", "WOOF BARK BORK");
		m.set("BODY_GLADIATOR", "The toughest gladiator in all of Ancient Rome.");
		// feet
		m.set("FEET_CLASSIC", "Rock it old school.");
		m.set("FEET_HEEL", "Very dressy.");
		m.set("FEET_LOAFER", "It's casual.");
		m.set("FEET_CLEAT", "Put me in coach; I'm ready to play!");
		m.set("FEET_MAGNET", "Opposites attract.");
		m.set("FEET_TINY", "If you blink, you might miss them.");
		m.set("FEET_SANDAL", "These might go well with some pajamas.");
		m.set("FEET_BARE", "Back to basics.");
		m.set("FEET_NICE", "So nice.");
		m.set("FEET_BIRD", "Squawk!");
		m.set("FEET_INVISIBLE", "Wow, where'd you go?");
		m.set("FEET_STICK", "Satisfy your inner doodler.");
		m.set("FEET_CAT", "Meow!");
		m.set("FEET_TIRE", "Vroom vroom! Beep beep!");
		m.set("FEET_ELEPHANT", "Trumpet!");
		m.set("FEET_ANT", "...crawl?");
		m.set("FEET_ASTRONAUT", "That's one small step for man... one giant leap for mankind.");
		m.set("FEET_ALIEN", "You surely, maybe, <i>definitely</i> come in peace.");
		m.set("FEET_GALAXY", "The power of the cosmos, at your disposal.");
		m.set("FEET_DINO", "ROAR!");
		m.set("FEET_ARMOR", "Disclaimer: This won't make you a knight.");
		m.set("FEET_FAIRY", "Pretty magical, if you ask me.");
		m.set("FEET_GINGERBREAD", "Pretty tasty, if you ask me.");
		m.set("FEET_KING", "The most benevolent monarch PR2 has ever seen.");
		m.set("FEET_QUEEN", "The real brains of the royal family.");
		m.set("FEET_SIR", "Ever so fancy.");
		m.set("FEET_VERY_INVISIBLE", "Okay, this time I <i>really</i> can't see you...");
		m.set("FEET_BUBBLE", "Pop!");
		m.set("FEET_TACO", "It doesn't even have to be a Tuesday!");
		m.set("FEET_SLENDER", "How many pages do I have?");
		m.set("FEET_SANTA", "Ho ho ho!");
		m.set("FEET_FROST_DJINN", "A higher being of great power.");
		m.set("FEET_REINDEER", "Rudolph has been dethroned as the most famous reindeer of all.");
		m.set("FEET_CROCODILE", "Your opponents had better run in a zig-zag pattern to escape you!");
		m.set("FEET_VALENTINE", "\"Ahhh! Girls have cooties!! And it's Valentine's Day!!!\"");
		m.set("FEET_BUNNY", "No easter eggs here!");
		m.set("FEET_GECKO", "...slither?");
		m.set("FEET_BAT", "...echolocate?");
		m.set("FEET_SEA", "We got the spirit, you got to hear it, under the sea!");
		m.set("FEET_BREW", "Hydration is key.");
		m.set("FEET_XMAS", "Presenting a present for you!");
		m.set("FEET_SNOWMAN", "Channel your inner frosty.");
		m.set("FEET_TURKEY", "Gobble, gobble!");
		m.set("FEET_DOG", "WOOF BARK BORK");
		m.set("FEET_GLADIATOR", "The toughest gladiator in all of Ancient Rome.");
		return m;
	}

	private static function buildObtainMap():Map<String, String> {
		var m = new Map<String, String>();
		var contests = contestsLink();
		var artifact = 'Find the artifact first. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>';
		var startup = "It's there when you create your account!";
		var random1to4 = "Won randomly in races with 1-4 players.";
		var random2to4 = "Won randomly in races with 2-4 players.";
		var vault = "Purchased in the Vault of Magics.";
		var rentVault = "Cannot be obtained; rented in the Vault of Magics.";
		var kong = "Click the Kongregate button on the login page.";
		var deliverance = "Has a 1 in 3 chance of appearing on -Deliverance- by changelings.";
		var lotw = 'Create a level that becomes Level of the Week. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=3509" target="_blank">Here\'s some more information!</a></font></u>';
		var roman = "Finish Romªn Empire by Overbeing.";
		// hats
		m.set("HAT_EXP", random2to4);
		m.set("HAT_KONG", kong);
		m.set("HAT_PROP", "Finish Hat Factory by Jiggmin or Volcanic Inferno by Pounce.");
		m.set("HAT_COWBOY",
			'Fold 100,000 points on Folding at Home. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=19" target="_blank">Here\'s some more information!</a></font></u>');
		m.set("HAT_CROWN",
			'Fold 5,000 points on Folding at Home. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=19" target="_blank">Here\'s some more information!</a></font></u>');
		m.set("HAT_SANTA", random2to4);
		m.set("HAT_PARTY", "Log into your PR2 account on New Year's Eve or Day. Also won randomly in races with 2-4 players.");
		m.set("HAT_TOP", "Finish The Golden Compass by -Shadowfax-.");
		m.set("HAT_JUMP_START", "Won randomly during a happy hour in races with 2-4 players.");
		m.set("HAT_MOON", "Finish Redemption by cooldude90.");
		m.set("HAT_THIEF", "Finish Apocalypse by Divinity.");
		m.set("HAT_JIGG", "Finish Buto (EXACT) by ZePHiR after finding the hidden Jigg Hat.");
		m.set("HAT_ARTIFACT",
			'This is a special part. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>');
		m.set("HAT_JELLYFISH", "Finish Deeper by Sothal.");
		m.set("HAT_CHEESE", "Finish Moon is made w/ cheese by ktosss450 after finding the hidden Cheese Hat.");
		// heads
		m.set("HEAD_CLASSIC", startup);
		m.set("HEAD_TIRED", startup);
		m.set("HEAD_SMILER", startup);
		m.set("HEAD_FLOWER", startup);
		m.set("HEAD_CLASSIC_GIRL", startup);
		m.set("HEAD_GOOF", startup);
		m.set("HEAD_DOWNER", startup);
		m.set("HEAD_BALLOON", startup);
		m.set("HEAD_WORM", startup);
		m.set("HEAD_UNICORN", "Won in Campaign #1 Level #1 with 2-4 players.");
		m.set("HEAD_BIRD", "Won in Campaign #1 Level #4 with 2-4 players.");
		m.set("HEAD_SUN", "Won in Campaign #1 Level #2 with 2-4 players.");
		m.set("HEAD_CANDY", "Won in Campaign #1 Level #7 with 2-4 players.");
		m.set("HEAD_INVISIBLE", random1to4);
		m.set("HEAD_FOOTBALL_HELMET", "Won in Campaign #1 Level #3 with 2-4 players.");
		m.set("HEAD_BASKETBALL", random1to4);
		m.set("HEAD_STICK", random1to4);
		m.set("HEAD_CAT", "Won in Campaign #2 Level #3 with 2-4 players.");
		m.set("HEAD_ELEPHANT", "Won in Campaign #2 Level #6 with 2-4 players.");
		m.set("HEAD_ANT", kong);
		m.set("HEAD_ASTRONAUT", "Won in Campaign #3 Level #1 with 2-4 players.");
		m.set("HEAD_ALIEN", "Won in Campaign #3 Level #4 with 2-4 players.");
		m.set("HEAD_DINO", "Won in Campaign #4 Level #3 with 2-4 players.");
		m.set("HEAD_ARMOR", random1to4);
		m.set("HEAD_FAIRY", "Won in Campaign #4 Level #6 with 2-4 players.");
		m.set("HEAD_GINGERBREAD", random1to4);
		m.set("HEAD_BUBBLE", artifact);
		m.set("HEAD_KING", vault);
		m.set("HEAD_QUEEN", vault);
		m.set("HEAD_SIR", random1to4);
		m.set("HEAD_VERY_INVISIBLE", rentVault);
		m.set("HEAD_TACO", random1to4);
		m.set("HEAD_SLENDER", deliverance);
		m.set("HEAD_SANTA", "Log into your PR2 account on Christmas Eve or Day.");
		m.set("HEAD_FROST_DJINN", vault);
		m.set("HEAD_REINDEER", contests);
		m.set("HEAD_CROCODILE", contests);
		m.set("HEAD_VALENTINE", "Log into your PR2 account on Valentine's Day.");
		m.set("HEAD_BUNNY", "Log into your PR2 account during Easter Weekend.");
		m.set("HEAD_GECKO", contests);
		m.set("HEAD_BAT", contests);
		m.set("HEAD_SEA", "Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.");
		m.set("HEAD_BREW", contests);
		m.set("HEAD_JACKOLANTERN", "Log into your PR2 account on Halloween.");
		m.set("HEAD_XMAS", "Won in Campaign #6 Level #3 during the holiday season.");
		m.set("HEAD_SNOWMAN", "Won in Campaign #6 Level #6 during the holiday season.");
		m.set("HEAD_BLOBFISH", "Finish Underwater World by Odin0030.");
		m.set("HEAD_TURKEY", "Log into your PR2 account on Thanksgiving.");
		m.set("HEAD_DOG", lotw);
		m.set("HEAD_GLADIATOR", roman);
		// bodies
		m.set("BODY_CLASSIC", startup);
		m.set("BODY_STRAP", startup);
		m.set("BODY_DRESS", startup);
		m.set("BODY_PEC", startup);
		m.set("BODY_GUT", startup);
		m.set("BODY_COLLAR", startup);
		m.set("BODY_MISS_PR2", startup);
		m.set("BODY_BELT", startup);
		m.set("BODY_SNAKE", startup);
		m.set("BODY_BIRD", "Won in Campaign #1 Level #5 with 2-4 players.");
		m.set("BODY_INVISIBLE", random1to4);
		m.set("BODY_BEE", "Won in Campaign #1 Level #8 with 2-4 players.");
		m.set("BODY_STICK", random1to4);
		m.set("BODY_CAT", "Won in Campaign #2 Level #2 with 2-4 players.");
		m.set("BODY_CAR", "Won in Campaign #2 Level #8 with 2-4 players.");
		m.set("BODY_ELEPHANT", "Won in Campaign #2 Level #5 with 2-4 players.");
		m.set("BODY_ANT", kong);
		m.set("BODY_ASTRONAUT", "Won in Campaign #3 Level #2 with 2-4 players.");
		m.set("BODY_ALIEN", "Won in Campaign #3 Level #5 with 2-4 players.");
		m.set("BODY_GALAXY", "Won in Campaign #3 Level #7 with 2-4 players.");
		m.set("BODY_BUBBLE", artifact);
		m.set("BODY_DINO", "Won in Campaign #4 Level #2 with 2-4 players.");
		m.set("BODY_ARMOR", "Won in Campaign #4 Level #8 with 2-4 players.");
		m.set("BODY_FAIRY", "Won in Campaign #4 Level #5 with 2-4 players.");
		m.set("BODY_GINGERBREAD", random1to4);
		m.set("BODY_KING", vault);
		m.set("BODY_QUEEN", vault);
		m.set("BODY_SIR", random1to4);
		m.set("BODY_FRED", rentVault);
		m.set("BODY_VERY_INVISIBLE", rentVault);
		m.set("BODY_TACO", random1to4);
		m.set("BODY_SLENDER", deliverance);
		m.set("BODY_SANTA", "Log into your PR2 account on Christmas Eve or Day.");
		m.set("BODY_FROST_DJINN", vault);
		m.set("BODY_REINDEER", contests);
		m.set("BODY_CROCODILE", contests);
		m.set("BODY_VALENTINE", "Log into your PR2 account on Valentine's Day.");
		m.set("BODY_BUNNY", "Log into your PR2 account during Easter Weekend.");
		m.set("BODY_GECKO", contests);
		m.set("BODY_BAT", contests);
		m.set("BODY_SEA", "Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.");
		m.set("BODY_BREW", contests);
		m.set("BODY_XMAS", "Won in Campaign #6 Level #2 during the holiday season.");
		m.set("BODY_SNOWMAN", "Won in Campaign #6 Level #5 during the holiday season.");
		m.set("BODY_TURKEY", "Log into your PR2 account on Thanksgiving.");
		m.set("BODY_DOG", lotw);
		m.set("BODY_GLADIATOR", roman);
		// feet
		m.set("FEET_CLASSIC", startup);
		m.set("FEET_HEEL", startup);
		m.set("FEET_LOAFER", startup);
		m.set("FEET_CLEAT", startup);
		m.set("FEET_MAGNET", startup);
		m.set("FEET_TINY", startup);
		m.set("FEET_SANDAL", startup);
		m.set("FEET_BARE", startup);
		m.set("FEET_NICE", startup);
		m.set("FEET_BIRD", "Won in Campaign #1 Level #6 with 2-4 players.");
		m.set("FEET_INVISIBLE", random1to4);
		m.set("FEET_STICK", random1to4);
		m.set("FEET_CAT", "Won in Campaign #2 Level #1 with 2-4 players.");
		m.set("FEET_TIRE", "Won in Campaign #2 Level #7 with 2-4 players.");
		m.set("FEET_ELEPHANT", "Won in Campaign #2 Level #4 with 2-4 players.");
		m.set("FEET_ANT", kong);
		m.set("FEET_ASTRONAUT", "Won in Campaign #3 Level #3 with 2-4 players.");
		m.set("FEET_ALIEN", "Won in Campaign #3 Level #6 with 2-4 players.");
		m.set("FEET_GALAXY", "Won in Campaign #3 Level #8 with 2-4 players.");
		m.set("FEET_DINO", "Won in Campaign #4 Level #1 with 2-4 players.");
		m.set("FEET_ARMOR", "Won in Campaign #4 Level #7 with 2-4 players.");
		m.set("FEET_FAIRY", "Won in Campaign #4 Level #4 with 2-4 players.");
		m.set("FEET_GINGERBREAD", random1to4);
		m.set("FEET_KING", vault);
		m.set("FEET_QUEEN", vault);
		m.set("FEET_SIR", random1to4);
		m.set("FEET_VERY_INVISIBLE", rentVault);
		m.set("FEET_BUBBLE", artifact);
		m.set("FEET_TACO", random1to4);
		m.set("FEET_SLENDER", deliverance);
		m.set("FEET_SANTA", "Log into your PR2 account on Christmas Eve or Day.");
		m.set("FEET_FROST_DJINN", vault);
		m.set("FEET_REINDEER", contests);
		m.set("FEET_CROCODILE", contests);
		m.set("FEET_VALENTINE", "Log into your PR2 account on Valentine's Day.");
		m.set("FEET_BUNNY", "Log into your PR2 account on Easter Weekend.");
		m.set("FEET_GECKO", contests);
		m.set("FEET_BAT", contests);
		m.set("FEET_SEA", "Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.");
		m.set("FEET_BREW", contests);
		m.set("FEET_XMAS", "Won in Campaign #6 Level #1 during the holiday season.");
		m.set("FEET_SNOWMAN", "Won in Campaign #6 Level #4 during the holiday season.");
		m.set("FEET_TURKEY", "Log into your PR2 account on Thanksgiving.");
		m.set("FEET_DOG", lotw);
		m.set("FEET_GLADIATOR", roman);
		return m;
	}
}
