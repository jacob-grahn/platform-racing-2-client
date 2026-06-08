// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// LoginPage = class_22

package menu
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.SecureData;
    import com.jiggmin.data.SavedAccounts;
    import com.jiggmin.data.Settings;
    import page.Page;
    import dialogs.ConfirmPopup;
    //import dialogs.LogoutPassPopup;
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
        private var buttons:Array = new Array(); // buttons = var_45
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
            this.m.loggedInAs.visible = false;
            CheckServers.activate();
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
            SecureData.setNumber("userRank", 0);
            super.initialize();
        }

        private function addToMenu(pageButton:LoginPageMenuButton)
        {
            this.buttons.push(pageButton);
            pageButton.x = this.posX;
            pageButton.y = this.posY;
            addChild(pageButton);
            this.posY = this.posY + 22;
        }

        public function clickLogIn(e:MouseEvent)
        {
            SecureData.setNumber("userRank", -1);
            if (SavedAccounts.getAll().length > 0) {
                Main.userName = "";
                Main.userPass = "";
                new ServerSelectPopup(false);
            } else {
                new LoginPopup();
            }
        }

        public function clickGuest(e:MouseEvent)
        {
            Main.userName = "Guest";
            Main.userPass = "";
            Main.remember = false;
            SecureData.setNumber("userRank", 0);
            new ServerSelectPopup(true);
        }

        public function clickCreateAccount(e:MouseEvent)
        {
            new CreateAccountPopup();
        }

        public function clickInstructions(e:MouseEvent)
        {
            navigateToURL(new URLRequest(Main.baseURL + "/instructions.php"), "_blank");
        }

        public function clickCredits(e:MouseEvent)
        {
            new CreditsPopup();
        }

        private function clickKong(e:MouseEvent)
        {
            new KongOutfitPopup();
        }

        // _loc1 = item
        override public function remove()
        {
            this.m.kongLogo.removeEventListener(MouseEvent.CLICK, this.clickKong);
            clearInterval(this.showHideInterval);
            for each (var item:LoginPageMenuButton in this.buttons) {
                item.remove();
                item = null;
            }
            this.buttons = new Array();
            this.buttons = null;
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
