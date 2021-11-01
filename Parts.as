package
{
    import com.jiggmin.data.Data;

    public class Parts
    {

        // general
        private static var init:Boolean = false;
        private static const GREATEST_ID:int = 50;
        private static const TYPES:Array = ['HAT', 'HEAD', 'BODY', 'FEET'];

        // hats
        private static const VARS_HAT:Array = ['NONE', 'EXP', 'KONG', 'PROP', 'COWBOY', 'CROWN', 'SANTA', 'PARTY', 'TOP', 'JUMP_START', 'MOON', 'THIEF', 'JIGG', 'ARTIFACT', 'JELLYFISH', 'CHEESE'];
        public static const HAT_NONE:int = 1;
        public static const HAT_EXP:int = 2;
        public static const HAT_KONG:int = 3;
        public static const HAT_PROP:int = 4;
        public static const HAT_COWBOY:int = 5;
        public static const HAT_CROWN:int = 6;
        public static const HAT_SANTA:int = 7;
        public static const HAT_PARTY:int = 8;
        public static const HAT_TOP:int = 9;
        public static const HAT_JUMP_START:int = 10;
        public static const HAT_MOON:int = 11;
        public static const HAT_THIEF:int = 12;
        public static const HAT_JIGG:int = 13;
        public static const HAT_ARTIFACT:int = 14;
        public static const HAT_JELLYFISH:int = 15;
        public static const HAT_CHEESE:int = 16;

        // heads
        private static const VARS_HEAD:Array = ['CLASSIC', 'TIRED', 'SMILER', 'FLOWER', 'CLASSIC_GIRL', 'GOOF', 'DOWNER', 'BALLOON', 'WORM', 'UNICORN', 'BIRD', 'SUN', 'CANDY', 'INVISIBLE', 'FOOTBALL_HELMET', 'BASKETBALL', 'STICK', 'CAT', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'BUBBLE', 'KING', 'QUEEN', 'SIR', 'VERY_INVISIBLE', 'TACO', 'SLENDER', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT', 'SEA', 'BREW', 'JACKOLANTERN', 'XMAS', 'SNOWMAN', 'BLOBFISH', 'TURKEY', 'DOG', 'GLADIATOR'];
        public static const HEAD_CLASSIC:int = 1;
        public static const HEAD_TIRED:int = 2;
        public static const HEAD_SMILER:int = 3;
        public static const HEAD_FLOWER:int = 4;
        public static const HEAD_CLASSIC_GIRL:int = 5;
        public static const HEAD_GOOF:int = 6;
        public static const HEAD_DOWNER:int = 7;
        public static const HEAD_BALLOON:int = 8;
        public static const HEAD_WORM:int = 9;
        public static const HEAD_UNICORN:int = 10;
        public static const HEAD_BIRD:int = 11;
        public static const HEAD_SUN:int = 12;
        public static const HEAD_CANDY:int = 13;
        public static const HEAD_INVISIBLE:int = 14;
        public static const HEAD_FOOTBALL_HELMET:int = 15;
        public static const HEAD_BASKETBALL:int = 16;
        public static const HEAD_STICK:int = 17;
        public static const HEAD_CAT:int = 18;
        public static const HEAD_ELEPHANT:int = 19;
        public static const HEAD_ANT:int = 20;
        public static const HEAD_ASTRONAUT:int = 21;
        public static const HEAD_ALIEN:int = 22;
        public static const HEAD_DINO:int = 23;
        public static const HEAD_ARMOR:int = 24;
        public static const HEAD_FAIRY:int = 25;
        public static const HEAD_GINGERBREAD:int = 26;
        public static const HEAD_BUBBLE:int = 27;
        public static const HEAD_KING:int = 28;
        public static const HEAD_QUEEN:int = 29;
        public static const HEAD_SIR:int = 30;
        public static const HEAD_VERY_INVISIBLE:int = 31;
        public static const HEAD_TACO:int = 32;
        public static const HEAD_SLENDER:int = 33;
        public static const HEAD_SANTA:int = 34;
        public static const HEAD_FROST_DJINN:int = 35;
        public static const HEAD_REINDEER:int = 36;
        public static const HEAD_CROCODILE:int = 37;
        public static const HEAD_VALENTINE:int = 38;
        public static const HEAD_BUNNY:int = 39;
        public static const HEAD_GECKO:int = 40;
        public static const HEAD_BAT:int = 41;
        public static const HEAD_SEA:int = 42;
        public static const HEAD_BREW:int = 43;
        public static const HEAD_JACKOLANTERN:int = 44;
        public static const HEAD_XMAS:int = 45;
        public static const HEAD_SNOWMAN:int = 46;
        public static const HEAD_BLOBFISH:int = 47;
        public static const HEAD_TURKEY:int = 48;
        public static const HEAD_DOG:int = 49;
        public static const HEAD_GLADIATOR:int = 50;

        // bodies
        private static const VARS_BODY:Array = ['CLASSIC', 'STRAP', 'DRESS', 'PEC', 'GUT', 'COLLAR', 'MISS_PR2', 'BELT', 'SNAKE', 'BIRD', 'INVISIBLE', 'BEE', 'STICK', 'CAT', 'CAR', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'GALAXY', 'BUBBLE', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'KING', 'QUEEN', 'SIR', 'FRED', 'VERY_INVISIBLE', 'TACO', 'SLENDER', '', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT', 'SEA', 'BREW', '', 'XMAS', 'SNOWMAN', '', 'TURKEY', 'DOG', 'GLADIATOR'];
        public static const BODY_CLASSIC:int = 1;
        public static const BODY_STRAP:int = 2;
        public static const BODY_DRESS:int = 3;
        public static const BODY_PEC:int = 4;
        public static const BODY_GUT:int = 5;
        public static const BODY_COLLAR:int = 6;
        public static const BODY_MISS_PR2:int = 7;
        public static const BODY_BELT:int = 8;
        public static const BODY_SNAKE:int = 9;
        public static const BODY_BIRD:int = 10;
        public static const BODY_INVISIBLE:int = 11;
        public static const BODY_BEE:int = 12;
        public static const BODY_STICK:int = 13;
        public static const BODY_CAT:int = 14;
        public static const BODY_CAR:int = 15;
        public static const BODY_ELEPHANT:int = 16; // bean
        public static const BODY_ANT:int = 17;
        public static const BODY_ASTRONAUT:int = 18;
        public static const BODY_ALIEN:int = 19;
        public static const BODY_GALAXY:int = 20;
        public static const BODY_BUBBLE:int = 21;
        public static const BODY_DINO:int = 22;
        public static const BODY_ARMOR:int = 23;
        public static const BODY_FAIRY:int = 24;
        public static const BODY_GINGERBREAD:int = 25;
        public static const BODY_KING:int = 26;
        public static const BODY_QUEEN:int = 27;
        public static const BODY_SIR:int = 28;
        public static const BODY_FRED:int = 29;
        public static const BODY_VERY_INVISIBLE:int = 30;
        public static const BODY_TACO:int = 31;
        public static const BODY_SLENDER:int = 32;
        public static const BODY_SANTA:int = 34;
        public static const BODY_FROST_DJINN:int = 35;
        public static const BODY_REINDEER:int = 36;
        public static const BODY_CROCODILE:int = 37;
        public static const BODY_VALENTINE:int = 38;
        public static const BODY_BUNNY:int = 39;
        public static const BODY_GECKO:int = 40;
        public static const BODY_BAT:int = 41;
        public static const BODY_SEA:int = 42;
        public static const BODY_BREW:int = 43;
        public static const BODY_XMAS:int = 45;
        public static const BODY_SNOWMAN:int = 46;
        public static const BODY_TURKEY:int = 48;
        public static const BODY_DOG:int = 49;
        public static const BODY_GLADIATOR:int = 50;

        // feet
        private static const VARS_FEET:Array = ['CLASSIC', 'HEEL', 'LOAFER', 'CLEAT', 'MAGNET', 'TINY', 'SANDAL', 'BARE', 'NICE', 'BIRD', 'INVISIBLE', 'STICK', 'CAT', 'TIRE', 'ELEPHANT', 'ANT', 'ASTRONAUT', 'ALIEN', 'GALAXY', 'DINO', 'ARMOR', 'FAIRY', 'GINGERBREAD', 'KING', 'QUEEN', 'SIR', 'VERY_INVISIBLE', 'BUBBLE', 'TACO', 'SLENDER', '', '', '', 'SANTA', 'FROST_DJINN', 'REINDEER', 'CROCODILE', 'VALENTINE', 'BUNNY', 'GECKO', 'BAT', 'SEA', 'BREW', '', 'XMAS', 'SNOWMAN', '', 'TURKEY', 'DOG', 'GLADIATOR'];
        public static const FEET_CLASSIC:int = 1;
        public static const FEET_HEEL:int = 2;
        public static const FEET_LOAFER:int = 3;
        public static const FEET_CLEAT:int = 4;
        public static const FEET_MAGNET:int = 5;
        public static const FEET_TINY:int = 6;
        public static const FEET_SANDAL:int = 7;
        public static const FEET_BARE:int = 8;
        public static const FEET_NICE:int = 9;
        public static const FEET_BIRD:int = 10;
        public static const FEET_INVISIBLE:int = 11;
        public static const FEET_STICK:int = 12;
        public static const FEET_CAT:int = 13;
        public static const FEET_TIRE:int = 14;
        public static const FEET_ELEPHANT:int = 15;
        public static const FEET_ANT:int = 16;
        public static const FEET_ASTRONAUT:int = 17;
        public static const FEET_ALIEN:int = 18;
        public static const FEET_GALAXY:int = 19;
        public static const FEET_DINO:int = 20;
        public static const FEET_ARMOR:int = 21;
        public static const FEET_FAIRY:int = 22;
        public static const FEET_GINGERBREAD:int = 23;
        public static const FEET_KING:int = 24;
        public static const FEET_QUEEN:int = 25;
        public static const FEET_SIR:int = 26;
        public static const FEET_VERY_INVISIBLE:int = 27;
        public static const FEET_BUBBLE:int = 28;
        public static const FEET_TACO:int = 29;
        public static const FEET_SLENDER:int = 30;
        public static const FEET_SANTA:int = 34;
        public static const FEET_FROST_DJINN:int = 35;
        public static const FEET_REINDEER:int = 36;
        public static const FEET_CROCODILE:int = 37;
        public static const FEET_VALENTINE:int = 38;
        public static const FEET_BUNNY:int = 39;
        public static const FEET_GECKO:int = 40;
        public static const FEET_BAT:int = 41;
        public static const FEET_SEA:int = 42;
        public static const FEET_BREW:int = 43;
        public static const FEET_XMAS:int = 45;
        public static const FEET_SNOWMAN:int = 46;
        public static const FEET_TURKEY:int = 48;
        public static const FEET_DOG:int = 49;
        public static const FEET_GLADIATOR:int = 50;

        // sets
        public static const SET_CLASSIC:Array = [HEAD_CLASSIC, BODY_CLASSIC, FEET_CLASSIC];
        public static const SET_BIRD:Array = [HEAD_BIRD, BODY_BIRD, FEET_BIRD];
        public static const SET_INVISIBLE:Array = [HEAD_INVISIBLE, BODY_INVISIBLE, FEET_INVISIBLE];
        public static const SET_STICK:Array = [HEAD_STICK, BODY_STICK, FEET_STICK];
        public static const SET_CAT:Array = [HEAD_CAT, BODY_CAT, FEET_CAT];
        public static const SET_ELEPHANT:Array = [HEAD_ELEPHANT, BODY_ELEPHANT, FEET_ELEPHANT];
        public static const SET_ANT:Array = [HEAD_ANT, BODY_ANT, FEET_ANT];
        public static const SET_ASTRONAUT:Array = [HEAD_ASTRONAUT, BODY_ASTRONAUT, FEET_ASTRONAUT];
        public static const SET_ALIEN:Array = [HEAD_ALIEN, BODY_ALIEN, FEET_ALIEN];
        public static const SET_DINO:Array = [HEAD_DINO, BODY_DINO, FEET_DINO];
        public static const SET_ARMOR:Array = [HEAD_ARMOR, BODY_ARMOR, FEET_ARMOR];
        public static const SET_FAIRY:Array = [HEAD_FAIRY, BODY_FAIRY, FEET_FAIRY];
        public static const SET_GINGERBREAD:Array = [HEAD_GINGERBREAD, BODY_GINGERBREAD, FEET_GINGERBREAD];
        public static const SET_BUBBLE:Array = [HEAD_BUBBLE, BODY_BUBBLE, FEET_BUBBLE];
        public static const SET_KING:Array = [HEAD_KING, BODY_KING, FEET_KING];
        public static const SET_QUEEN:Array = [HEAD_QUEEN, BODY_QUEEN, FEET_QUEEN];
        public static const SET_SIR:Array = [HEAD_SIR, BODY_SIR, FEET_SIR];
        public static const SET_VERY_INVISIBLE:Array = [HEAD_VERY_INVISIBLE, BODY_VERY_INVISIBLE, FEET_VERY_INVISIBLE];
        public static const SET_TACO:Array = [HEAD_TACO, BODY_TACO, FEET_TACO];
        public static const SET_SLENDER:Array = [HEAD_SLENDER, BODY_SLENDER, FEET_SLENDER];
        public static const SET_SANTA:Array = [HEAD_SANTA, BODY_SANTA, FEET_SANTA];
        public static const SET_FROST_DJINN:Array = [HEAD_FROST_DJINN, BODY_FROST_DJINN, FEET_FROST_DJINN];
        public static const SET_REINDEER:Array = [HEAD_REINDEER, BODY_REINDEER, FEET_REINDEER];
        public static const SET_CROCODILE:Array = [HEAD_CROCODILE, BODY_CROCODILE, FEET_CROCODILE];
        public static const SET_VALENTINE:Array = [HEAD_VALENTINE, BODY_VALENTINE, FEET_VALENTINE];
        public static const SET_BUNNY:Array = [HEAD_BUNNY, BODY_BUNNY, FEET_BUNNY];
        public static const SET_GECKO:Array = [HEAD_GECKO, BODY_GECKO, FEET_GECKO];
        public static const SET_BAT:Array = [HEAD_BAT, BODY_BAT, FEET_BAT];
        public static const SET_SEA:Array = [HEAD_SEA, BODY_SEA, FEET_SEA];
        public static const SET_BREW:Array = [HEAD_BREW, BODY_BREW, FEET_BREW];
        public static const SET_XMAS:Array = [HEAD_XMAS, BODY_XMAS, FEET_XMAS];
        public static const SET_SNOWMAN:Array = [HEAD_SNOWMAN, BODY_SNOWMAN, FEET_SNOWMAN];
        public static const SET_TURKEY:Array = [HEAD_TURKEY, BODY_TURKEY, FEET_TURKEY];
        public static const SET_DOG:Array = [HEAD_DOG, BODY_DOG, FEET_DOG];
        public static const SET_GLADIATOR:Array = [HEAD_GLADIATOR, BODY_GLADIATOR, FEET_GLADIATOR];

        // descriptions
        public static const DESC_HAT_EXP:String = 'If you finish a race with this hat, it will increase your EXP gain by 100%!';
        public static const DESC_HAT_KONG:String = 'If you finish a race with this hat, it will increase your GP gain by 100%!';
        public static const DESC_HAT_PROP:String = 'Hold up while wearing this hat to float!';
        public static const DESC_HAT_COWBOY:String = 'Fly, cowboy, fly!';
        public static const DESC_HAT_CROWN:String = 'Wear this hat to become immune to mines, laser guns, and swords!';
        public static const DESC_HAT_SANTA:String = 'Briefly freezes the blocks you stand on!';
        public static const DESC_HAT_PARTY:String = 'Wear this hat to become immune to lightning!';
        public static const DESC_HAT_TOP:String = 'Stroll through vanish blocks with class!';
        public static const DESC_HAT_JUMP_START:String = 'Waiting is slow! Start racing right away.';
        public static const DESC_HAT_MOON:String = 'Soar to new heights by defying the laws of gravity!';
        public static const DESC_HAT_THIEF:String = 'Steal other player\'s hats --even crowns!';
        public static const DESC_HAT_JIGG:String = 'Bounce on the heads of your opponents!';
        public static const DESC_HAT_ARTIFACT:String = 'Leave your opponents in the dust for a glorious 30 seconds.';
        public static const DESC_HAT_JELLYFISH:String = 'Give nearby opponents a nasty sting!';
        public static const DESC_HAT_CHEESE:String = 'Turn crumble blocks into feta cheese --break through with record speed!';

        public static const DESC_HEAD_CLASSIC:String = 'Rock it old school.';
        public static const DESC_HEAD_TIRED:String = 'Did you stay up late playing PR2?';
        public static const DESC_HEAD_SMILER:String = 'Glad to be here!';
        public static const DESC_HEAD_FLOWER:String = 'Spring\'s finest flower.';
        public static const DESC_HEAD_CLASSIC_GIRL:String = 'Girls are way cooler.';
        public static const DESC_HEAD_GOOF:String = 'The funny one of the bunch.';
        public static const DESC_HEAD_DOWNER:String = 'Cheer up!';
        public static const DESC_HEAD_BALLOON:String = 'So happy you might float away!';
        public static const DESC_HEAD_WORM:String = 'Squiggly.';
        public static const DESC_HEAD_UNICORN:String = 'Pretty mythical, if you ask me.';
        public static const DESC_HEAD_BIRD:String = 'Squawk!';
        public static const DESC_HEAD_SUN:String = 'It\'s always a nice day with this head around.';
        public static const DESC_HEAD_CANDY:String = 'Pretty sweet, if you ask me.';
        public static const DESC_HEAD_INVISIBLE:String = 'Wow, where\'d you go?';
        public static const DESC_HEAD_FOOTBALL_HELMET:String = 'Hike!';
        public static const DESC_HEAD_BASKETBALL:String = 'He shoots, he scores!';
        public static const DESC_HEAD_STICK:String = 'Satisfy your inner doodler.';
        public static const DESC_HEAD_CAT:String = 'Meow!';
        public static const DESC_HEAD_ELEPHANT:String = 'Trumpet!';
        public static const DESC_HEAD_ANT:String = '...crawl?';
        public static const DESC_HEAD_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static const DESC_HEAD_ALIEN:String = 'You surely, maybe, definitely come in peace.';
        public static const DESC_HEAD_DINO:String = 'ROAR!';
        public static const DESC_HEAD_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static const DESC_HEAD_FAIRY:String = 'Pretty magical, if you ask me.';
        public static const DESC_HEAD_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static const DESC_HEAD_BUBBLE:String = 'Pop!';
        public static const DESC_HEAD_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static const DESC_HEAD_QUEEN:String = 'The real brains of the royal family.';
        public static const DESC_HEAD_SIR:String = 'Ever so fancy.';
        public static const DESC_HEAD_VERY_INVISIBLE:String = 'Okay, this time I really can\'t see you...';
        public static const DESC_HEAD_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static const DESC_HEAD_SLENDER:String = 'How many pages do I have?';
        public static const DESC_HEAD_SANTA:String = 'Ho ho ho!';
        public static const DESC_HEAD_FROST_DJINN:String = 'A higher being of great power.';
        public static const DESC_HEAD_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static const DESC_HEAD_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static const DESC_HEAD_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static const DESC_HEAD_BUNNY:String = 'No easter eggs here!';
        public static const DESC_HEAD_GECKO:String = '...slither?';
        public static const DESC_HEAD_BAT:String = '...echolocate?';
        public static const DESC_HEAD_SEA:String = 'We got the spirit, you got to hear it, under the sea!';
        public static const DESC_HEAD_BREW:String = 'Hydration is key.';
        public static const DESC_HEAD_JACKOLANTERN:String = 'Spook your friends!';
        public static const DESC_HEAD_XMAS:String = 'Twinkle twinkle...';
        public static const DESC_HEAD_SNOWMAN:String = 'Channel your inner frosty.';
        public static const DESC_HEAD_BLOBFISH:String = 'The world\'s most misunderstood fish.';
        public static const DESC_HEAD_TURKEY:String = 'Gobble, gobble!';
        public static const DESC_HEAD_DOG:String = 'WOOF BARK BORK';
        public static const DESC_HEAD_GLADIATOR:String = 'The toughest gladiator in all of Ancient Rome.';

        public static const DESC_BODY_CLASSIC:String = 'Rock it old school.';
        public static const DESC_BODY_STRAP:String = 'Strapping!';
        public static const DESC_BODY_DRESS:String = 'Very dressy.';
        public static const DESC_BODY_PEC:String = 'Do you even lift?';
        public static const DESC_BODY_GUT:String = 'Couch potato.';
        public static const DESC_BODY_COLLAR:String = 'Dracula would be proud.';
        public static const DESC_BODY_MISS_PR2:String = 'You won the pageant!';
        public static const DESC_BODY_BELT:String = 'How you keep your pants up, especially when performing. It\'s incredible.';
        public static const DESC_BODY_SNAKE:String = 'Ssssssquiggly.';
        public static const DESC_BODY_BIRD:String = 'Squawk!';
        public static const DESC_BODY_INVISIBLE:String = 'Wow, where\'d you go?';
        public static const DESC_BODY_BEE:String = 'Bzzzzzz!';
        public static const DESC_BODY_STICK:String = 'Satisfy your inner doodler.';
        public static const DESC_BODY_CAT:String = 'Meow!';
        public static const DESC_BODY_CAR:String = 'Vroom vroom! Beep beep!';
        public static const DESC_BODY_ELEPHANT:String = 'Trumpet!'; // bean
        public static const DESC_BODY_ANT:String = '...crawl?';
        public static const DESC_BODY_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static const DESC_BODY_ALIEN:String = 'You surely, maybe, <i>definitely</i> come in peace.';
        public static const DESC_BODY_GALAXY:String = 'The power of the cosmos, at your disposal.';
        public static const DESC_BODY_BUBBLE:String = 'Pop!';
        public static const DESC_BODY_DINO:String = 'ROAR!';
        public static const DESC_BODY_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static const DESC_BODY_FAIRY:String = 'Pretty magical, if you ask me.';
        public static const DESC_BODY_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static const DESC_BODY_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static const DESC_BODY_QUEEN:String = 'The real brains of the royal family.';
        public static const DESC_BODY_SIR:String = 'Ever so fancy.';
        public static const DESC_BODY_FRED:String = 'Hi, I\'m Fred the Giant Cactus. I\'ll be seeng you around!';
        public static const DESC_BODY_VERY_INVISIBLE:String = 'Okay, this time I <i>really</i> can\'t see you...';
        public static const DESC_BODY_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static const DESC_BODY_SLENDER:String = 'How many pages do I have?';
        public static const DESC_BODY_SANTA:String = 'Ho ho ho!';
        public static const DESC_BODY_FROST_DJINN:String = 'A higher being of great power.';
        public static const DESC_BODY_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static const DESC_BODY_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static const DESC_BODY_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static const DESC_BODY_BUNNY:String = 'No easter eggs here!';
        public static const DESC_BODY_GECKO:String = '...slither?';
        public static const DESC_BODY_BAT:String = '...echolocate?';
        public static const DESC_BODY_SEA:String = 'We got the spirit, you got to hear it, under the sea!';
        public static const DESC_BODY_BREW:String = 'Hydration is key.';
        public static const DESC_BODY_XMAS:String = 'Oh Christmas tree, oh Christmas tree...';
        public static const DESC_BODY_SNOWMAN:String = 'Channel your inner frosty.';
        public static const DESC_BODY_TURKEY:String = 'Gobble, gobble!';
        public static const DESC_BODY_DOG:String = 'WOOF BARK BORK';
        public static const DESC_BODY_GLADIATOR:String = 'The toughest gladiator in all of Ancient Rome.';

        public static const DESC_FEET_CLASSIC:String = 'Rock it old school.';
        public static const DESC_FEET_HEEL:String = 'Very dressy.';
        public static const DESC_FEET_LOAFER:String = 'It\'s casual.';
        public static const DESC_FEET_CLEAT:String = 'Put me in coach; I\'m ready to play!';
        public static const DESC_FEET_MAGNET:String = 'Opposites attract.';
        public static const DESC_FEET_TINY:String = 'If you blink, you might miss them.';
        public static const DESC_FEET_SANDAL:String = 'These might go well with some pajamas.';
        public static const DESC_FEET_BARE:String = 'Back to basics.';
        public static const DESC_FEET_NICE:String = 'So nice.';
        public static const DESC_FEET_BIRD:String = 'Squawk!';
        public static const DESC_FEET_INVISIBLE:String = 'Wow, where\'d you go?';
        public static const DESC_FEET_STICK:String = 'Satisfy your inner doodler.';
        public static const DESC_FEET_CAT:String = 'Meow!';
        public static const DESC_FEET_TIRE:String = 'Vroom vroom! Beep beep!';
        public static const DESC_FEET_ELEPHANT:String = 'Trumpet!';
        public static const DESC_FEET_ANT:String = '...crawl?';
        public static const DESC_FEET_ASTRONAUT:String = 'That\'s one small step for man... one giant leap for mankind.';
        public static const DESC_FEET_ALIEN:String = 'You surely, maybe, <i>definitely</i> come in peace.';
        public static const DESC_FEET_GALAXY:String = 'The power of the cosmos, at your disposal.';
        public static const DESC_FEET_DINO:String = 'ROAR!';
        public static const DESC_FEET_ARMOR:String = 'Disclaimer: This won\'t make you a knight.';
        public static const DESC_FEET_FAIRY:String = 'Pretty magical, if you ask me.';
        public static const DESC_FEET_GINGERBREAD:String = 'Pretty tasty, if you ask me.';
        public static const DESC_FEET_KING:String = 'The most benevolent monarch PR2 has ever seen.';
        public static const DESC_FEET_QUEEN:String = 'The real brains of the royal family.';
        public static const DESC_FEET_SIR:String = 'Ever so fancy.';
        public static const DESC_FEET_VERY_INVISIBLE:String = 'Okay, this time I <i>really</i> can\'t see you...';
        public static const DESC_FEET_BUBBLE:String = 'Pop!';
        public static const DESC_FEET_TACO:String = 'It doesn\'t even have to be a Tuesday!';
        public static const DESC_FEET_SLENDER:String = 'How many pages do I have?';
        public static const DESC_FEET_SANTA:String = 'Ho ho ho!';
        public static const DESC_FEET_FROST_DJINN:String = 'A higher being of great power.';
        public static const DESC_FEET_REINDEER:String = 'Rudolph has been dethroned as the most famous reindeer of all.';
        public static const DESC_FEET_CROCODILE:String = 'Your opponents had better run in a zig-zag pattern to escape you!';
        public static const DESC_FEET_VALENTINE:String = '\"Ahhh! Girls have cooties!! And it\'s Valentine\'s Day!!!\"';
        public static const DESC_FEET_BUNNY:String = 'No easter eggs here!';
        public static const DESC_FEET_GECKO:String = '...slither?';
        public static const DESC_FEET_BAT:String = '...echolocate?';
        public static const DESC_FEET_SEA:String = 'We got the spirit, you got to hear it, under the sea!';
        public static const DESC_FEET_BREW:String = 'Hydration is key.';
        public static const DESC_FEET_XMAS:String = 'Presenting a present for you!';
        public static const DESC_FEET_SNOWMAN:String = 'Channel your inner frosty.';
        public static const DESC_FEET_TURKEY:String = 'Gobble, gobble!';
        public static const DESC_FEET_DOG:String = 'WOOF BARK BORK';
        public static const DESC_FEET_GLADIATOR:String = 'The toughest gladiator in all of Ancient Rome.';

        // how to obtain
        public static const OBTAIN_HAT_EXP:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HAT_KONG:String = 'Click the Kongregate button on the login page.';
        public static const OBTAIN_HAT_PROP:String = 'Finish Hat Factory by Jiggmin or Volcanic Inferno by Pounce.';
        public static const OBTAIN_HAT_COWBOY:String = 'Fold 100,000 points on Folding at Home. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=19" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HAT_CROWN:String = 'Fold 5,000 points on Folding at Home. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=19" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HAT_SANTA:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HAT_PARTY:String = 'Log into your PR2 account on New Year\'s Eve or Day. Also won randomly in races with 2-4 players.';
        public static const OBTAIN_HAT_TOP:String = 'Finish The Golden Compass by -Shadowfax-.';
        public static const OBTAIN_HAT_JUMP_START:String = 'Won randomly during a happy hour in races with 2-4 players.';
        public static const OBTAIN_HAT_MOON:String = 'Finish Redemption by cooldude90.';
        public static const OBTAIN_HAT_THIEF:String = 'Finish Apocalypse by Divinity.';
        public static const OBTAIN_HAT_JIGG:String = 'Finish Buto (EXACT) by ZePHiR after finding the hidden Jigg Hat.';
        public static const OBTAIN_HAT_ARTIFACT:String = 'This is a special part. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HAT_JELLYFISH:String = 'Finish Deeper by Sothal.';
        public static const OBTAIN_HAT_CHEESE:String = 'Finish Moon is made w/ cheese by ktosss450 after finding the hidden Cheese Hat.';

        public static const OBTAIN_HEAD_CLASSIC:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_TIRED:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_SMILER:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_FLOWER:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_CLASSIC_GIRL:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_GOOF:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_DOWNER:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_BALLOON:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_WORM:String = 'It\'s there when you create your account!';
        public static const OBTAIN_HEAD_UNICORN:String = 'Won in Campaign #1 Level #1 with 4 players.';
        public static const OBTAIN_HEAD_BIRD:String = 'Won in Campaign #1 Level #4 with 4 players.';
        public static const OBTAIN_HEAD_SUN:String = 'Won in Campaign #1 Level #2 with 4 players.';
        public static const OBTAIN_HEAD_CANDY:String = 'Won in Campaign #1 Level #7 with 4 players.';
        public static const OBTAIN_HEAD_INVISIBLE:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_FOOTBALL_HELMET:String = 'Won in Campaign #1 Level #3 with 4 players.';
        public static const OBTAIN_HEAD_BASKETBALL:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_STICK:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_CAT:String = 'Won in Campaign #2 Level #3 with 4 players.';
        public static const OBTAIN_HEAD_ELEPHANT:String = 'Won in Campaign #2 Level #6 with 4 players.';
        public static const OBTAIN_HEAD_ANT:String = 'Click the Kongregate button on the login page.';
        public static const OBTAIN_HEAD_ASTRONAUT:String = 'Won in Campaign #3 Level #1 with 4 players.';
        public static const OBTAIN_HEAD_ALIEN:String = 'Won in Campaign #3 Level #4 with 4 players.';
        public static const OBTAIN_HEAD_DINO:String = 'Won in Campaign #4 Level #3 with 4 players.';
        public static const OBTAIN_HEAD_ARMOR:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_FAIRY:String = 'Won in Campaign #4 Level #6 with 4 players.';
        public static const OBTAIN_HEAD_GINGERBREAD:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_BUBBLE:String = 'Find the artifact first. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_KING:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_HEAD_QUEEN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_HEAD_SIR:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_VERY_INVISIBLE:String = 'Cannot be obtained; rented in the Vault of Magics.';
        public static const OBTAIN_HEAD_TACO:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_HEAD_SLENDER:String = 'Has a 1 in 3 chance of appearing on -Deliverance- by changelings.';
        public static const OBTAIN_HEAD_SANTA:String = 'Log into your PR2 account on Christmas Eve or Day.';
        public static const OBTAIN_HEAD_FROST_DJINN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_HEAD_REINDEER:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_CROCODILE:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_VALENTINE:String = 'Log into your PR2 account on Valentine\'s Day.';
        public static const OBTAIN_HEAD_BUNNY:String = 'Log into your PR2 account during Easter Weekend.';
        public static const OBTAIN_HEAD_GECKO:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_BAT:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_SEA:String = 'Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.';
        public static const OBTAIN_HEAD_BREW:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_JACKOLANTERN:String = 'Log into your PR2 account on Halloween.';
        public static const OBTAIN_HEAD_XMAS:String = 'Won in Campaign #6 Level #3 during the holiday season.';
        public static const OBTAIN_HEAD_SNOWMAN:String = 'Won in Campaign #6 Level #6 during the holiday season.';
        public static const OBTAIN_HEAD_BLOBFISH:String = 'Finish Underwater World by Odin0030.';
        public static const OBTAIN_HEAD_TURKEY:String = 'Log into your PR2 account on Thanksgiving.';
        public static const OBTAIN_HEAD_DOG:String = 'Create a level that becomes Level of the Week. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=3509" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_HEAD_GLADIATOR:String = 'Finish Romªn Empire by Overbeing.';

        public static const OBTAIN_BODY_CLASSIC:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_STRAP:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_DRESS:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_PEC:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_GUT:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_COLLAR:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_MISS_PR2:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_BELT:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_SNAKE:String = 'It\'s there when you create your account!';
        public static const OBTAIN_BODY_BIRD:String = 'Won in Campaign #1 Level #5 with 4 players.';
        public static const OBTAIN_BODY_INVISIBLE:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_BODY_BEE:String = 'Won in Campaign #1 Level #8 with 4 players.';
        public static const OBTAIN_BODY_STICK:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_BODY_CAT:String = 'Won in Campaign #2 Level #2 with 4 players.';
        public static const OBTAIN_BODY_CAR:String = 'Won in Campaign #2 Level #8 with 4 players.';
        public static const OBTAIN_BODY_ELEPHANT:String = 'Won in Campaign #2 Level #5 with 4 players.'; // bean
        public static const OBTAIN_BODY_ANT:String = 'Click the Kongregate button on the login page.';
        public static const OBTAIN_BODY_ASTRONAUT:String = 'Won in Campaign #3 Level #2 with 4 players.';
        public static const OBTAIN_BODY_ALIEN:String = 'Won in Campaign #3 Level #5 with 4 players.';
        public static const OBTAIN_BODY_GALAXY:String = 'Won in Campaign #3 Level #7 with 4 players.';
        public static const OBTAIN_BODY_BUBBLE:String = 'Find the artifact first. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_DINO:String = 'Won in Campaign #4 Level #2 with 4 players.';
        public static const OBTAIN_BODY_ARMOR:String = 'Won in Campaign #4 Level #8 with 4 players.';
        public static const OBTAIN_BODY_FAIRY:String = 'Won in Campaign #4 Level #5 with 4 players.';
        public static const OBTAIN_BODY_GINGERBREAD:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_BODY_KING:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_BODY_QUEEN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_BODY_SIR:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_BODY_FRED:String = 'Cannot be obtained; rented in the Vault of Magics.';
        public static const OBTAIN_BODY_VERY_INVISIBLE:String = 'Cannot be obtained; rented in the Vault of Magics.';
        public static const OBTAIN_BODY_TACO:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_BODY_SLENDER:String = 'Has a 1 in 3 chance of appearing on -Deliverance- by changelings.';
        public static const OBTAIN_BODY_SANTA:String = 'Log into your PR2 account on Christmas Eve or Day.';
        public static const OBTAIN_BODY_FROST_DJINN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_BODY_REINDEER:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_CROCODILE:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_VALENTINE:String = 'Log into your PR2 account on Valentine\'s Day.';
        public static const OBTAIN_BODY_BUNNY:String = 'Log into your PR2 account during Easter Weekend.';
        public static const OBTAIN_BODY_GECKO:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_BAT:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_SEA:String = 'Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.';
        public static const OBTAIN_BODY_BREW:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_XMAS:String = 'Won in Campaign #6 Level #2 during the holiday season.';
        public static const OBTAIN_BODY_SNOWMAN:String = 'Won in Campaign #6 Level #5 during the holiday season.';
        public static const OBTAIN_BODY_TURKEY:String = 'Log into your PR2 account on Thanksgiving.';
        public static const OBTAIN_BODY_DOG:String = 'Create a level that becomes Level of the Week. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=3509" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_BODY_GLADIATOR:String = 'Finish Romªn Empire by Overbeing.';

        public static const OBTAIN_FEET_CLASSIC:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_HEEL:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_LOAFER:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_CLEAT:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_MAGNET:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_TINY:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_SANDAL:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_BARE:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_NICE:String = 'It\'s there when you create your account!';
        public static const OBTAIN_FEET_BIRD:String = 'Won in Campaign #1 Level #6 with 4 players.';
        public static const OBTAIN_FEET_INVISIBLE:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_FEET_STICK:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_FEET_CAT:String = 'Won in Campaign #2 Level #1 with 4 players.';
        public static const OBTAIN_FEET_TIRE:String = 'Won in Campaign #2 Level #7 with 4 players.';
        public static const OBTAIN_FEET_ELEPHANT:String = 'Won in Campaign #2 Level #4 with 4 players.';
        public static const OBTAIN_FEET_ANT:String = 'Click the Kongregate button on the login page.';
        public static const OBTAIN_FEET_ASTRONAUT:String = 'Won in Campaign #3 Level #3 with 4 players.';
        public static const OBTAIN_FEET_ALIEN:String = 'Won in Campaign #3 Level #6 with 4 players.';
        public static const OBTAIN_FEET_GALAXY:String = 'Won in Campaign #3 Level #8 with 4 players.';
        public static const OBTAIN_FEET_DINO:String = 'Won in Campaign #4 Level #1 with 4 players.';
        public static const OBTAIN_FEET_ARMOR:String = 'Won in Campaign #4 Level #7 with 4 players.';
        public static const OBTAIN_FEET_FAIRY:String = 'Won in Campaign #4 Level #4 with 4 players.';
        public static const OBTAIN_FEET_GINGERBREAD:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_FEET_KING:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_FEET_QUEEN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_FEET_SIR:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_FEET_VERY_INVISIBLE:String = 'Cannot be obtained; rented in the Vault of Magics.';
        public static const OBTAIN_FEET_BUBBLE:String = 'Find the artifact first. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=1677" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_TACO:String = 'Won randomly in races with 2-4 players.';
        public static const OBTAIN_FEET_SLENDER:String = 'Has a 1 in 3 chance of appearing on -Deliverance- by changelings.';
        public static const OBTAIN_FEET_SANTA:String = 'Log into your PR2 account on Christmas Eve or Day.';
        public static const OBTAIN_FEET_FROST_DJINN:String = 'Purchased in the Vault of Magics.';
        public static const OBTAIN_FEET_REINDEER:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_CROCODILE:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_VALENTINE:String = 'Log into your PR2 account on Valentine\'s Day.';
        public static const OBTAIN_FEET_BUNNY:String = 'Log into your PR2 account on Easter Weekend.';
        public static const OBTAIN_FEET_GECKO:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_BAT:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_SEA:String = 'Has a 1 in 3 chance of appearing on ~Under the sea~ by Rammjet.';
        public static const OBTAIN_FEET_BREW:String = 'Won in contests. <u><font color="#0000FF"><a href="' + Main.baseURL + '/contests" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_XMAS:String = 'Won in Campaign #6 Level #1 during the holiday season.';
        public static const OBTAIN_FEET_SNOWMAN:String = 'Won in Campaign #6 Level #4 during the holiday season.';
        public static const OBTAIN_FEET_TURKEY:String = 'Log into your PR2 account on Thanksgiving.';
        public static const OBTAIN_FEET_DOG:String = 'Create a level that becomes Level of the Week. <u><font color="#0000FF"><a href="https://jiggmin2.com/forums/showthread.php?tid=3509" target="_blank">Here\'s some more information!</a></font></u>';
        public static const OBTAIN_FEET_GLADIATOR:String = 'Finish Romªn Empire by Overbeing.';



        // arrays
        private static var HAT_ARRAY:Array = [HAT_EXP, HAT_KONG, HAT_PROP, HAT_COWBOY, HAT_CROWN, HAT_SANTA, HAT_PARTY, HAT_TOP, HAT_JUMP_START, HAT_MOON, HAT_THIEF, HAT_JIGG, HAT_ARTIFACT, HAT_JELLYFISH, HAT_CHEESE];
        private static var HEAD_ARRAY:Array = [HEAD_CLASSIC, HEAD_TIRED, HEAD_SMILER, HEAD_FLOWER, HEAD_CLASSIC_GIRL, HEAD_GOOF, HEAD_DOWNER, HEAD_BALLOON, HEAD_WORM, HEAD_UNICORN, HEAD_BIRD, HEAD_SUN, HEAD_CANDY, HEAD_INVISIBLE, HEAD_FOOTBALL_HELMET, HEAD_BASKETBALL, HEAD_STICK, HEAD_CAT, HEAD_ELEPHANT, HEAD_ANT, HEAD_ASTRONAUT, HEAD_ALIEN, HEAD_DINO, HEAD_ARMOR, HEAD_FAIRY, HEAD_GINGERBREAD, HEAD_BUBBLE, HEAD_KING, HEAD_QUEEN, HEAD_SIR, HEAD_VERY_INVISIBLE, HEAD_TACO, HEAD_SLENDER, HEAD_SANTA, HEAD_FROST_DJINN, HEAD_REINDEER, HEAD_CROCODILE, HEAD_VALENTINE, HEAD_BUNNY, HEAD_GECKO, HEAD_BAT, HEAD_SEA, HEAD_BREW, HEAD_JACKOLANTERN, HEAD_XMAS, HEAD_SNOWMAN, HEAD_BLOBFISH, HEAD_TURKEY, HEAD_DOG, HEAD_GLADIATOR];
        private static var BODY_ARRAY:Array = [BODY_CLASSIC, BODY_STRAP, BODY_DRESS, BODY_PEC, BODY_GUT, BODY_COLLAR, BODY_MISS_PR2, BODY_BELT, BODY_SNAKE, BODY_BIRD, BODY_INVISIBLE, BODY_BEE, BODY_STICK, BODY_CAT, BODY_CAR, BODY_ELEPHANT, BODY_ANT, BODY_ASTRONAUT, BODY_ALIEN, BODY_GALAXY, BODY_BUBBLE, BODY_DINO, BODY_ARMOR, BODY_FAIRY, BODY_GINGERBREAD, BODY_KING, BODY_QUEEN, BODY_SIR, BODY_FRED, BODY_VERY_INVISIBLE, BODY_TACO, BODY_SLENDER, BODY_SANTA, BODY_FROST_DJINN, BODY_REINDEER, BODY_CROCODILE, BODY_VALENTINE, BODY_BUNNY, BODY_GECKO, BODY_BAT, BODY_SEA, BODY_BREW, BODY_XMAS, BODY_SNOWMAN, BODY_TURKEY, BODY_DOG, BODY_GLADIATOR];
        private static var FEET_ARRAY:Array = [FEET_CLASSIC, FEET_HEEL, FEET_LOAFER, FEET_CLEAT, FEET_MAGNET, FEET_TINY, FEET_SANDAL, FEET_BARE, FEET_NICE, FEET_BIRD, FEET_INVISIBLE, FEET_STICK, FEET_CAT, FEET_TIRE, FEET_ELEPHANT, FEET_ANT, FEET_ASTRONAUT, FEET_ALIEN, FEET_GALAXY, FEET_DINO, FEET_ARMOR, FEET_FAIRY, FEET_GINGERBREAD, FEET_KING, FEET_QUEEN, FEET_SIR, FEET_VERY_INVISIBLE, FEET_BUBBLE, FEET_TACO, FEET_SLENDER, FEET_SANTA, FEET_FROST_DJINN, FEET_REINDEER, FEET_CROCODILE, FEET_VALENTINE, FEET_BUNNY, FEET_GECKO, FEET_BAT, FEET_SEA, FEET_BREW, FEET_XMAS, FEET_SNOWMAN, FEET_TURKEY, FEET_DOG, FEET_GLADIATOR];

        public static const HAT_NAMES_ARRAY:Array = ['', 'EXP', 'Kongregate', 'Propeller', 'Cowboy', 'Crown', 'Santa', 'Party', 'Top', 'Jump Start', 'Moon', 'Thief', 'Jigg', 'Artifact', 'Jellyfish', 'Cheese'];
        public static const HEAD_NAMES_ARRAY:Array = ['Classic', 'Tired', 'Smiling', 'Flower', 'Lady', 'Goof', 'Downer', 'Balloon', 'Worm', 'Unicorn', 'Giant Bird', 'Cool Sun', 'Candy', 'Invisible', 'Helmet', 'Basketball', 'Stick', 'Cat', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Bubble', 'Wise King', 'Wise Queen', 'Sir', 'Very Invisible', 'Taco', 'Slender', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat', 'Sea', 'Brew', 'Jack-o\'-Lantern', 'Star', 'Snowman', 'Blobfish', 'Turkey', 'Dog', 'Gladiator'];
        public static const BODY_NAMES_ARRAY:Array = ['Classic', 'Strap', 'Dress', 'Pec', 'Gut', 'Collar', 'Miss PR2', 'Belt', 'Snake', 'Giant Bird', 'Invisible', 'Bee', 'Stick', 'Cat', 'Car', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Galaxy', 'Bubble', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Wise King', 'Wise Queen', 'Sir', 'Fred', 'Very Invisible', 'Taco', 'Slender', '', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat', 'Sea', 'Brew', '', 'Christmas Tree', 'Snowman', '', 'Turkey', 'Dog', 'Gladiator'];
        public static const FEET_NAMES_ARRAY:Array = ['Classic', 'Heel', 'Loafer', 'Cleat', 'Magnet', 'Tiny', 'Sandal', 'Bare', 'Nice', 'Giant Bird', 'Invisible', 'Stick', 'Cat', 'Tire', 'Elephant', 'Ant', 'Astronaut', 'Alien', 'Galaxy', 'Dino', 'Armor', 'Fairy', 'Gingerbread', 'Wise King', 'Wise Queen', 'Sir', 'Very Invisible', 'Bubble', 'Taco', 'Slender', '', '', '', 'Santa', 'Frost Djinn', 'Reindeer', 'Crocodile', 'Valentine', 'Bunny', 'Gecko', 'Bat', 'Sea', 'Brew', '', 'Present', 'Snowman', '', 'Turkey', 'Dog', 'Gladiator'];


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
            if (
                id < 1 ||
                id > Parts.GREATEST_ID ||
                (type == 'HAT' && id > 16) ||
                (type == 'BODY' && id === 33) ||
                (type == 'FEET' && id > 30 && id < 34) ||
                ((type == 'BODY' || type == 'FEET') && (id == 44 || id == 47))
            ) {
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
                part.obtain = Parts.getObtain(type, id);
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


        // get information on how to obtain
        public static function getObtain(type:String, id:int) : String
        {
            var partVar:* = Parts.verifyPart(type, id);
            if (partVar != false) {
                return Parts['OBTAIN_' + partVar];
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