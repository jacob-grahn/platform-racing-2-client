package pr2.lobby.players;

import pr2.lobby.account.AccountCharacter;

class ProfileCharacter {
	public static function create(data:ProfileData):AccountCharacter {
		var c = new AccountCharacter(data.number("hat"), data.number("head"), data.number("body"), data.number("feet"));
		c.setHatColors(data.number("hatColor"), data.number("hatColor2"));
		c.setHeadColors(data.number("headColor"), data.number("headColor2"));
		c.setBodyColors(data.number("bodyColor"), data.number("bodyColor2"));
		c.setFeetColors(data.number("feetColor"), data.number("feetColor2"));
		return c;
	}
}
