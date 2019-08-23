// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// LoginPage = class_22

package menu
{
    import data.class_28;
    import data.class_33;
    import data.Settings;
    import page.Page;
    import package_4.ConfirmPopup;
    import package_4.LogoutPassPopup;
    import flash.display.StageQuality;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.net.URLRequestMethod;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import ui.LoginPageMenuButton;

    public class LoginPage extends Page 
    {

        private var m:LoginPageGraphic = new LoginPageGraphic();
        private var itemsArray:Array = new Array(); // itemsArray = var_45
        private var posX:Number = 275;
        private var posY:Number = 228;
        private var showHideInterval:uint;

        public function LoginPage()
        {
            Settings.clear();
            addChild(this.m);
            this.addToMenu(new LoginPageMenuButton("Log In", this.clickLogIn));
            this.addToMenu(new LoginPageMenuButton("Play as Guest", this.clickGuest));
            this.addToMenu(new LoginPageMenuButton("Create Account", this.clickCreateAccount));
            this.addToMenu(new LoginPageMenuButton("Instructions", this.clickInstructions));
            this.addToMenu(new LoginPageMenuButton("Credits", this.clickCredits));
            this.m.kongLogo.visible = false;
            this.m.bubbleBoxLogo.visible = false;
            this.m.armorGamesLogo.visible = false;
            if (Main.siteMode == "kongregate") {
                this.m.kongLogo.visible = true;
                this.m.kongLogo.addEventListener(MouseEvent.CLICK, this.clickKong, false, 0, true);
            } else if (Main.siteMode == "bubbleBox") {
                this.m.bubbleBoxLogo.visible = true;
            } else if (Main.siteMode == "armorGames") {
                this.m.armorGamesLogo.visible = true;
            }
            this.showHideInterval = setInterval(this.showHideLoggedInAs, 500); // var_606 = showHideInterval
            this.showHideLoggedInAs();
            CheckServers.activate();
        }

        // method_201 = showHideLoggedInAs
        private function showHideLoggedInAs()
        {
            if (Main.loggedInAs == "" || !Main.remember) {
                this.m.loggedInAs.visible = false;
            } else {
                this.m.loggedInAs.visible = true;
                this.m.loggedInAs.textBox.text = "Logged in as " + Main.loggedInAs;
                this.m.loggedInAs.logoutButton.addEventListener(MouseEvent.CLICK, this.clickLogout, false, 0, true); // method_328 = clickLogout
            }
        }

        override public function initialize()
        {
            if (Settings.musicLevel > 0) {
                Main.noodleTown.startPlaying();
                Main.noodleTown.setTargetVolume(1 * (Settings.musicLevel / 100));
            }
            Main.stage.quality = StageQuality.HIGH;
            Main.userPass = "";
            Main.group = 0;
            class_33.setNumber("userRank", 0);
            super.initialize();
        }

        // method_77 = addToMenu
        private function addToMenu(pageButton:LoginPageMenuButton)
        {
            this.itemsArray.push(pageButton);
            pageButton.x = this.posX;
            pageButton.y = this.posY;
            addChild(pageButton);
            this.posY = this.posY + 22;
        }

        // method_165 = clickLogIn
        public function clickLogIn(e:MouseEvent)
        {
            class_33.setNumber("userRank", -1);
            if (Main.remember && Main.loggedInAs != "") {
                Main.userName = "";
                Main.userPass = "";
                new ServerSelectPopup();
            } else {
                new LoginPopup();
            }
        }

        // method_492 = clickGuest
        public function clickGuest(e:MouseEvent)
        {
            if (Main.remember && Main.loggedInAs != "") {
                new ConfirmPopup(this.playAsGuest, "It appears you\'re currently logged in as " + class_28.escapeString(Main.loggedInAs) + ". Do you want to log out of your account and log in as a guest?");
                return;
            } else {
                this.playAsGuest();
            }
        }

        public function playAsGuest()
        {
            Main.userName = "Guest";
            Main.userPass = "";
            Main.remember = false;
            class_33.setNumber("userRank", 0);
            new ServerSelectPopup();
        }

        // method_644 = clickCreateAccount
        public function clickCreateAccount(e:MouseEvent)
        {
            new CreateAccountPopup();
        }

        // method_793 = clickInstructions
        public function clickInstructions(e:MouseEvent)
        {
            navigateToURL(new URLRequest(Main.baseURL + "/pr2_instructions.php"), "_blank");
        }

        // method_413 = clickCredits
        public function clickCredits(e:MouseEvent)
        {
            new CreditsPopup();
        }

        // method_376 = clickKong
        private function clickKong(e:MouseEvent)
        {
            navigateToURL(new URLRequest("http://kongregate.com?gamereferral=platformracing2"), "_blank");
        }

        private function clickLogout(e:MouseEvent)
        {
            if (Main.token == "") {
                new LogoutPassPopup(this.showHideLoggedInAs());
                return;
            }
            var vars:URLVariables = new URLVariables();
            vars.token = Main.token;
            var request = new URLRequest(Main.baseURL + '/logout.php');
            request.data = vars;
            request.method = URLRequestMethod.POST;
            var superLoader:SuperLoader = new SuperLoader(true, "json");
            superLoader.load(request);
            superLoader.addEventListener(SuperLoader.d, this.logoutSuccessHandler);
        }

        private function logoutSuccessHandler(e:Event)
        {
            var ret:Object = SuperLoader(e.target).parsedData;
            if (ret.success === true) {
                Main.clearUserData();
                this.showHideLoggedInAs();
            } else {
                this.logoutErrorHandler(new Event(SuperLoader.e));
            }
        }

        // _loc1 = item
        override public function remove()
        {
            this.m.kongLogo.removeEventListener(MouseEvent.CLICK, this.clickKong);
            this.m.loggedInAs.logoutButton.removeEventListener(MouseEvent.CLICK, this.clickLogout);
            clearInterval(this.showHideInterval);
            for each (var item:LoginPageMenuButton in this.itemsArray) {
                item.remove();
                item = null;
            }
            this.itemsArray = new Array();
            this.itemsArray = null;
            this.m.bg.bg1.stop();
            this.m.bg.bg2.stop();
            this.m.bg.bg3.stop();
            removeChild(this.m);
            this.m = null;
            CheckServers.deactivate();
            super.remove();
        }


    }
}
