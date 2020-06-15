// package_6.Modes = package_6.class_93

package package_6
{
    public class Modes 
    {

        public static var egg:String = "egg"; // var_345
        public static var dm:String = "deathmatch"; // var_456
        public static var race:String = "race"; // var_558
        public static var obj:String = "objective"; // var_383

        public static function getFullName(str:String)
        {
            if (str == 'e' || str == 'eggs' || str == Modes.egg) {
                return 'Alien Eggs';
            } else if (str == 'd' || str == 'dm' || str == Modes.dm) {
                return 'Deathmatch';
            } else if (str == 'o' || str == 'obj' || str == Modes.obj) {
                return 'Objective';
            } else {
                return 'Race';
            }
        }
    }
}
