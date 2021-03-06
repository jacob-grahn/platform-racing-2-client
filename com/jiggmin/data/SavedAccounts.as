package com.jiggmin.data
{
    import flash.net.SharedObject;
    import package_4.MessagePopup;

    public class SavedAccounts
    {

        private static var cookieId;
        private static var accounts:Array = null;


        public static function init()
        {
            cookieId = Main.baseURL.substr(-3) === 'dev' ? 'pr2hub_dev_logged_in' : 'pr2hub_logged_in';
            getCookie();
        }

        private static function getCookie()
        {
            accounts = [];
            try {
                var cookie:SharedObject = SharedObject.getLocal(cookieId);
                for (var i:int = 0; i < cookie.data.accounts.length; i++) {
                    var account:Object = cookie.data.accounts[i];
                    account.name = Data.trimWhitespace(account.name);
                    if (account.name != '') {
                        accounts.push(account);
                    }
                }
            } catch (e:Error) {
            }
        }

        private static function setCookie()
        {
            try {
                var cookie:SharedObject = SharedObject.getLocal(cookieId);
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

        private static function getArrayPos(data:String, mode:String = 'name')
        {
            for (var i:int = 0; i < accounts.length; i++) {
                var account:Object = accounts[i];
                if (
                    (mode === 'name' && account.name.toLowerCase() === Data.trimWhitespace(data).toLowerCase())
                    || (mode === 'token' && account.token === data)
                ) {
                    return i;
                }
            }
            return -1;
        }

        public static function getByName(name:String)
        {
            var accId:int = getArrayPos(name);
            return accId > -1 ? accounts[accId] : null;
        }

        public static function add(name:String, token:String)
        {
            // don't add an account with no name
            if (Data.trimWhitespace(name) == '') {
                return;
            }

            // don't add an account that's already saved
            if (getByName(name) !== null) {
                updateToken(name, token);
                moveToTop(name);
                return;
            }

            // save the account
            accounts.unshift({'name': Data.trimWhitespace(name), 'token': token});
            setCookie();
        }

        public static function deleteAccount(data:String, mode:String = 'name')
        {
            // ensure existing
            var accId:int = getArrayPos(data, mode);
            if (accId === -1) {
                return false;
            }

            // delete from accounts array
            accounts.removeAt(accId);
            setCookie();
        }

        private static function updateToken(name:String, token:String)
        {
            var accId:int = getArrayPos(name);
            if (accId === -1) {
                return false;
            }

            // update the token
            accounts[accId].token = token;
            setCookie();
        }

        private static function moveToTop(name:String)
        {
            var accId:int = getArrayPos(name);
            if (accId <= -1) {
                return false;
            }

            // move account to beginning of array
            accounts.unshift(accounts.removeAt(accId));
            setCookie();
        }

    }
}