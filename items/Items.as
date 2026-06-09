// items.Items

package items
{
    //import __AS3__.vec.Vector;
    import character.LocalCharacter;
    import items.*;

    public class Items 
    {

        public static const laserGun:int = 1;
        public static const mine:int = 2;
        public static const lightning:int = 3;
        public static const teleport:int = 4;
        public static const superJump:int = 5;
        public static const jetPack:int = 6;
        public static const speedBurst:int = 7;
        public static const sword:int = 8;
        public static const iceWave:int = 9;


        public static function getAllCodes():Vector.<int>
        {
            return new <int>[laserGun, mine, lightning, teleport, superJump, jetPack, speedBurst, sword, iceWave];
        }

        public static function getFromCode(code:int, player:LocalCharacter):Item
        {
            if (code == laserGun) {
                return new LaserGun(player);
            } else if (code == mine) {
                return new Mine(player);
            } else if (code == lightning) {
                return new Lightning(player);
            } else if (code == teleport) {
                return new Teleport(player);
            } else if (code == superJump) {
                return new SuperJump(player);
            } else if (code == jetPack) {
                return new JetPack(player);
            } else if (code == speedBurst) {
                return new SpeedBurst(player);
            } else if (code == sword) {
                return new Sword(player);
            } else if (code == iceWave) {
                return new IceWave(player);
            } else {
                return null;
            }
        }

        public static function getCodeFromItem(item:Item):int
        {
            if (item is LaserGun) {
                return laserGun;
            } else if (item is Mine) {
                return mine;
            } else if (item is Lightning) {
                return lightning;
            } else if (item is Teleport) {
                return teleport;
            } else if (item is SuperJump) {
                return superJump;
            } else if (item is JetPack) {
                return jetPack;
            } else if (item is SpeedBurst) {
                return speedBurst;
            } else if (item is Sword) {
                return sword;
            } else if (item is IceWave) {
                return iceWave;
            } else {
                return 0;
            }
        }

        public static function getNameFromCode(code:int):String
        {
            if (code == laserGun) {
                return "Laser";
            } else if (code == mine) {
                return "Mine";
            } else if (code == lightning) {
                return "Lightning";
            } else if (code == teleport) {
                return "Teleport";
            } else if (code == superJump) {
                return "Super Jump";
            } else if (code == jetPack) {
                return "Jet Pack";
            } else if (code == speedBurst) {
                return "Speed Burst";
            } else if (code == sword) {
                return "Sword";
            } else if (code == iceWave) {
                return "Ice Wave";
            } else {
                return "None";
            }
        }

        public static function getCodeFromName(item:String):int
        {
            if (item == "Laser" || item == "Laser Gun") {
                return laserGun;
            } else if (item == "Mine") {
                return mine;
            } else if (item == "Lightning") {
                return lightning;
            } else if (item == "Teleport") {
                return teleport;
            } else if (item == "Super Jump") {
                return superJump;
            } else if (item == "Jet Pack") {
                return jetPack;
            } else if (item == "Speed Burst") {
                return speedBurst;
            } else if (item == "Sword") {
                return sword;
            } else if (item == "Ice Wave") {
                return iceWave;
            } else {
                return 0;
            }
        }


    }
}
