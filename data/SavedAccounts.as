package data
{
    import flash.net.SharedObject;
    import package_4.MessagePopup;

    public class SavedAccounts
    {

        private static const COOKIE_ID = 'pr2hub_logged_in';

        private static var accounts:Array = null;


        public static function init()
        {
            getCookie();
        }

        private static function getCookie()
        {
            accounts = [];
            try {
                var cookie:SharedObject = SharedObject.getLocal(COOKIE_ID);
                for (var i:int = 0; i < cookie.data.accounts.length; i++) {
                    var account:Object = cookie.data.accounts[i];
                    account.name = class_28.trimWhitespace(account.name);
                    accounts.push(account);
                }
            } catch (e:Error) {
            }            
        }

        private static function setCookie()
        {
            try {
                var cookie:SharedObject = SharedObject.getLocal(COOKIE_ID);
                cookie.data.accounts = [];
                for (var i:int = 0; i < accounts.length; i++) {
                    cookie.data.accounts.push(accounts[i]);
                }
                cookie.flush();
            } catch (e:Error) {
            }
            getCookie();
        }

        public static function getAll()
        {
            return accounts;
        }

        private static function getArrayPosByName(name:String)
        {
            for (var i:int = 0; i < accounts.length; i++) {
                var account:Object = accounts[i];
                if (account.name.toLowerCase() === class_28.trimWhitespace(name).toLowerCase()) {
                    return i;
                }
            }
            return -1;
        }

        public static function getByName(name:String)
        {
            var accId:int = getArrayPosByName(name);
            return accId > -1 ? accounts[accId] : null;
        }

        public static function add(name:String, token:String)
        {
            // don't add an account that's already saved
            if (getByName(name) !== null) {
                moveToTop(name);
                return;
            }

            // save the account
            accounts.unshift({'name': class_28.trimWhitespace(name), 'token': token});
            setCookie();
        }

        public static function deleteByName(name:String)
        {
            // ensure existing
            var accId:int = getArrayPosByName(name);
            if (accId === -1) {
                return false;
            }

            // delete from accounts array
            accounts.removeAt(accId);
            setCookie();
        }

        private static function moveToTop(name:String)
        {
            var accId:int = getArrayPosByName(name);
            if (accId <= -1) {
                return false;
            }

            // move account to beginning of array
            accounts.unshift(accounts.removeAt(accId));
            setCookie();
        }

    }
}