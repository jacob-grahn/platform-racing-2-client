// menu.CommAuth

package menu
{
    import com.jiggmin.data.SecureStore;

    public class CommAuth 
    {

        private static var hashing:SecureStore = new SecureStore(); // var_4


        public static function init()
        {
            hashing.initEncryptor("1", Env.COMM_PASS);
            hashing.initEncryptor("10", "ayo3JnBGQCZVRiEhVjFAQA==");
        }

        // _loc2 = str
        public static function getToken(num:int):String
        {
            var str:String = "1";
            if (num === 10) {
                str = "10";
            }
            return hashing.getString(str);
        }


    }
}

