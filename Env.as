package
{

    public class Env
    {

        public static var COMM_PASS:String = 'QHE0NSNwKWZZQVEhU19xMA=='; // all socket communications

        public static var LOGIN_KEY:String = 'VUovam5GKndSMHFSSy9kSA=='; // encryptor key for login-related fns
        public static var LOGIN_IV:String = 'JmM5KnkqNXA9MVVOeC9Ucg=='; // encryptor iv for login-related fns

        public static var CHANGE_EMAIL_KEY:String = 'KVhFJSVLNigvKkdhV0RaSw=='; // encryptor key for email changes
        public static var CHANGE_EMAIL_IV:String = 'QEFUZCskMnhhdk8rYlFLKg=='; // encryptor iv for email changes

        public static var LEVEL_LIST_SALT:String = '984cn98c54$'; // hash salt used when listing levels

        public static var LEVEL_SALT:String = '84ge5tnr'; // hash salt used when loading a level txt file
        public static var LEVEL_SALT_2:String = '0kg4%dsw'; // hash salt used when uploading a level

        public static var LEVEL_HASH_SALT:String = 'N^&drwseawf'; // another one

        public static var LEVEL_PASS_SALT:String = 'WGZSL3JWcUE9L3Q4YipZIQ=='; // hashes level passes prior to sending 

        public static var LEVEL_PASS_KEY:String = 'OWdCREBKUkI9JjEpQCNuYg==';
        public static var LEVEL_PASS_IV:String = 'ZiUybmpjc04mNEAkNythbg==';

    }

}