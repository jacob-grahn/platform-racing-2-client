package pr2.audio;

typedef MusicTrack = {
	var id:String;
	var label:String;
	var file:String;
}

class MusicCatalog {
	public static final TRACKS:Array<MusicTrack> = [
		track("1", "Orbital Trance - Space Planet", "01_orbital-trance.mp3"),
		track("2", "Code - Stefano Maccarelli", "02_code.mp3"),
		track("3", "Paradise on E - API", "03_paradise-on-e_ng32772.mp3"),
		track("4", "Crying Soul (FL Mix) - Pyroific", "04_crying-soul_ng102483.mp3"),
		track("5", "My Vision - David Orr", "05_my-vision_ng44613.mp3"),
		track("6", "Switchblade - Detective Jabsco", "06_switchblade_ng59342.mp3"),
		track("7", "The Wires - Cheez-R-Us", "07_the-wires_ng74690.mp3"),
		track("8", "Before Mydnite - F-777", "08_before-mydnite_ng108133.mp3"),
		track("10", "Broked It - SWiTCH", "10_broked-it_ng51265.mp3"),
		track("11", "Hello? - TMM43", "11_hello_ng83720.mp3"),
		track("12", "Pyrokinesis - Sean Tucker", "12_pyrokinesis_ng98624.mp3"),
		track("13", "Flowerz 'n' Herbz - Brunzolaitis", "13_flowerz-n-herbs_ng109884.mp3"),
		track("14", "Instrumental #4 - Reasoner", "14_instrumental-4_ng128701.mp3"),
		track("15", "Prismatic - Lunanova", "15_prismatic.mp3"),
		track("17", "Toodaloo - mustangman", "17_toodaloo.mp3"),
		track("18", "Night Shade - Goliathe", "18_night-shade.mp3"),
		track("19", "Blizzard! - Majicke", "19_blizzard.mp3"),
		track("20", "Pasture (Instrumental) - Dangevin", "20_pasture.mp3"),
		track("21", "Sunset Raiders - AVL", "21_sunset-raiders.mp3")
	];
	public static final ARTIFACT:MusicTrack = track("16", "We Are Loud - Dynamedion", "16_we-are-loud.mp3");

	public static function enabled(disabled:Array<String>, inEditor:Bool = false, artifact:Bool = false):Array<MusicTrack> {
		var result:Array<MusicTrack> = [{id: "0", label: "None", file: ""}];
		if (inEditor) result.push({id: "random", label: "Random", file: ""});
		for (song in TRACKS) if (inEditor || disabled.indexOf(song.id) < 0) result.push(song);
		if (artifact) result.push(ARTIFACT);
		return result;
	}

	public static function select(songs:Array<MusicTrack>, requested:String, randomIndex:Int):Int {
		if (requested == "0") return 0;
		if (requested != "" && requested != "random") {
			for (i in 0...songs.length) if (songs[i].id == requested) return i;
		}
		return songs.length <= 1 ? 0 : 1 + positiveMod(randomIndex, songs.length - 1);
	}

	private static function positiveMod(value:Int, divisor:Int):Int return ((value % divisor) + divisor) % divisor;
	private static function track(id:String, label:String, file:String):MusicTrack return {id: id, label: label, file: file};
}
