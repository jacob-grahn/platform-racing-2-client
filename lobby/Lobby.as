// lobby.Lobby = lobby.class_152

package lobby
{
    import data.Settings;
    import page.Page;
    import package_4.HoverPopup;
    import flash.display.MovieClip;
    import flash.display.StageQuality;
    import flash.events.MouseEvent;
    import lobby.Lobby;
    import package_4.MessagePopup;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import menu.LoginPage;
    import levelEditor.LevelEditor;
    import flash.net.navigateToURL;
    import package_4.OptionsPopup;
    import package_17.StorePopup;
    import menu.CreditsPopup;

    public class Lobby extends Page 
    {

        public static var var_516:Boolean = false;
        public static var lobbyEntrances:int = 0; // var_277

        private var left:LobbyLeft;
        private var right:LobbyRight;
        private var m:LobbyGraphic = new LobbyGraphic();
        private var hover:HoverPopup; // var_234
        private var bottom_bts:LobbyBottomButtonsGraphic; // var_20

        public function Lobby()
        {
        }

        override public function initialize()
        {
            this.left = new LobbyLeft();
            this.right = new LobbyRight();
            addChild(this.m);
            addChild(this.left);
            addChild(this.right);
            if (Settings.musicLevel > 0) {
                Main.noodleTown.startPlaying();
            }
            Main.noodleTown.setTargetVolume(0.6 * (Settings.musicLevel / 100));
            Main.stage.quality = StageQuality.HIGH;
            this.bottom_bts = new LobbyBottomButtonsGraphic();
            if (Main.siteMode == "kongregate") {
                if (Main.domain.indexOf("kongregate.com") != -1 && Main.group != 0) {
                    this.bottom_bts.gotoAndStop("kongregateSite");
                } else {
                    this.bottom_bts.gotoAndStop("miscSite");
                }
            } else {
                this.bottom_bts.gotoAndStop("sponsoredSite");
            }
            /*if (Main.testing) {
                this.bottom_bts.gotoAndStop("kongregateSite");
            }*/
            this.bottom_bts.logoutButton.addEventListener(MouseEvent.CLICK, this.clickLogout, false, 0, true);
            this.bottom_bts.levelEditorButton.addEventListener(MouseEvent.CLICK, this.clickLE, false, 0, true);
            this.bottom_bts.moreGamesButton.addEventListener(MouseEvent.CLICK, this.clickKong, false, 0, true);
            this.bottom_bts.optionsButton.addEventListener(MouseEvent.CLICK, this.clickOptions, false, 0, true);
            this.bottom_bts.vaultButton.addEventListener(MouseEvent.CLICK, this.clickStore, false, 0, true);
            this.bottom_bts.creditsButton.addEventListener(MouseEvent.CLICK, this.clickCredits, false, 0, true);
            this.bottom_bts.moreGamesButton.addEventListener(MouseEvent.MOUSE_OVER, this.hoverKong, false, 0, true);
            this.bottom_bts.moreGamesButton.addEventListener(MouseEvent.MOUSE_OUT, this.hoverOutKong, false, 0, true);
            addChild(this.bottom_bts);
            this.method_547();
        }

        private function method_547()
        {
            if (Main.siteMode == "kongregate" && Main.instance.kongAPI != null && !Main.hasAnt) {
                if (Main.instance.kongAPI.services.isGuest() && Main.group != 0) {
                    Lobby.lobbyEntrances++;
                    if (Lobby.lobbyEntrances == 4 || Lobby.lobbyEntrances == 10) {
                        new KongOutfitPopup();
                    }
                } else {
                    Main.socket.write("award_kong_outfit`");
                    Main.socket.write("get_customize_info`");
                    new MessagePopup("Thank you for playing Platform Racing 2 on Kongregate! To say thanks you have been awarded a special Kongregate Solidier Ant outfit. Enjoy!");
                    Main.hasAnt = true;
                }
            }
        }

        // method_328 = clickLogout
        private function clickLogout(e:MouseEvent)
        {
            if (!Main.remember) {
                var vars:URLVariables = new URLVariables();
                vars.from_lobby = '1';
                var request:URLRequest = new URLRequest(Main.baseURL + '/logout.php');
                request.data = vars;
                request.method = URLRequestMethod.POST;
                var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);
                superLoader.load(request);
                Main.clearUserData();
            }
            Main.pageHolder.changePage(new LoginPage());
            Main.socket.close();
        }

        // method_233 = clickLE
        private function clickLE(e:MouseEvent)
        {
            Main.pageHolder.changePage(new LevelEditor(null));
            Main.socket.close();
        }

        // method_437 = clickKong
        private function clickKong(e:MouseEvent)
        {
            navigateToURL(new URLRequest("http://www.kongregate.com/games/jiggmin/platform-racing-2/?gamereferral=platformracing2"), "_blank");
        }

        // method_433 = clickOptions
        private function clickOptions(e:MouseEvent)
        {
            new OptionsPopup();
        }

        // method_428 = clickStore
        private function clickStore(e:MouseEvent)
        {
            new StorePopup();
        }

        // method_413 = clickCredits
        private function clickCredits(e:MouseEvent)
        {
            new CreditsPopup();
        }

        // method_291 = hoverKong
        private function hoverKong(e:MouseEvent)
        {
            this.hover = new HoverPopup("Kong Hat", "Players from Kongregate automatically get a hat that increases your experience gain by 25%!", this.bottom_bts.moreGamesButton);
        }

        // method_353 = hoverOutKong
        private function hoverOutKong(e:MouseEvent)
        {
            this.hover.remove();
            this.hover = null;
        }

        override public function remove()
        {
            this.bottom_bts.logoutButton.removeEventListener(MouseEvent.CLICK, this.clickLogout);
            this.bottom_bts.levelEditorButton.removeEventListener(MouseEvent.CLICK, this.clickLE);
            this.bottom_bts.moreGamesButton.removeEventListener(MouseEvent.CLICK, this.clickKong);
            this.bottom_bts.optionsButton.removeEventListener(MouseEvent.CLICK, this.clickOptions);
            this.bottom_bts.vaultButton.removeEventListener(MouseEvent.CLICK, this.clickStore);
            this.bottom_bts.creditsButton.removeEventListener(MouseEvent.CLICK, this.clickCredits);
            this.bottom_bts.moreGamesButton.removeEventListener(MouseEvent.MOUSE_OVER, this.hoverKong);
            this.bottom_bts.moreGamesButton.removeEventListener(MouseEvent.MOUSE_OUT, this.hoverOutKong);
            removeChild(this.bottom_bts);
            this.bottom_bts = null;
            this.left.remove();
            this.right.remove();
            removeChild(this.m);
            this.m = null;
            this.left = null;
            this.right = null;
            if (this.hover != null) {
                this.hover.remove();
                this.hover = null;
            }
            Main.noodleTown.setTargetVolume(0);
            super.remove();
        }


    }
}//package lobby

