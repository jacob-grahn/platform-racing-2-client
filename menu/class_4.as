// menu.class_4

package menu
{
    import data.class_20;

    public class class_4 
    {

        private static var hashing:class_20 = new class_20(); // var_4


        public static function init()
        {
            hashing.initEncryptor("1", Env.COMM_PASS);
            hashing.initEncryptor("10", "ayo3JnBGQCZVRiEhVjFAQA==");
        }

        // _loc2 = str
        public static function method_310(num:int):String
        {
            var str:String = "1";
            if (num === 10) {
                str = "10";
            }
            return hashing.getString(str);
        }


    }
}//package menu

