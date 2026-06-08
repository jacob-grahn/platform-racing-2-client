// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.LoggingInPopup = menu.class_165

package menu
{
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Encryptor;
    import com.jiggmin.data.PR2Socket;
    import com.jiggmin.data.SavedAccounts;
    import com.jiggmin.data.Settings;
    import com.jiggmin.data.UnreadNotif;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import lobby.Lobby;
    import player_profile.Presets;
    import dialogs.Popup;

    public class LoggingInPopup extends Popup 
    {

        private var loader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var m:LoggingInPopupGraphic = new LoggingInPopupGraphic();
        private var socketOK:Boolean = false; // var_560
        private var httpOK:Boolean = false; // var_615
        private var socket:PR2Socket;

        // _loc2 = send
        // _loc3 = sendStr
        // _loc4 = encryptor
        // _loc5 = encryptedStr
        // _loc6 = vars
        // _loc7 = request
        public function LoggingInPopup(loginId:String)
        {
            super();
            this.socket = Main.socket;
            this.socket.addEventListener(Event.CLOSE, this.onError, false, 0, true);
            CommandHandler.commandHandler.defineCommand("loginSuccessful", this.loginSuccessful);
            CommandHandler.commandHandler.defineCommand("loginFailure", this.loginFailure);

            // send login data to the server
            var send:Object = new Object();
            send.user_name = Main.userName;
            send.user_pass = Main.userPass;
            send.build = Main.build;
            send.server = Main.server;
            send.domain = Main.domain;
            send.remember = Main.remember;
            send.login_id = int(loginId);
            send.award_kong = Main.awardKongNextLogin;
            var sendStr:String = JSON.stringify(send);
            var encryptor:Encryptor = new Encryptor();
            encryptor.setKey(Env.LOGIN_KEY);
            encryptor.setIV(Env.LOGIN_IV);
            var encryptedStr:String = encryptor.encrypt(sendStr);
            var vars:URLVariables = new URLVariables();
            vars.i = encryptedStr;
            vars.build = Main.build;
            var request:URLRequest = new URLRequest(Main.baseURL + "/login.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            this.loader.addEventListener(SuperLoader.d, this.onHttpSuccess, false, 0, true);
            this.loader.addEventListener(SuperLoader.e, this.onError, false, 0, true);
            this.loader.load(request);

            Main.awardKongNextLogin = false;
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose);
            addChild(this.m);
        }

        public function loginSuccessful(ret:Array)
        {
            Main.group = int(ret[0]);
            Main.loggedInAs = ret[1];
            this.socketOK = true;
            this.maybeSwitchToLobby();
        }

        private function onHttpSuccess(e:Event)
        {
            var ret:Object = this.loader.parsedData;
            Main.userId = ret.userId;
            Main.hasEmail = ret.email;
            Main.token = ret.token;
            Main.guild = ret.guild;
            Main.guildOwner = ret.guildOwner;
            Main.guildName = ret.guildName;
            Main.emblem = ret.emblem;
            Main.favoriteLevels = ret.favoriteLevels;
            Main.lastAuthTime.setTime(ret.time);
            UnreadNotif.setLastRead(ret.lastRead);
            UnreadNotif.notifyUser(ret.lastRecv);
            this.httpOK = true;
            this.maybeSwitchToLobby();
        }

        private function onError(e:Event)
        {
            startFadeOut();
            Main.socket.remove();
            try {
                var ret:Object = JSON.parse(e.target.data);
                if ('resetToken' in ret && ret.resetToken) {
                    SavedAccounts.deleteAccount(Main.token, 'token');
                }
            } catch (e:Error) {
            }
            Main.clearUserData();
        }

        private function maybeSwitchToLobby()
        {
            if (this.socketOK && this.httpOK) {
                if (Main.remember) {
                    SavedAccounts.add(Main.loggedInAs, Main.token);
                }
                Settings.init(Main.loggedInAs);
                Presets.load();
                Main.pageHolder.changePage(new Lobby());
                startFadeOut();
            }
        }

        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
            Main.socket.remove();
        }

        public function loginFailure(a:Array)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.socket.removeEventListener(Event.CLOSE, this.onError);
            this.socket = null;
            CommandHandler.commandHandler.defineCommand("loginSuccessful", null);
            CommandHandler.commandHandler.defineCommand("loginFailure", null);
            this.loader.removeEventListener(SuperLoader.d, this.onHttpSuccess);
            this.loader.removeEventListener(SuperLoader.e, this.onError);
            this.loader.remove();
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            super.remove();
        }


    }
}
