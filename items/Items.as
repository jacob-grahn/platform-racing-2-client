// items.Items

package items
{
    //import __AS3__.vec.Vector;
    import package_8.LocalCharacter;
    import items.*;

    public class Items 
    {

        public static const laserGun:int = 1; // const_44
        public static const mine:int = 2; // const_34
        public static const lightning:int = 3; // const_49
        public static const teleport:int = 4; // const_35
        public static const superJump:int = 5; // const_7
        public static const jetPack:int = 6; // const_45
        public static const speedBurst:int = 7; // const_9
        public static const sword:int = 8; // const_48
        public static const iceWave:int = 9; // const_40


        public static function method_188():Vector.<int>
        {
            return new <int>[laserGun, mine, lightning, teleport, superJump, jetPack, speedBurst, sword, iceWave];
        }

        // method_29 = getFromCode
        public static function getFromCode(code:int, c:LocalCharacter):Item
        {
            if (code == laserGun) {
                return new LaserGun(c);
            } else if (code == mine) {
                return new Mine(c);
            } else if (code == lightning) {
                return new Lightning(c);
            } else if (code == teleport) {
                return new Teleport(c);
            } else if (code == superJump) {
                return new SuperJump(c);
            } else if (code == jetPack) {
                return new JetPack(c);
            } else if (code == speedBurst) {
                return new SpeedBurst(c);
            } else if (code == sword) {
                return new Sword(c);
            } else if (code == iceWave) {
                return new IceWave(c);
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

        // method_330 = getNameFromCode
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

        // method_657 = getCodeFromName
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
