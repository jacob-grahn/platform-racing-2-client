// gameplay.Modes = gameplay.class_93

package gameplay
{
    public class Modes 
    {

        public static var egg:String = "egg";
        public static var dm:String = "deathmatch";
        public static var race:String = "race";
        public static var obj:String = "objective";
        public static var hat:String = "hat";

        public static function getFullName(str:String)
        {
            if (str == 'e' || str == 'eggs' || str == Modes.egg) {
                return 'Alien Eggs';
            } else if (str == 'd' || str == 'dm' || str == Modes.dm) {
                return 'Deathmatch';
            } else if (str == 'o' || str == 'obj' || str == Modes.obj) {
                return 'Objective';
            } else if (str == 'h' || str == Modes.hat) {
                return 'Hat Attack';
            } else {
                return 'Race';
            }
        }
    }
}
