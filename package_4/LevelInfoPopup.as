package package_4
{
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.events.Event;
    import data.HTMLNameMaker;
    import data.class_28;
    import data.class_33;
    import flash.net.URLRequestMethod;
    import package_6.Game;
    import package_18.PartInfo.*;
    import lobby.LobbyRight;

    public class LevelInfoPopup extends Popup 
    {
        public static var instance;

        private var superLoader:SuperLoader;
        private var m:LevelInfoPopupGraphic = new LevelInfoPopupGraphic();
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();

        private var levelId:int = 0;

        private var live:Boolean = false; // live
        private var hasPass:Boolean = true; // has_pass
        
        private var userId:int = 0; // user_id
        private var userName:String = "";
        private var userGroup:String = '0';

        private var title:String = ''; // title
        private var note:String = ''; // note
        private var version:int = 1; // version
        private var time:int = 0; // time
        private var updated:Date;
        private var plays:int = 0; // play_count
        private var rating:Number = 0.0; // rating

        private var maxTime:int = 120; // max_time
        private var minRank:int = 0; // min_rank
        private var gravity:Number = 1.0; // gravity
        private var items:String = "Laser Gun`Mine`Lightning`Teleport`Super Jump`Jet Pack`Speed Burst`Sword`Ice Wave"; // items
        private var song:String = ''; // song
        private var gameMode:String = 'race'; // gameMode
        private var cowboyChance:int = 5; // cowboyChance

        // hovers
        private var hoverRating:HoverPopup;
        private var hoverGameMode:HoverPopup;
        private var hoverSong:HoverPopup;
        private var hoverCowboyChance:HoverPopup;
        private var hoverMaxTime:HoverPopup;
        private var hoverGravity:HoverPopup;
        private var hoverItems:InfoPopup;

        // uploading popup
        private var uploadingRemove:UploadingPopup;


        public function LevelInfoPopup(id:int)
        {
            if (LevelInfoPopup.instance != null) {
                LevelInfoPopup.instance.startFadeOut();
            }
            LevelInfoPopup.instance = this;

            this.levelId = id;
            this.m.levelInfo.visible = false;
            this.m.levelInfo.rating.buttonMode = this.m.levelInfo.gameMode.buttonMode = true;
            this.m.levelInfo.rating.cover.visible = this.m.levelInfo.gameMode.cover.visible = false;
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.levelId;
            var request:URLRequest = new URLRequest(Main.levelsURL.substr(0, -7) + "/level_data.php");
            request.data = vars;
            this.superLoader.load(request);
            this.superLoader.addEventListener(SuperLoader.d, this.applyReturnData, false, 0, true);
            this.superLoader.addEventListener(SuperLoader.e, this.clickClose, false, 0, true);
        }

        private function applyReturnData(e:Event)
        {
            var ret:Object = SuperLoader(e.target).parsedData;

            this.live = ret.live;
            this.hasPass = ret.has_pass;
            this.userId = ret.user_id;
            this.userName = ret.user_name;
            this.userGroup = ret.user_group;
            this.rating = ret.rating;
            this.time = ret.time;
            this.updated = new Date(this.time * 1000);
            this.gravity = ret.gravity;
            this.maxTime = ret.max_time;
            this.items = ret.items;
            this.song = this.determineSong(ret.song);
            this.gameMode = this.determineMode(ret.gameMode);
            this.cowboyChance = ret.cowboyChance;

            // apply straight to mc
            this.m.levelInfo.title.text = this.title = ret.title;
            this.m.levelInfo.note.text = this.note = ret.note;
            this.m.levelInfo.version.text = this.version = class_28.formatNumber(ret.version);
            this.m.levelInfo.plays.text = this.plays = class_28.formatNumber(ret.play_count);
            this.m.levelInfo.minRank.text = this.minRank = ret.min_rank;

            // make strings/data to give to mc
            this.m.levelInfo.author.htmlText = 'by: ' + this.htmlNameMaker.makeName(this.userName, this.userGroup);
            this.htmlNameMaker.listenForLink(this.m.levelInfo.author);
            this.m.levelInfo.updated.text = this.updated.date + '/' + class_28.getMonthStr(this.updated.month) + '/' + this.updated.fullYear;
            this.m.levelInfo.rating.stars.bar.scaleX = this.rating / 5;

            // hover events
            this.m.levelInfo.rating.addEventListener(MouseEvent.MOUSE_OVER, this.overRatingHandler, false, 0, true);
            this.m.levelInfo.rating.addEventListener(MouseEvent.MOUSE_OUT, this.outRatingHandler, false, 0, true);
            this.m.levelInfo.gameMode.addEventListener(MouseEvent.MOUSE_OVER, this.overGameModeHandler, false, 0, true);
            this.m.levelInfo.gameMode.addEventListener(MouseEvent.MOUSE_OUT, this.outGameModeHandler, false, 0, true);
            this.m.levelInfo.song.addEventListener(MouseEvent.MOUSE_OVER, this.overSongHandler, false, 0, true);
            this.m.levelInfo.song.addEventListener(MouseEvent.MOUSE_OUT, this.outSongHandler, false, 0, true);
            this.m.levelInfo.cowboyChance.addEventListener(MouseEvent.MOUSE_OVER, this.overCowboyChanceHandler, false, 0, true);
            this.m.levelInfo.cowboyChance.addEventListener(MouseEvent.MOUSE_OUT, this.outCowboyChanceHandler, false, 0, true);
            this.m.levelInfo.maxTime.addEventListener(MouseEvent.MOUSE_OVER, this.overMaxTimeHandler, false, 0, true);
            this.m.levelInfo.maxTime.addEventListener(MouseEvent.MOUSE_OUT, this.outMaxTimeHandler, false, 0, true);
            this.m.levelInfo.gravity.addEventListener(MouseEvent.MOUSE_OVER, this.overGravityHandler, false, 0, true);
            this.m.levelInfo.gravity.addEventListener(MouseEvent.MOUSE_OUT, this.outGravityHandler, false, 0, true);
            this.m.levelInfo.items.addEventListener(MouseEvent.MOUSE_OVER, this.overItemsHandler, false, 0, true);
            this.m.levelInfo.items.addEventListener(MouseEvent.MOUSE_OUT, this.outItemsHandler, false, 0, true);

            // enable play button
            /*var myRank:Number = class_33.getNumber("userRank");
            myRank = isNaN(myRank) || myRank < 0 ? 0 : myRank;*/
            //if ((this.live && !this.hasPass && this.minRank <= myRank) || Main.group >= 2) {
                this.m.play_bt.enabled = true;
                this.m.play_bt.addEventListener(MouseEvent.CLICK, this.clickPlay, false, 0, true);
            //}

            // buttons
            if (Main.group >= 1) {
                // enable share
                this.m.levelInfo.share_bt.addEventListener(MouseEvent.CLICK, this.clickShare, false, 0, true);

                // choose whether to enable report or unpublish
                if (Main.group >= 2) {
                    this.m.levelInfo.removeChild(this.m.levelInfo.report_bt);
                    this.m.levelInfo.unpublish_bt.addEventListener(MouseEvent.CLICK, this.clickRemove, false, 0, true);
                } else if (Main.group == 1) {
                    this.m.levelInfo.removeChild(this.m.levelInfo.unpublish_bt);
                    this.m.levelInfo.report_bt.addEventListener(MouseEvent.CLICK, this.clickReport, false, 0, true);
                }
            } else {
                this.m.levelInfo.removeChild(this.m.levelInfo.report_bt);
                this.m.levelInfo.removeChild(this.m.levelInfo.unpublish_bt);
                this.m.levelInfo.removeChild(this.m.levelInfo.share_bt);
            }

            // show m.levelInfo
            this.m.loading.visible = false;
            this.m.levelInfo.visible = true;
        }

        private function overRatingHandler(e:MouseEvent)
        {
            this.m.levelInfo.rating.cover.visible = true;
            this.hoverRating = new HoverPopup('', this.rating, this.m.levelInfo.rating);
            this.hoverRating.x += 238;
            this.hoverRating.y -= 15;
            this.hoverRating.width /= 2;
        }

        private function outRatingHandler(e:*)
        {
            this.m.levelInfo.rating.cover.visible = false;
            this.hoverRating.remove();
            this.hoverRating = null;
        }

        private function overGameModeHandler(e:MouseEvent)
        {
            this.m.levelInfo.gameMode.cover.visible = true;
            this.hoverGameMode = new HoverPopup('Game Mode', this.gameMode, this.m.levelInfo.gameMode);
        }

        private function outGameModeHandler(e:*)
        {
            this.m.levelInfo.gameMode.cover.visible = false;
            this.hoverGameMode.remove();
            this.hoverGameMode = null;
        }

        private function overSongHandler(e:MouseEvent)
        {
            this.hoverSong = new HoverPopup('Music', this.song, this.m.levelInfo.song);
            this.hoverSong.x += 193;
        }

        private function outSongHandler(e:*)
        {
            this.hoverSong.remove();
            this.hoverSong = null;
        }

        private function overCowboyChanceHandler(e:MouseEvent)
        {
            this.hoverCowboyChance = new HoverPopup('Chance of Cowboy Mode', this.cowboyChance + '%', this.m.levelInfo.cowboyChance);
        }

        private function outCowboyChanceHandler(e:*)
        {
            this.hoverCowboyChance.remove();
            this.hoverCowboyChance = null;
        }

        private function overMaxTimeHandler(e:MouseEvent)
        {
            this.hoverMaxTime = new HoverPopup('Time Limit', this.maxTime == 0 || (this.maxTime == 999 && this.time < 1358640000) ? 'Infinite' : class_28.formatTime(this.maxTime) + " (" + class_28.formatNumber(this.maxTime) + " seconds)", this.m.levelInfo.maxTime);
        }

        private function outMaxTimeHandler(e:*)
        {
            this.hoverMaxTime.remove();
            this.hoverMaxTime = null;
        }

        private function overGravityHandler(e:MouseEvent)
        {
            this.hoverGravity = new HoverPopup('Gravity Multiplier', this.gravity, this.m.levelInfo.gravity);
        }

        private function outGravityHandler(e:*)
        {
            this.hoverGravity.remove();
            this.hoverGravity = null;
        }

        private function overItemsHandler(e:MouseEvent)
        {
            this.hoverItems = new ItemMenu(this.items, this.m.levelInfo.items);
        }

        private function outItemsHandler(e:*)
        {
            this.hoverItems.remove();
            this.hoverItems = null;
        }

        private function determineMode(mode:String)
        {
            if (mode == 'deathmatch' || mode == 'dm' || mode == 'd') {
                mode = 'Deathmatch';
                this.m.levelInfo.gameMode.modeSym.gotoAndStop(2);
            } else if (mode == 'eggs' || mode == 'egg' || mode == 'e') {
                mode = 'Alien Eggs';
                this.m.levelInfo.gameMode.modeSym.gotoAndStop(3);
            } else if (mode == 'objective' || mode == 'obj' || mode == 'o') {
                mode = 'Objective';
                this.m.levelInfo.gameMode.modeSym.gotoAndStop(4);
            } else {
                mode = 'Race';
                this.m.levelInfo.gameMode.modeSym.gotoAndStop(1);
            }
            return mode;
        }

        private function determineSong(song:String)
        {
            if (song == '' || song == 'random') {
                return "Random";
            } else if (song == '0' || song == 'none') {
                return "None";
            }

            song = int(song);
            var songArr = [
                "None",
                "Orbital Trance - Space Planet",
                "Code - Stefano Maccarelli",
                "Paradise on E - API",
                "Crying Soul (FL Mix) - Pyroific",
                "My Vision - David Orr",
                "Switchblade - SKAzini",
                "The Wires - Cheez-R-Us",
                "Before Mydnite - F-777",
                "", // desert rose
                "Broked It - SWiTCH",
                "Hello? - TMM43",
                "Pyrokinesis - Sean Tucker",
                "Flowerz 'n' Herbz - Brunzolaitis",
                "Instrumental #4 - Reasoner",
                "Prismatic - Lunanova",
                "We Are Loud - Dynamedion", // should never be triggered; song can't be set to we are loud
                "Toodaloo - mustangman"
            ];
            return songArr[song];
        }

        private function clickShare(e:MouseEvent)
        {
            var message:String = "Hey, check out this level! \n\n[level=" + this.levelId + "]" + this.title + "[/level] by [user]" + this.userName + "[/user]";
            new SendMessagePopup("", message, false, true);
        }

        private function clickReport(e:MouseEvent)
        {
            new LevelReportPopup(this.levelId, this.version);
        }

        private function clickRemove(e:MouseEvent)
        {
            new ConfirmPopup(this.confirmRemove, "Are you sure you want to remove this level?");
        }

        private function confirmRemove()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.levelId;
            var request:URLRequest = new URLRequest(Main.baseURL + "/remove_level.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploadingRemove = new UploadingPopup(request, 'json');
            this.uploadingRemove.addEventListener(SuperLoader.d, this.returnRemove, false, 0, true);
        }

        private function returnRemove(e:*)
        {
            if (this.uploadingRemove.parsedData.success === true) {
                startFadeOut();
            }
        }

        private function clickPlay(e:MouseEvent)
        {
            // add validation + server code
            /*
            Flow:
             - Client sends socket command to manually start the game
             - Server gets the socket command and routes to a fn
             - Response to socket command:
                - Somewhat replicate flow in CourseBox.php
                - Also check to see if the user is in a course box rn
                - Validate as you see fit
             - Server sends back startGame.
            */
            //startFadeOut();
            //Main.pageHolder.changePage(new Game(this.levelId, this.version));
            if (PartPopup.instance != null) {
                PartPopup.instance.startFadeOut();
            }
            if (PartInfoPopup.instance != null) {
                PartInfoPopup.instance.startFadeOut();
            }
            if (LobbyRight.lobbyRight != null) {
                LobbyRight.lobbyRight.lookupLevel(this.levelId);
            }
            startFadeOut();
            //new MessagePopup('Placeholder!'); // code to automatically start the race
        }

        private function clickClose(e:*)
        {
            startFadeOut();
        }

        private function closeHoverPopups()
        {
            if (this.hoverRating != null) {
                this.outRatingHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverGameMode != null) {
                this.outGameModeHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverSong != null) {
                this.outSongHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverCowboyChance != null) {
                this.outCowboyChanceHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverMaxTime != null) {
                this.outMaxTimeHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverGravity != null) {
                this.outGravityHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
            if (this.hoverItems != null) {
                this.outItemsHandler(dispatchEvent(new Event(Event.CLOSE)));
            }
        }

        override public function remove()
        {
            if (LevelInfoPopup.instance === this) {
                LevelInfoPopup.instance = null;
            }
            this.closeHoverPopups();
            this.m.levelInfo.rating.removeEventListener(MouseEvent.MOUSE_OVER, this.overRatingHandler);
            this.m.levelInfo.rating.removeEventListener(MouseEvent.MOUSE_OUT, this.outRatingHandler);
            this.m.levelInfo.gameMode.removeEventListener(MouseEvent.MOUSE_OVER, this.overGameModeHandler);
            this.m.levelInfo.gameMode.removeEventListener(MouseEvent.MOUSE_OUT, this.outGameModeHandler);
            this.m.levelInfo.song.removeEventListener(MouseEvent.MOUSE_OVER, this.overSongHandler);
            this.m.levelInfo.song.removeEventListener(MouseEvent.MOUSE_OUT, this.outSongHandler);
            this.m.levelInfo.cowboyChance.removeEventListener(MouseEvent.MOUSE_OVER, this.overCowboyChanceHandler);
            this.m.levelInfo.cowboyChance.removeEventListener(MouseEvent.MOUSE_OUT, this.outCowboyChanceHandler);
            this.m.levelInfo.maxTime.removeEventListener(MouseEvent.MOUSE_OVER, this.overMaxTimeHandler);
            this.m.levelInfo.maxTime.removeEventListener(MouseEvent.MOUSE_OUT, this.outMaxTimeHandler);
            this.m.levelInfo.gravity.removeEventListener(MouseEvent.MOUSE_OVER, this.overGravityHandler);
            this.m.levelInfo.gravity.removeEventListener(MouseEvent.MOUSE_OUT, this.outGravityHandler);
            this.m.levelInfo.items.removeEventListener(MouseEvent.MOUSE_OVER, this.overItemsHandler);
            this.m.levelInfo.items.removeEventListener(MouseEvent.MOUSE_OUT, this.outItemsHandler);

            // possibly enabled?
            this.m.play_bt.removeEventListener(MouseEvent.CLICK, this.clickPlay);
            this.m.levelInfo.unpublish_bt.removeEventListener(MouseEvent.CLICK, this.clickRemove);
            this.m.levelInfo.report_bt.removeEventListener(MouseEvent.CLICK, this.clickReport);
            this.m.levelInfo.share_bt.removeEventListener(MouseEvent.CLICK, this.clickShare);

            // possibly instantiated?
            if (this.uploadingRemove != null) {
                this.uploadingRemove.removeEventListener(SuperLoader.d, this.returnRemove);
                this.uploadingRemove.startFadeOut();
                this.uploadingRemove = null;
            }

            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            if (this.superLoader != null) {
                this.superLoader.removeEventListener(SuperLoader.d, this.applyReturnData);
                this.superLoader.removeEventListener(SuperLoader.e, this.clickClose);
                this.superLoader.remove();
                this.superLoader = null;
            }
            this.htmlNameMaker.remove();
            this.htmlNameMaker = null;
            removeChild(m);
            this.m = null;
            super.remove();
        }


    }
}
