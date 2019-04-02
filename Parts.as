package
{
    import data.class_28;

    public class Parts
    {

        // general
        private static var init:Boolean = false;
        private static var GREATEST_ID:int = 41;
        private static var TYPES:Array = ['HAT', 'HEAD', 'BODY', 'FEET'];

        // hats
        private static var VARS_HAT:Array = ['NONE', 'EXP', 'KONG', 'PROP', 'COWBOY', 'CROWN', 'SANTA', 'PARTY', 'TOP', 'JUMP_START', 'MOON', 'THIEF', 'JIGG', 'ARTIFACT'];
        public static var HAT_NONE:int = 1;
        public static var HAT_EXP:int = 2;
        public static var HAT_KONG:int = 3;
        public static var HAT_PROP:int = 4;
        public static var HAT_COWBOY:int = 5;
        public static var HAT_CROWN:int = 6;
        public static var HAT_SANTA:int = 7;
        public static var HAT_PARTY:int = 8;
        public static var HAT_TOP:int = 9;
        public static var HAT_JUMP_START:int = 10;
        public static var HAT_MOON:int = 11;
        public static var HAT_THIEF:int = 12;
        public static var HAT_JIGG:int = 13;
        public static var HAT_ARTIFACT:int = 14;

        // heads
        private static var VARS_HEAD:Array = ['CLASSIC', 'TIRED', 'SMILER', 'FLOWER', 'CLASSIC_GIRL', 'GOOF', 'DOWNER', 'BALLOON', 'WORM', 'UNICORN', 'BIRD', 'SUN', 'CANDY', 'INVISIBLE', 'FOOTBALL_HELMET', 'BASKETBALL', 'STICK', 'CAT', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'BUBBLE', 'KING', 'QUEEN', 'SIR', 'VERY_INVISIBLE', 'TACO', 'SLENDER', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT'];
        public static var HEAD_CLASSIC:int = 1;
        public static var HEAD_TIRED:int = 2;
        public static var HEAD_SMILER:int = 3;
        public static var HEAD_FLOWER:int = 4;
        public static var HEAD_CLASSIC_GIRL:int = 5;
        public static var HEAD_GOOF:int = 6;
        public static var HEAD_DOWNER:int = 7;
        public static var HEAD_BALLOON:int = 8;
        public static var HEAD_WORM:int = 9;
        public static var HEAD_UNICORN:int = 10;
        public static var HEAD_BIRD:int = 11;
        public static var HEAD_SUN:int = 12;
        public static var HEAD_CANDY:int = 13;
        public static var HEAD_INVISIBLE:int = 14;
        public static var HEAD_FOOTBALL_HELMET:int = 15;
        public static var HEAD_BASKETBALL:int = 16;
        public static var HEAD_STICK:int = 17;
        public static var HEAD_CAT:int = 18;
        public static var HEAD_ELEPHANT:int = 19;
        public static var HEAD_ANT:int = 20;
        public static var HEAD_ASTRONAUT:int = 21;
        public static var HEAD_ALIEN:int = 22;
        public static var HEAD_DINO:int = 23;
        public static var HEAD_ARMOR:int = 24;
        public static var HEAD_FAIRY:int = 25;
        public static var HEAD_GINGERBREAD:int = 26;
        public static var HEAD_BUBBLE:int = 27;
        public static var HEAD_KING:int = 28;
        public static var HEAD_QUEEN:int = 29;
        public static var HEAD_SIR:int = 30;
        public static var HEAD_VERY_INVISIBLE:int = 31;
        public static var HEAD_TACO:int = 32;
        public static var HEAD_SLENDER:int = 33;
        public static var HEAD_SANTA:int = 34;
        public static var HEAD_FROST_DJINN:int = 35;
        public static var HEAD_REINDEER:int = 36;
        public static var HEAD_CROCODILE:int = 37;
        public static var HEAD_VALENTINE:int = 38;
        public static var HEAD_BUNNY:int = 39;
        public static var HEAD_GECKO:int = 40;
        public static var HEAD_BAT:int = 41;

        // bodies
        private static var VARS_BODY:Array = ['CLASSIC', 'STRAP', 'DRESS', 'PEC', 'GUT', 'COLLAR', 'MISS_PR2', 'BELT', 'SNAKE', 'BIRD', 'INVISIBLE', 'BEE', 'STICK', 'CAT', 'CAR', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'GALAXY', 'BUBBLE', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'KING', 'QUEEN', 'SIR', 'FRED', 'VERY_INVISIBLE', 'TACO', 'SLENDER', '', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT'];
        public static var BODY_CLASSIC:int = 1;
        public static var BODY_STRAP:int = 2;
        public static var BODY_DRESS:int = 3;
        public static var BODY_PEC:int = 4;
        public static var BODY_GUT:int = 5;
        public static var BODY_COLLAR:int = 6;
        public static var BODY_MISS_PR2:int = 7;
        public static var BODY_BELT:int = 8;
        public static var BODY_SNAKE:int = 9;
        public static var BODY_BIRD:int = 10;
        public static var BODY_INVISIBLE:int = 11;
        public static var BODY_BEE:int = 12;
        public static var BODY_STICK:int = 13;
        public static var BODY_CAT:int = 14;
        public static var BODY_CAR:int = 15;
        public static var BODY_ELEPHANT:int = 16; // bean
        public static var BODY_ANT:int = 17;
        public static var BODY_ASTRONAUT:int = 18;
        public static var BODY_ALIEN:int = 19;
        public static var BODY_GALAXY:int = 20;
        public static var BODY_BUBBLE:int = 21;
        public static var BODY_DINO:int = 22;
        public static var BODY_ARMOR:int = 23;
        public static var BODY_FAIRY:int = 24;
        public static var BODY_GINGERBREAD:int = 25;
        public static var BODY_KING:int = 26;
        public static var BODY_QUEEN:int = 27;
        public static var BODY_SIR:int = 28;
        public static var BODY_FRED:int = 29;
        public static var BODY_VERY_INVISIBLE:int = 30;
        public static var BODY_TACO:int = 31;
        public static var BODY_SLENDER:int = 32;
        public static var BODY_SANTA:int = 34;
        public static var BODY_FROST_DJINN:int = 35;
        public static var BODY_REINDEER:int = 36;
        public static var BODY_CROCODILE:int = 37;
        public static var BODY_VALENTINE:int = 38;
        public static var BODY_BUNNY:int = 39;
        public static var BODY_GECKO:int = 40;
        public static var BODY_BAT:int = 41;

        // feet
        private static var VARS_FEET:Array = ['CLASSIC', 'HEEL', 'LOAFER', 'CLEAT', 'MAGNET', 'TINY', 'SANDAL', 'BARE', 'NICE', 'BIRD', 'INVISIBLE', 'STICK', 'CAT', 'TIRE', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'GALAXY', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'KING', 'QUEEN', 'SIR', 'VERY_INVISIBLE', 'BUBBLE', 'TACO', 'SLENDER', '', '', '', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT'];
        public static var FEET_CLASSIC:int = 1;
        public static var FEET_HEEL:int = 2;
        public static var FEET_LOAFER:int = 3;
        public static var FEET_CLEAT:int = 4;
        public static var FEET_MAGNET:int = 5;
        public static var FEET_TINY:int = 6;
        public static var FEET_SANDAL:int = 7;
        public static var FEET_BARE:int = 8;
        public static var FEET_NICE:int = 9;
        public static var FEET_BIRD:int = 10;
        public static var FEET_INVISIBLE:int = 11;
        public static var FEET_STICK:int = 12;
        public static var FEET_CAT:int = 13;
        public static var FEET_TIRE:int = 14;
        public static var FEET_ELEPHANT:int = 15;
        public static var FEET_ANT:int = 16;
        public static var FEET_ASTRONAUT:int = 17;
        public static var FEET_ALIEN:int = 18;
        public static var FEET_GALAXY:int = 19;
        public static var FEET_DINO:int = 20;
        public static var FEET_ARMOR:int = 21;
        public static var FEET_FAIRY:int = 22;
        public static var FEET_GINGERBREAD:int = 23;
        public static var FEET_KING:int = 24;
        public static var FEET_QUEEN:int = 25;
        public static var FEET_SIR:int = 26;
        public static var FEET_VERY_INVISIBLE:int = 27;
        public static var FEET_BUBBLE:int = 28;
        public static var FEET_TACO:int = 29;
        public static var FEET_SLENDER:int = 30;
        public static var FEET_SANTA:int = 34;
        public static var FEET_FROST_DJINN:int = 35;
        public static var FEET_REINDEER:int = 36;
        public static var FEET_CROCODILE:int = 37;
        public static var FEET_VALENTINE:int = 38;
        public static var FEET_BUNNY:int = 39;
        public static var FEET_GECKO:int = 40;
        public static var FEET_BAT:int = 41;

        // sets
        public static var SET_CLASSIC:Array = [HEAD_CLASSIC, BODY_CLASSIC, FEET_CLASSIC];
        public static var SET_BIRD:Array = [HEAD_BIRD, BODY_BIRD, FEET_BIRD];
        public static var SET_INVISIBLE:Array = [HEAD_INVISIBLE, BODY_INVISIBLE, FEET_INVISIBLE];
        public static var SET_STICK:Array = [HEAD_STICK, BODY_STICK, FEET_STICK];
        public static var SET_CAT:Array = [HEAD_CAT, BODY_CAT, FEET_CAT];
        public static var SET_ELEPHANT:Array = [HEAD_ELEPHANT, BODY_ELEPHANT, FEET_ELEPHANT];
        public static var SET_ANT:Array = [HEAD_ANT, BODY_ANT, FEET_ANT];
        public static var SET_ASTRONAUT:Array = [HEAD_ASTRONAUT, BODY_ASTRONAUT, FEET_ASTRONAUT];
        public static var SET_ALIEN:Array = [HEAD_ALIEN, BODY_ALIEN, FEET_ALIEN];
        public static var SET_DINO:Array = [HEAD_DINO, BODY_DINO, FEET_DINO];
        public static var SET_ARMOR:Array = [HEAD_ARMOR, BODY_ARMOR, FEET_ARMOR];
        public static var SET_FAIRY:Array = [HEAD_FAIRY, BODY_FAIRY, FEET_FAIRY];
        public static var SET_GINGERBREAD:Array = [HEAD_GINGERBREAD, BODY_GINGERBREAD, FEET_GINGERBREAD];
        public static var SET_BUBBLE:Array = [HEAD_BUBBLE, BODY_BUBBLE, FEET_BUBBLE];
        public static var SET_KING:Array = [HEAD_KING, BODY_KING, FEET_KING];
        public static var SET_QUEEN:Array = [HEAD_QUEEN, BODY_QUEEN, FEET_QUEEN];
        public static var SET_SIR:Array = [HEAD_SIR, BODY_SIR, FEET_SIR];
        public static var SET_VERY_INVISIBLE:Array = [HEAD_VERY_INVISIBLE, BODY_VERY_INVISIBLE, FEET_VERY_INVISIBLE];
        public static var SET_TACO:Array = [HEAD_TACO, BODY_TACO, FEET_TACO];
        public static var SET_SLENDER:Array = [HEAD_SLENDER, BODY_SLENDER, FEET_SLENDER];
        public static var SET_SANTA:Array = [HEAD_SANTA, BODY_SANTA, FEET_SANTA];
        public static var SET_FROST_DJINN:Array = [HEAD_FROST_DJINN, BODY_FROST_DJINN, FEET_FROST_DJINN];
        public static var SET_REINDEER:Array = [HEAD_REINDEER, BODY_REINDEER, FEET_REINDEER];
        public static var SET_CROCODILE:Array = [HEAD_CROCODILE, BODY_CROCODILE, FEET_CROCODILE];
        public static var SET_VALENTINE:Array = [HEAD_VALENTINE, BODY_VALENTINE, FEET_VALENTINE];
        public static var SET_BUNNY:Array = [HEAD_BUNNY, BODY_BUNNY, FEET_BUNNY];
        public static var SET_GECKO:Array = [HEAD_GECKO, BODY_GECKO, FEET_GECKO];
        public static var SET_BAT:Array = [HEAD_BAT, BODY_BAT, FEET_BAT];

        // descriptions
        public static var DESC_HAT_EXP:String = 'If you finish a race with this hat, it will increase your EXP gain by 100%!';
        public static var DESC_HAT_KONG:String = 'If you finish a race with this hat, it will increase your EXP gain by 25%!';
        public static var DESC_HAT_PROP:String = 'Hold up while wearing this hat to float!';
        public static var DESC_HAT_COWBOY:String = 'Fly, cowboy, fly!';
        public static var DESC_HAT_CROWN:String = 'Wear this hat to become immune to mines, laser guns, and swords!';
        public static var DESC_HAT_SANTA:String = 'Briefly freezes the blocks you stand on!';
        public static var DESC_HAT_PARTY:String = 'Wear this hat to become immune to lightning!';
        public static var DESC_HAT_TOP:String = 'Stroll through vanish blocks with class!';
        public static var DESC_HAT_JUMP_START:String = 'Waiting is slow! Start racing right away.';
        public static var DESC_HAT_MOON:String = 'Soar to new heights by defying the laws of gravity!';
        public static var DESC_HAT_THIEF:String = 'Steal other player\'s hats --even crowns!';
        public static var DESC_HAT_JIGG:String = 'Bounce on the heads of your opponents!';

        public static var DESC_HEAD_CLASSIC:String = 'Rock it old school.';
        public static var DESC_HEAD_TIRED:String = 'Did you stay up late playing PR2?';
        public static var DESC_HEAD_SMILER:String = 'Glad to be here!';
        public static var DESC_HEAD_FLOWER:String = 'Spring\'s finest flower.';
        public static var DESC_HEAD_CLASSIC_GIRL:String = 'Girls are way cooler.';
        public static var DESC_HEAD_GOOF:String = 'The funny one of the bunch.';
        public static var DESC_HEAD_DOWNER:String = 'Cheer up!';
        public static var DESC_HEAD_BALLOON:String = 'So happy you might float away!';
        public static var DESC_HEAD_WORM:String = 'Squiggly.';
        public static var DESC_HEAD_UNICORN:String = 'Pretty mythical, if you ask me.';
        public static var DESC_HEAD_BIRD:String = 'Squawk!';
        public static var DESC_HEAD_SUN:String = 'It\'s always a nice day with this head around.';
        public static var DESC_HEAD_CANDY:String = 'Pretty sweet, if you ask me.';
        public static var DESC_HEAD_INVISIBLE:String = 'Wow, where\'d you go?';
        public static var DESC_HEAD_FOOTBALL_HELMET:String = 'Hike!';
        public static var DESC_HEAD_BASKETBALL:String = 'He shoots, he scores!';
        public static var DESC_HEAD_STICK:String = 'Satisfy your inner doodler.';
        public static var DESC_HEAD_CAT:String = 'Meow!';
        public static var DESC_HEAD_ELEPHANT:String = 'Trumpet!';
        public static var DESC_HEAD_ANT:String = '...crawl?';
        public static var DESC_HEAD_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static var DESC_HEAD_ALIEN:String = 'You surely, maybe, definitely come in peace.';
        public static var DESC_HEAD_DINO:String = 'ROAR!';
        public static var DESC_HEAD_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static var DESC_HEAD_FAIRY:String = 'Pretty magical, if you ask me.';
        public static var DESC_HEAD_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static var DESC_HEAD_BUBBLE:String = 'Pop!';
        public static var DESC_HEAD_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static var DESC_HEAD_QUEEN:String = 'The real brains of the royal family.';
        public static var DESC_HEAD_SIR:String = 'Ever so fancy.';
        public static var DESC_HEAD_VERY_INVISIBLE:String = 'Okay, this time I really can\'t see you...';
        public static var DESC_HEAD_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static var DESC_HEAD_SLENDER:String = 'How many pages do I have?';
        public static var DESC_HEAD_SANTA:String = 'Ho ho ho!';
        public static var DESC_HEAD_FROST_DJINN:String = 'A higher being of great power.';
        public static var DESC_HEAD_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static var DESC_HEAD_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static var DESC_HEAD_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static var DESC_HEAD_BUNNY:String = 'No easter eggs here!';
        public static var DESC_HEAD_GECKO:String = '...slither?';
        public static var DESC_HEAD_BAT:String = '...echolocate?';

        public static var DESC_BODY_CLASSIC:String = 'Rock it old school.';
        public static var DESC_BODY_STRAP:String = 'Strapping!';
        public static var DESC_BODY_DRESS:String = 'Very dressy.';
        public static var DESC_BODY_PEC:String = 'Do you even lift?';
        public static var DESC_BODY_GUT:String = 'Couch potato.';
        public static var DESC_BODY_COLLAR:String = 'Dracula would be proud.';
        public static var DESC_BODY_MISS_PR2:String = 'You won the pageant!';
        public static var DESC_BODY_BELT:String = 'How you keep your pants up, especially when performing. It\'s incredible.';
        public static var DESC_BODY_SNAKE:String = 'Ssssssquiggly.';
        public static var DESC_BODY_BIRD:String = 'Squawk!';
        public static var DESC_BODY_INVISIBLE:String = 'Wow, where\'d you go?';
        public static var DESC_BODY_BEE:String = 'Bzzzzzz!';
        public static var DESC_BODY_STICK:String = 'Satisfy your inner doodler.';
        public static var DESC_BODY_CAT:String = 'Meow!';
        public static var DESC_BODY_CAR:String = 'Vroom vroom! Beep beep!';
        public static var DESC_BODY_ELEPHANT:String = 'Trumpet!'; // bean
        public static var DESC_BODY_ANT:String = '...crawl?';
        public static var DESC_BODY_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static var DESC_BODY_ALIEN:String = 'You surely, maybe, <i>definitely</i> come in peace.';
        public static var DESC_BODY_GALAXY:String = 'The power of the cosmos, harnessed and consolidated here for your convenience.';
        public static var DESC_BODY_BUBBLE:String = 'Pop!';
        public static var DESC_BODY_DINO:String = 'ROAR!';
        public static var DESC_BODY_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static var DESC_BODY_FAIRY:String = 'Pretty magical, if you ask me.';
        public static var DESC_BODY_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static var DESC_BODY_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static var DESC_BODY_QUEEN:String = 'The real brains of the royal family.';
        public static var DESC_BODY_SIR:String = 'Ever so fancy.';
        public static var DESC_BODY_FRED:String = 'Hi, I\'m Fred the Giant Cactus. I\'ll be seeng you around!';
        public static var DESC_BODY_VERY_INVISIBLE:String = 'Okay, this time I <i>really</i> can\'t see you...';
        public static var DESC_BODY_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static var DESC_BODY_SLENDER:String = 'How many pages do I have?';
        public static var DESC_BODY_SANTA:String = 'Ho ho ho!';
        public static var DESC_BODY_FROST_DJINN:String = 'A higher being of great power.';
        public static var DESC_BODY_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static var DESC_BODY_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static var DESC_BODY_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static var DESC_BODY_BUNNY:String = 'No easter eggs here!';
        public static var DESC_BODY_GECKO:String = '...slither?';
        public static var DESC_BODY_BAT:String = '...echolocate?';

        public static var DESC_FEET_CLASSIC:String = 'Rock it old school.';
        public static var DESC_FEET_HEEL:String = 'Very dressy.';
        public static var DESC_FEET_LOAFER:String = 'It\'s casual.';
        public static var DESC_FEET_CLEAT:String = 'Put me in coach; I\'m ready to play!';
        public static var DESC_FEET_MAGNET:String = 'Opposites attract.';
        public static var DESC_FEET_TINY:String = 'If you blink, you might miss them.';
        public static var DESC_FEET_SANDAL:String = 'These might go well with some pajamas.';
        public static var DESC_FEET_BARE:String = 'Back to basics.';
        public static var DESC_FEET_NICE:String = 'So nice.';
        public static var DESC_FEET_BIRD:String = 'Squawk!';
        public static var DESC_FEET_INVISIBLE:String = 'Wow, where\'d you go?';
        public static var DESC_FEET_STICK:String = 'Satisfy your inner doodler.';
        public static var DESC_FEET_CAT:String = 'Meow!';
        public static var DESC_FEET_TIRE:String = 'Vroom vroom! Beep beep!';
        public static var DESC_FEET_ELEPHANT:String = 'Trumpet!';
        public static var DESC_FEET_ANT:String = '...crawl?';
        public static var DESC_FEET_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static var DESC_FEET_ALIEN:String = 'You surely, maybe, <i>definitely</i> come in peace.';
        public static var DESC_FEET_GALAXY:String = 'The power of the cosmos, harnessed and consolidated here for your convenience.';
        public static var DESC_FEET_DINO:String = 'ROAR!';
        public static var DESC_FEET_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static var DESC_FEET_FAIRY:String = 'Pretty magical, if you ask me.';
        public static var DESC_FEET_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static var DESC_FEET_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static var DESC_FEET_QUEEN:String = 'The real brains of the royal family.';
        public static var DESC_FEET_SIR:String = 'Ever so fancy.';
        public static var DESC_FEET_VERY_INVISIBLE:String = 'Okay, this time I <i>really</i> can\'t see you...';
        public static var DESC_FEET_BUBBLE:String = 'Pop!';
        public static var DESC_FEET_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static var DESC_FEET_SLENDER:String = 'How many pages do I have?';
        public static var DESC_FEET_SANTA:String = 'Ho ho ho!';
        public static var DESC_FEET_FROST_DJINN:String = 'A higher being of great power.';
        public static var DESC_FEET_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static var DESC_FEET_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static var DESC_FEET_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static var DESC_FEET_BUNNY:String = 'No easter eggs here!';
        public static var DESC_FEET_GECKO:String = '...slither?';
        public static var DESC_FEET_BAT:String = '...echolocate?';

        // arrays
        private static var HAT_ARRAY:Array = [HAT_EXP, HAT_KONG, HAT_PROP, HAT_COWBOY, HAT_CROWN, HAT_SANTA, HAT_PARTY, HAT_TOP, HAT_JUMP_START, HAT_MOON, HAT_THIEF, HAT_JIGG];
        private static var HEAD_ARRAY:Array = [HEAD_CLASSIC, HEAD_TIRED, HEAD_SMILER, HEAD_FLOWER, HEAD_CLASSIC_GIRL, HEAD_GOOF, HEAD_DOWNER, HEAD_BALLOON, HEAD_WORM, HEAD_UNICORN, HEAD_BIRD, HEAD_SUN, HEAD_CANDY, HEAD_INVISIBLE, HEAD_FOOTBALL_HELMET, HEAD_BASKETBALL, HEAD_STICK, HEAD_CAT, HEAD_ELEPHANT, HEAD_ANT, HEAD_ASTRONAUT, HEAD_ALIEN, HEAD_DINO, HEAD_ARMOR, HEAD_FAIRY, HEAD_GINGERBREAD, HEAD_BUBBLE, HEAD_KING, HEAD_QUEEN, HEAD_SIR, /*HEAD_VERY_INVISIBLE,*/ HEAD_TACO, HEAD_SLENDER, HEAD_SANTA, HEAD_FROST_DJINN, HEAD_REINDEER, HEAD_CROCODILE, HEAD_VALENTINE, HEAD_BUNNY, HEAD_GECKO, HEAD_BAT];
        private static var BODY_ARRAY:Array = [BODY_CLASSIC, BODY_STRAP, BODY_DRESS, BODY_PEC, BODY_GUT, BODY_COLLAR, BODY_MISS_PR2, BODY_BELT, BODY_SNAKE, BODY_BIRD, BODY_INVISIBLE, BODY_BEE, BODY_STICK, BODY_CAT, BODY_CAR, BODY_ELEPHANT, BODY_ANT, BODY_ASTRONAUT, BODY_ALIEN, BODY_GALAXY, BODY_BUBBLE, BODY_DINO, BODY_ARMOR, BODY_FAIRY, BODY_GINGERBREAD, BODY_KING, BODY_QUEEN, BODY_SIR, /*BODY_FRED, BODY_VERY_INVISIBLE,*/ BODY_TACO, BODY_SLENDER, BODY_SANTA, BODY_FROST_DJINN, BODY_REINDEER, BODY_CROCODILE, BODY_VALENTINE, BODY_BUNNY, BODY_GECKO, BODY_BAT];
        private static var FEET_ARRAY:Array = [FEET_CLASSIC, FEET_HEEL, FEET_LOAFER, FEET_CLEAT, FEET_MAGNET, FEET_TINY, FEET_SANDAL, FEET_BARE, FEET_NICE, FEET_BIRD, FEET_INVISIBLE, FEET_STICK, FEET_CAT, FEET_TIRE, FEET_ELEPHANT, FEET_ANT, FEET_ASTRONAUT, FEET_ALIEN, FEET_GALAXY, FEET_DINO, FEET_ARMOR, FEET_FAIRY, FEET_GINGERBREAD, FEET_KING, FEET_QUEEN, FEET_SIR, /*FEET_VERY_INVISIBLE,*/ FEET_BUBBLE, FEET_TACO, FEET_SLENDER, FEET_SANTA, FEET_FROST_DJINN, FEET_REINDEER, FEET_CROCODILE, FEET_VALENTINE, FEET_BUNNY, FEET_GECKO, FEET_BAT];

        public static var HAT_NAMES_ARRAY:Array = ['', 'EXP', 'Kongregate', 'Propeller', 'Cowboy', 'Crown', 'Santa', 'Party', 'Top', 'Jump Start', 'Moon', 'Thief', 'Jigg', 'Artifact'];
        public static var HEAD_NAMES_ARRAY:Array = ['Classic', 'Tired', 'Smiling', 'Flower', 'Lady', 'Goof', 'Downer', 'Balloon', 'Worm', 'Unicorn', 'Giant Bird', 'Cool Sun', 'Candy', 'Invisible', 'Helmet', 'Basketball', 'Stick', 'Cat', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Bubble', 'Wise King', 'Wise Queen', 'Sir', 'Very Invisible', 'Taco', 'Slender', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat'];
        public static var BODY_NAMES_ARRAY:Array = ['Classic', 'Strap', 'Dress', 'Pec', 'Gut', 'Collar', 'Miss PR2', 'Belt', 'Snake', 'Giant Bird', 'Invisible', 'Bee', 'Stick', 'Cat', 'Car', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Galaxy', 'Bubble', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Wise King', 'Wise Queen', 'Sir', 'Fred', 'Very Invisible', 'Taco', 'Slender', '', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat'];
        public static var FEET_NAMES_ARRAY:Array = ['Classic', 'Heel', 'Loafer', 'Cleat', 'Magnet', 'Tiny', 'Sandal', 'Bare', 'Nice', 'Giant Bird', 'Invisible', 'Stick', 'Cat', 'Tire', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Galaxy', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Wise King', 'Wise Queen', 'Sir', 'Very Invisible', 'Bubble', 'Taco', 'Slender', '', '', '', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat'];


        // handle type
        public static function validateType(type:String)
        {
            type = type.toUpperCase();
            if (type != 'HAT' && type != 'HEAD' && type != 'BODY' && type != 'FEET' && type != 'EHAT' && type != 'EHEAD' && type != 'EBODY' && type != 'EFEET') {
                return false;
            } else {
                if (type.charAt(0) == 'E') {
                    type = type.substr(1);
                }
                return type;
            }
        }


        // validate id
        private static function verifyPart(type:String, id:int)
        {
            type = Parts.validateType(type);
            if (id < 1 || id > Parts.GREATEST_ID || (type == 'BODY' && id === 33) || (type == 'FEET' && id > 30 && id < 34)) {
                return false;
            } else {
                return type + '_' + Parts['VARS_' + type][id - 1];
            }
        }


        // get object from part type/id request
        private static function makePart(type:String, id:int) : Object
        {
            type = Parts.validateType(type);
            var partVar:* = Parts.verifyPart(type, id);
            if (type != false && partVar != false) {
                var part:Object = new Object();
                part.type = type;
                part.id = id;
                part.name = Parts.getName(type, id);
                part.desc = Parts.getDesc(type, id);
            }
            return part;
        }


        // make part array
        public static function makeParts()
        {
            for each (var type:String in Parts.TYPES) {
                for each (var id:int in Parts[type + '_ARRAY']) {
                    var arrPos:int = Parts[type + '_ARRAY'].indexOf(id);
                    var part:Object = Parts.makePart(type, id);
                    Parts[type + '_ARRAY'][arrPos] = part;
                }
            }
            Parts.init = true;
        }


        // get part array
        public static function getPartArray(type:String)
        {
            type = Parts.validateType(type);
            if (type == false) {
                return false;
            }
            return Parts[type + '_ARRAY'];
        }


        // get only part name (without type)
        public static function getName(type:String, id:int) : String
        {
            type = Parts.validateType(type);
			var arr:Array;
            if (type == 'HAT') {
				arr = Parts.HAT_NAMES_ARRAY;
            } else if (type == 'HEAD') {
                arr = Parts.HEAD_NAMES_ARRAY;
            } else if (type == 'BODY') {
                arr = Parts.BODY_NAMES_ARRAY;
            } else if (type == 'FEET') {
                arr = Parts.FEET_NAMES_ARRAY;
            } else {
                return '';
            }

            return arr[id - 1];
        }


        // get full part description
        public static function getDesc(type:String, id:int) : String
        {
            var partVar:* = Parts.verifyPart(type, id);
            if (partVar != false) {
                return Parts['DESC_' + partVar];
            }
        }


        // get plural version of the type
        public static function getPlural(type:String) : String
        {
            type = Parts.validateType(type);
            if (type == 'HAT' || type == 'HEAD') {
                return type + 'S';
            } else if (type == 'BODY') {
                return 'BODIES';
            }
            return type;
        }

    }

}