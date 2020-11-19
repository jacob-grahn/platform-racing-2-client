// ServerSelectPopup = menu.class_72

package menu
{
    import data.class_28;
    import data.SavedAccounts;
    import fl.controls.ComboBox;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.setTimeout;
    import package_4.Popup;
    import package_4.ConfirmPopup;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;

    public class ServerSelectPopup extends Popup 
    {

        private var m:ServerSelectPopupGraphic = new ServerSelectPopupGraphic();

        public function ServerSelectPopup(guestLogin:Boolean = true)
        {
            this.m.login_bt.addEventListener(MouseEvent.CLICK, this.clickLogIn, false, 0, true); // method_165
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.reload_bt.addEventListener(MouseEvent.CLICK, this.clickReload, false, 0, true);
            if (guestLogin) {
                this.m.user_del_bt.alpha = 0.1;
                this.m.user_del_bt.enabled = this.m.userSelect.enabled = false;
            } else {
                this.m.userSelect.addEventListener(Event.CHANGE, this.userChange, false, 0, true);
                this.userSelectPopulate();
            }
            addChild(this.m);
            CheckServers.determineServer(this.m.serverSelect);
            if (this.m.serverSelect.length <= 1) {
                this.m.serverSelect.selectedItem = this.m.serverSelect.dataProvider.getItemAt(0);
                this.clickLogIn(new MouseEvent("click"));
            }
        }

        public function userSelectPopulate()
        {
            var savedAccounts:Array = SavedAccounts.getAll();

            // if no accounts saved, load regular login popup
            if (savedAccounts.length === 0) {
                new LoginPopup();
                startFadeOut();
                return;
            }

            // add accounts
            this.m.userSelect.removeAll();
            this.m.userSelect.prompt = null;
            for (var i:int = 0; i < savedAccounts.length; i++) {
                var listItem:Object = {};
                listItem.label = savedAccounts[i].name;
                listItem.token = savedAccounts[i].token;
                this.m.userSelect.addItem(listItem);
            }

            // add new account option
            this.m.userSelect.addItem({'label': 'Use Other Account...', 'token': ''});

            // select first account
            this.m.userSelect.selectedItem = this.m.userSelect.dataProvider.getItemAt(0);

            // enable dropdown
            this.m.userSelect.enabled = true;
            this.m.userSelect.dispatchEvent(new Event(Event.CHANGE));
        }

        private function toggleUserButton(enable:Boolean)
        {
            if (enable) {
                this.m.user_del_bt.alpha = this.m.login_bt.alpha = 1;
                this.m.user_del_bt.enabled = this.m.login_bt.enabled = true;
                this.m.user_del_bt.addEventListener(MouseEvent.CLICK, this.clickUserDelete, false, 0, true);
            } else {
                this.m.user_del_bt.alpha = this.m.login_bt.alpha = 0.1;
                this.m.user_del_bt.enabled = this.m.login_bt.enabled = false;
                this.m.user_del_bt.removeEventListener(MouseEvent.CLICK, this.clickUserDelete);
            }
        }

        private function userChange(e:Event)
        {
            var account:Object = this.m.userSelect.selectedItem;
            if (account.token === '') {
                Main.token = '';
                Main.remember = false;
                this.toggleUserButton(false);
                new LoginPopup(this);
            } else {
                Main.token = account.token;
                Main.remember = true;
                this.toggleUserButton(true);
            }
        }

        private function clickUserDelete(e:MouseEvent)
        {
            var name:String = class_28.escapeString(this.m.userSelect.selectedItem.label);
            new ConfirmPopup(this.doUserDelete, 'Are you sure you want to delete "' + name + '" from your saved accounts?');
        }

        public function doUserDelete()
        {
            var listItem:Object = this.m.userSelect.selectedItem;

            // sanity: not a valid account
            if (listItem.token === '') {
                return;
            }

            // delete from server
            var vars:URLVariables = new URLVariables();
            var request:URLRequest = new URLRequest(Main.baseURL + "/logout.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            var sl:SuperLoader = new SuperLoader(true, SuperLoader.j);
            sl.load(request);

            // delete from cookie
            if (SavedAccounts.deleteByName(listItem.label) === false) {
                new MessagePopup('Error: Invalid account specified.');
                return;
            }

            // populate list
            this.userSelectPopulate();
        }

        private function clickLogIn(e:MouseEvent)
        {
            if (this.m.serverSelect.length > 0) {
                Main.server = this.m.serverSelect.selectedItem.server;
                new ConnectingPopup();
                startFadeOut();
            }
        }

        private function clickReload(e:MouseEvent)
        {
            if (this.m.reload_bt.enabled == true) {
                this.m.reload_bt.enabled = false;
                this.m.reload_bt.alpha = 0.1;
                setTimeout(enableReload, 10000);
                CheckServers.reload();
            }
        }

        private function enableReload()
        {
            this.m.reload_bt.enabled = true;
            this.m.reload_bt.alpha = 1;
        }

        private function clickCancel(e:MouseEvent)
        {
            Main.token = '';
            Main.remember = false;
            startFadeOut();
        }

        /*public function extClose()
        {
            startFadeOut();
        }*/

        override public function remove()
        {
            this.m.login_bt.removeEventListener(MouseEvent.CLICK, this.clickLogIn);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.reload_bt.removeEventListener(MouseEvent.CLICK, this.clickReload);
            this.m.user_del_bt.removeEventListener(MouseEvent.CLICK, this.clickUserDelete);
            this.m.userSelect.removeEventListener(Event.CHANGE, this.userChange);
            CheckServers.removeBox();
            super.remove();
        }


    }
}
