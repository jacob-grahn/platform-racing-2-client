

package level_browser
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.SecureData;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Encryptor;
    import com.jiggmin.data.HTMLNameMaker;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import lobby.Lobby;
    import dialogs.ConfirmPopup;
    import dialogs.HoverPopup;
    import dialogs.LevelInfoPopup;
    import dialogs.MessagePopup;
    import dialogs.UploadingPopup;
    import player_profile.AccountInfo;
    import ui.PageNavigation;

    public class LevelItem extends Removable 
    {

        //private static var unlocked:Boolean = false; // var_332

        private var m:LevelItemGraphic = new LevelItemGraphic();
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var infoPopup:HoverPopup;
        private var favBtPopup:HoverPopup;
        private var favBtTimer:uint;
        private var slotArray:Array = new Array(); // var_127
        private var coverActive = true;
        public var courseID:int;
        public var version:int;
        private var title:String;
        private var rating:Number;
        private var playCount:Number;
        private var myRank:Number;
        private var minRank:Number;
        private var note:String;
        private var userName:String;
        private var group:String;
        private var pass:Boolean;
        private var passOK:Boolean = false;
        private var type:String;
        private var badHats:Vector.<int> = new Vector.<int>;
        private var lastUpdated:int;
        private var maxSlots:Number = 4; // var_590
        private var superLoader:SuperLoader; // var_80
        private var uploading:UploadingPopup;

        // _loc12 = htmlName
        // _loc13 = myRank
        public function LevelItem(id:int, v:int, t:String, r:Number, plays:int, rank:int, desc:String, uName:String, uGroup:String, hasPass:Boolean, gMode:String, badHatsStr:String, time:int)
        {
            this.courseID = id;
            this.version = v;
            this.title = t;
            this.rating = r;
            this.playCount = plays;
            this.myRank = SecureData.getNumber("userRank");
            this.minRank = rank;
            this.note = desc;
            this.userName = uName;
            this.group = uGroup;
            this.pass = hasPass;
            this.passOK = !this.pass;
            this.type = gMode;
            this.lastUpdated = time;
            this.myRank = isNaN(this.myRank) || this.myRank < 0 ? 0 : this.myRank;
            this.minRank = Data.numLimit(this.minRank, 0, 99);
            var htmlName:String = this.htmlNameMaker.makeName(this.userName, this.group);
            this.m.titleBox.text = this.title;
            this.m.authorBox.htmlText = "by " + htmlName;
            this.m.ratingStars.bar.scaleX = this.rating / 5;
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler, false, 0, true);
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler, false, 0, true);
            this.m.infoButton.addEventListener(MouseEvent.CLICK, this.clickInfoHandler, false, 0, true);
            if (Main.group >= 1) {
                if (Main.favoriteLevels.indexOf(this.courseID) > -1) {
                    this.m.minusButton.addEventListener(MouseEvent.MOUSE_OVER, this.overFavBt, false, 0, true);
                    this.m.minusButton.addEventListener(MouseEvent.MOUSE_OUT, this.outFavBt, false, 0, true);
                    this.m.minusButton.addEventListener(MouseEvent.CLICK, this.clickMinus, false, 0, true);
                    this.m.removeChild(this.m.plusButton);
                } else {
                    this.m.plusButton.addEventListener(MouseEvent.MOUSE_OVER, this.overFavBt, false, 0, true);
                    this.m.plusButton.addEventListener(MouseEvent.MOUSE_OUT, this.outFavBt, false, 0, true);
                    this.m.plusButton.addEventListener(MouseEvent.CLICK, this.clickPlus, false, 0, true);
                    this.m.removeChild(this.m.minusButton);
                }
            } else {
                this.m.removeChild(this.m.plusButton);
                this.m.removeChild(this.m.minusButton);
            }
            if (gMode == "r") {
                this.m.bg.gotoAndStop(1);
            } else if (gMode == "d") {
                this.m.bg.gotoAndStop(2);
            } else if (gMode == "e") {
                this.m.bg.gotoAndStop(3);
            } else if (gMode == "o") {
                this.m.bg.gotoAndStop(4);
            } else if (gMode == 'h') {
                this.m.bg.gotoAndStop(5);
            }
            var badHatsArr:Array = badHatsStr.split(',');
            for (var hat:int in badHatsArr) {
                if (badHatsArr[hat] > 1) {
                    this.badHats.push(badHatsArr[hat]);
                }
            }
            this.htmlNameMaker.listenForLink(this.m.authorBox);
            addChild(this.m);
            this.addSlots();
            this.testAccess();
            this.cm.defineCommand("fillSlot" + this.courseID + "_" + this.version, this.fillSlot);
            this.cm.defineCommand("confirmSlot" + this.courseID + "_" + this.version, this.confirmSlot);
            this.cm.defineCommand("clearSlot" + this.courseID + "_" + this.version, this.clearSlot);
        }

        public function testAccess()
        {
            var byMe:Boolean = Main.loggedInAs.toLowerCase() == this.userName.toLowerCase(); // logged in user is level creator

            // test password
            if (this.pass && !this.passOK && Main.group < 2 && !byMe) {
                if (this.m.accessCover.textBox.text !== 'Pass Needed') {
                    this.m.accessCover.textBox.text = "Pass Needed";
                    if (!this.m.accessCover.contains(this.m.accessCover.passButton)) {
                        this.m.accessCover.addChild(this.m.accessCover.passButton);
                    }
                    if (!this.m.accessCover.contains(this.m.accessCover.passBox)) {
                        this.m.accessCover.addChild(this.m.accessCover.passBox);
                    }
                    this.m.accessCover.passButton.addEventListener(MouseEvent.CLICK, this.clickPassEnter, false, 0, true);
                }
                return;
            } else if (!this.pass || (this.pass && this.passOK) || Main.group >= 2 || byMe) { // pass is OK or byMe, make sure all the pass-related stuff is removed
                if (this.m.accessCover.contains(this.m.accessCover.passButton)) {
                    this.m.accessCover.passButton.removeEventListener(MouseEvent.CLICK, this.clickPassEnter);
                    this.m.accessCover.removeChild(this.m.accessCover.passButton);
                }
                if (this.m.accessCover.contains(this.m.accessCover.passBox)) {
                    this.m.accessCover.removeChild(this.m.accessCover.passBox);
                }
            }

            // test rank
            this.myRank = SecureData.getNumber("userRank");
            this.myRank = isNaN(this.myRank) || this.myRank < 0 ? 0 : this.myRank;
            if (Main.group < 2 && !byMe) {
                if (this.myRank < this.minRank) {
                    this.m.accessCover.textBox.text = "Rank " + this.minRank + " Needed";
                    this.toggleCover(true);
                    return;
                } else {
                    this.toggleCover(false);
                }
            }

            // test hat
            if (this.badHats.length > 0 && this.badHats.indexOf(AccountInfo.currentHat) != -1) {
                this.m.accessCover.textBox.text = 'Hat Not Allowed';
                this.toggleCover(true);
                return;
            }

            // success! remove the accessCover
            this.toggleCover(false);
        }

        private function toggleCover(enable:Boolean)
        {
            if (enable && !this.m.contains(this.m.accessCover)) {
                this.m.addChild(this.m.accessCover);
                if (CourseMenu.instance != null) {
                    CourseMenu.instance.staticCloseMenu();
                }
            } else if (!enable && this.m.contains(this.m.accessCover)) {
                this.m.removeChild(this.m.accessCover);
            }
            this.coverActive = enable;
        }

        private function clickPassEnter(e:MouseEvent)
        {
            if (this.superLoader == null) {
                var enteredPass:String = this.m.accessCover.passBox.text;
                var hash:String = Data.hash(enteredPass + Env.LEVEL_PASS_SALT);
                this.m.accessCover.passButton.enabled = this.m.accessCover.passBox.enabled = false;
                this.m.accessCover.passBox.text = 'checking...';
                this.superLoader = new SuperLoader(true, SuperLoader.j);
                this.superLoader.addEventListener(SuperLoader.d, this.validatePassResponse, false, 0, true);
                this.superLoader.addEventListener(SuperLoader.e, this.passResponseError, false, 0, true);
                var vars:URLVariables = new URLVariables();
                vars.course_id = this.courseID;
                vars.hash = hash;
                var request:URLRequest = new URLRequest(Main.baseURL + "/level_pass_check.php");
                request.method = URLRequestMethod.POST;
                request.data = vars;
                this.superLoader.load(request);
            }
        }

        private function validatePassResponse(e:Event)
        {
            var ret:Object = this.superLoader.parsedData;
            if (ret.success == true) {
                var encryptor:Encryptor = new Encryptor();
                encryptor.setKey(Env.LEVEL_PASS_KEY);
                encryptor.setIV(Env.LEVEL_PASS_IV);
                var decryptedStr:String = encryptor.decrypt(ret.result);
                // added this after mcrypt conversion. to-do: find a real way to fix this
                if (decryptedStr.substr(1).indexOf("{") != -1) {
                    decryptedStr = decryptedStr.substring(0, decryptedStr.indexOf("}") + 1);
                }
                decryptedStr = Data.trimWhitespace(decryptedStr);
                // end post-mcrypt addition
                var obj:Object = JSON.parse(decryptedStr);
                if (obj.level_id == this.courseID && obj.access == 1) {
                    this.passOK = true;
                    this.testAccess();
                } else {
                    this.m.accessCover.passBox.text = "nope!";
                    this.m.accessCover.passButton.enabled = this.m.accessCover.passBox.enabled = true;
                }
            }
            this.superLoader.removeEventListener(SuperLoader.d, this.validatePassResponse);
            this.superLoader.removeEventListener(SuperLoader.e, this.passResponseError);
            this.superLoader.remove();
            this.superLoader = null;
        }

        private function passResponseError(e:Event)
        {
            this.m.accessCover.passBox.text = "";
            this.m.accessCover.passButton.enabled = this.m.accessCover.passBox.enabled = true;
            this.superLoader.removeEventListener(SuperLoader.d, this.validatePassResponse);
            this.superLoader.removeEventListener(SuperLoader.e, this.passResponseError);
            this.superLoader.remove();
            this.superLoader = null;
        }

        private function addSlots()
        {
            var y:Number = 0;
            var i:int = 0;
            while (i < this.maxSlots) {
                var slot:Slot = new Slot(i, this);
                slot.x = 0;
                slot.y = y;
                y = y + 16;
                this.slotArray.push(slot);
                this.m.slotsHolder.addChild(slot);
                i++;
            }
        }

        private function removeSlots()
        {
            var slot:Slot;
            var i:int = 0;
            while (i < this.maxSlots) {
                slot = this.slotArray[i];
                slot.remove();
                i++;
            }
        }

        private function clickPlus(e:MouseEvent)
        {
            if (this.uploading == null) {
                this.handleFavorite('add');
            }
        }

        private function clickMinus(e:MouseEvent)
        {
            if (this.uploading == null) {
                this.handleFavorite('remove');
            }
        }

        private function handleFavorite(mode:String)
        {
            var vars:URLVariables = new URLVariables();
            vars.mode = mode;
            vars.level_id = this.courseID;
            var request:URLRequest = new URLRequest(Main.baseURL + "/favorite_levels_modify.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.uploading = new UploadingPopup(request, SuperLoader.j, (mode == 'add' ? 'Adding to' : 'Removing from') + ' favorites...');
            this.uploading.addEventListener(SuperLoader.d, this.onFavoriteResult, false, 0, true);
        }

        private function onFavoriteResult(e:Event)
        {
            var ret:Object = this.uploading.parsedData;
            if (ret.mode === 'add') {
                Main.favoriteLevels.push(this.courseID);
                this.m.plusButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overFavBt);
                this.m.plusButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outFavBt);
                this.m.plusButton.removeEventListener(MouseEvent.CLICK, this.clickPlus);
                this.m.removeChild(this.m.plusButton);
                this.m.addChild(this.m.minusButton);
                this.m.minusButton.addEventListener(MouseEvent.MOUSE_OVER, this.overFavBt, false, 0, true);
                this.m.minusButton.addEventListener(MouseEvent.MOUSE_OUT, this.outFavBt, false, 0, true);
                this.m.minusButton.addEventListener(MouseEvent.CLICK, this.clickMinus, false, 0, true);
            } else if (ret.mode === 'remove') {
                Main.favoriteLevels.splice(Main.favoriteLevels.indexOf(this.courseID), 1);
                this.m.minusButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overFavBt);
                this.m.minusButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outFavBt);
                this.m.minusButton.removeEventListener(MouseEvent.CLICK, this.clickMinus);
                this.m.removeChild(this.m.minusButton);
                this.m.addChild(this.m.plusButton);
                this.m.plusButton.addEventListener(MouseEvent.MOUSE_OVER, this.overFavBt, false, 0, true);
                this.m.plusButton.addEventListener(MouseEvent.MOUSE_OUT, this.outFavBt, false, 0, true);
                this.m.plusButton.addEventListener(MouseEvent.CLICK, this.clickPlus, false, 0, true);
            }
            if (this.uploading != null) {
                this.uploading.removeEventListener(SuperLoader.d, this.onFavoriteResult);
                this.uploading.startFadeOut();
                this.uploading = null;
            }
        }

        private function overFavBt(e:MouseEvent)
        {
            this.favBtTimer = setTimeout(this.showFavHover, 500);
        }

        private function showFavHover()
        {
            clearTimeout(this.favBtTimer);
            var bt:DisplayObject = this.m.contains(this.m.plusButton) ? this.m.plusButton : this.m.minusButton;
            var mode:String = this.m.contains(this.m.plusButton) ? 'add' : 'remove';
            var title:String = mode === 'add' ? 'Add to Favorites' : 'Remove from Favorites';
            var msg:String = mode === 'add' ? 'Add this level to your favorites list.' : 'Remove this level from your favorites list.';
            this.favBtPopup = new HoverPopup(title, msg, bt);
        }

        private function outFavBt(e:MouseEvent)
        {
            clearTimeout(this.favBtTimer);
            if (this.favBtPopup != null) {
                this.favBtPopup.remove();
                this.favBtPopup = null;
            }
        }

        public function sendFillSlot(slotNum:int)
        {
            var pageNum:int = LevelListing.levelListing.getPageNum();
            Main.socket.write("fill_slot`" + this.courseID + "_" + this.version + "`" + slotNum + "`" + pageNum);
        }

        public function sendClearSlot()
        {
            Main.socket.write("clear_slot`");
        }

        public function sendConfirmSlot()
        {
            Main.socket.write("confirm_slot`");
        }

        // _loc2 = slotNum
        // _loc3 = name
        // _loc4 = rank
        // _loc5 = me
        // _loc6 = slot
        private function fillSlot(a:Array)
        {
            var slot:Slot;
            if (this.slotArray != null) {
                var slotNum:Number = Number(a[0]);
                slot = this.slotArray[slotNum];
            }
            if (slot != null) {
                var name:String = a[1];
                var rank:Number = Number(a[2]);
                var me:String = a[3];
                slot.fillSlot(name, rank, me);
            }
            if (me == "me") {
                Main.filledSlotCourseID = this.courseID;
                Main.filledSlotCourseVersion = this.version;
            }
        }

        private function confirmSlot(a:Array)
        {
            var slotNum:Number = Number(a[0]);
            if (this.slotArray != null) {
                var slot:Slot = this.slotArray[slotNum];
                slot.confirmSlot();
            }
        }

        private function clearSlot(a:Array)
        {
            var slotNum:Number = Number(a[0]);
            if (this.slotArray != null) {
                var slot:Slot = this.slotArray[slotNum];
                slot.clearSlot();
            }
        }

        private function overInfoHandler(e:MouseEvent)
        {
            var popupTitle:String = "-- " + Data.escapeString(this.title) + " --";
            var byText:String = "By: " + Data.escapeString(this.userName) + "<br/>";
            var versionText:String = "Version: " + Data.formatNumber(this.version) + "<br/>";
            var updatedText:String = "Updated: "  + Data.getShortDateStr(this.lastUpdated) + '<br/>';
            var minRankText:String = "Min Rank: " + this.minRank + "<br/>";
            var playsText:String = "Plays: " + Data.formatNumber(this.playCount) + "<br/>";
            var ratingText:String = "Rating: " + this.rating;
            var noteText:String = "";
            if (Data.escapeString(this.note) != "") {
                noteText = "<br/>-----<br/><i>" + Data.escapeString(this.note, true) + "</i>";
            }
            var clickText:String = "<br/>-----<br/>(click the \"?\" for more info)";
            var levelInfoText:String = byText + versionText + updatedText + minRankText + playsText + ratingText + noteText + clickText;
            this.infoPopup = new HoverPopup(popupTitle, levelInfoText, this.m.infoButton);
        }

        private function outInfoHandler(e:MouseEvent)
        {
            this.infoPopup.remove();
            this.infoPopup = null;
        }

        private function clickInfoHandler(e:MouseEvent)
        {
            new LevelInfoPopup(this.courseID);
        }

        override public function remove()
        {
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler);
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler);
            this.m.infoButton.removeEventListener(MouseEvent.CLICK, this.clickInfoHandler);
            this.m.plusButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overFavBt);
            this.m.plusButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outFavBt);
            this.m.plusButton.removeEventListener(MouseEvent.CLICK, this.clickPlus);
            this.m.minusButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overFavBt);
            this.m.minusButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outFavBt);
            this.m.minusButton.removeEventListener(MouseEvent.CLICK, this.clickMinus);
            this.removeSlots();
            this.slotArray = null;
            if (this.infoPopup != null) {
                this.infoPopup.remove();
                this.infoPopup = null;
            }
            clearTimeout(this.favBtTimer);
            if (this.favBtPopup != null) {
                this.favBtPopup.remove();
                this.favBtPopup = null;
            }
            if (this.superLoader != null) {
                this.superLoader.removeEventListener(Event.COMPLETE, this.validatePassResponse);
                this.superLoader.remove();
                this.superLoader = null;
            }
            if (this.uploading != null) {
                this.uploading.removeEventListener(SuperLoader.d, this.onFavoriteResult);
                this.uploading.remove();
                this.uploading = null;
            }
            this.htmlNameMaker.remove();
            this.htmlNameMaker = null;
            this.cm.defineCommand(("fillSlot" + this.courseID), null);
            this.cm.defineCommand(("confirmSlot" + this.courseID), null);
            this.cm.defineCommand(("clearSlot" + this.courseID), null);
            this.cm = null;
            super.remove();
        }


    }
}//package level_browser

