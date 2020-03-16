// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_22.LevelItem = package_22.class_284

package package_22
{
    import data.class_28;
    import data.class_33;
    import data.CommandHandler;
    import data.Encryptor;
    import data.HTMLNameMaker;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import package_4.HoverPopup;
    import package_4.ConfirmPopup;
    import package_4.UploadingPopup;
    import ui.PageNavigation;

    public class LevelItem extends Removable 
    {

        private static var unlocked:Boolean = false; // var_332

        private var m:LevelItemGraphic = new LevelItemGraphic();
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var infoPopup:HoverPopup;
        private var slotArray:Array = new Array(); // var_127
        public var courseID:int;
        public var version:int;
        private var title:String;
        private var rating:Number;
        private var playCount:Number;
        private var minRank:Number;
        private var note:String;
        private var userName:String;
        private var group:Number;
        private var pass:Boolean;
        private var type:String;
        private var lastUpdated:Date;
        private var maxSlots:Number = 4; // var_590
        private var superLoader:SuperLoader; // var_80
        private var uploading:UploadingPopup;

        // _loc12 = htmlName
        // _loc13 = myRank
        public function LevelItem(id:int, v:int, t:String, r:Number, plays:int, rank:int, desc:String, uName:String, uGroup:Number, hasPass:Boolean, gMode:String, time:int)
        {
            this.courseID = id;
            this.version = v;
            this.title = t;
            this.rating = r;
            this.playCount = plays;
            this.minRank = rank;
            this.note = desc;
            this.userName = uName;
            this.group = uGroup;
            this.pass = hasPass;
            this.type = gMode;
            this.lastUpdated = new Date(time * 1000);
            this.minRank = class_74.numLimit(this.minRank, 0, 99);
            var htmlName:String = this.htmlNameMaker.makeName(uName, uGroup);
            this.m.titleBox.text = this.title;
            this.m.authorBox.htmlText = "by " + htmlName;
            this.m.ratingStars.bar.scaleX = this.rating / 5;
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler, false, 0, true);
            this.m.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler, false, 0, true);
            if (Main.group >= 2 && Main.isTrialMod == false) {
                this.m.deleteButton.addEventListener(MouseEvent.CLICK, this.clickDelete, false, 0, true);
            } else {
                this.m.removeChild(this.m.deleteButton);
            }
            if (gMode == "r") {
                this.m.bg.gotoAndStop(1);
            } else if (gMode == "d") {
                this.m.bg.gotoAndStop(2);
            } else if (gMode == "e") {
                this.m.bg.gotoAndStop(3);
            } else if (gMode == "o") {
                this.m.bg.gotoAndStop(4);
            }
            this.htmlNameMaker.listenForLink(this.m.authorBox);
            addChild(this.m);
            this.addSlots();
            var myRank:Number = class_33.getNumber("userRank");
            if (isNaN(myRank) || myRank < 0) {
                myRank = 0;
            }
            if (hasPass && Main.group < 2) {
                this.m.accessCover.textBox.text = "Pass Needed";
                this.m.accessCover.passButton.addEventListener(MouseEvent.CLICK, this.clickPassEnter, false, 0, true);
            } else if (myRank < this.minRank && !LevelItem.unlocked && Main.group < 2) {
                this.m.accessCover.textBox.text = "Rank " + this.minRank + " Needed";
                this.m.accessCover.removeChild(this.m.accessCover.passButton);
                this.m.accessCover.removeChild(this.m.accessCover.passBox);
                if (this.m.accessCover.textBox.text == "Rank 0 Needed") {
                    this.m.removeChild(this.m.accessCover);
                    LevelItem.unlocked = true;
                }
            } else {
                this.m.removeChild(this.m.accessCover);
            }
            this.cm.defineCommand("fillSlot" + this.courseID + "_" + this.version, this.fillSlot);
            this.cm.defineCommand("confirmSlot" + this.courseID + "_" + this.version, this.confirmSlot);
            this.cm.defineCommand("clearSlot" + this.courseID + "_" + this.version, this.clearSlot);
        }

        // _loc2 = enteredPass
        // _loc3 = hash
        // _loc4 = request
        // method_681 = clickPassEnter
        private function clickPassEnter(e:MouseEvent)
        {
            if (this.superLoader == null) {
                var enteredPass:String = this.m.accessCover.passBox.text;
                var hash:String = class_28.hash(enteredPass + Env.LEVEL_PASS_SALT);
                this.superLoader = new SuperLoader(true, SuperLoader.j);
                this.superLoader.addEventListener(Event.COMPLETE, this.validateResponse, false, 0, true);
                var vars:URLVariables = new URLVariables();
                vars.course_id = this.courseID;
                vars.hash = hash;
                var request:URLRequest = new URLRequest(Main.baseURL + "/level_pass_check.php");
                request.method = URLRequestMethod.POST;
                request.data = vars;
                this.superLoader.load(request);
            }
        }

        // _loc2 = ret
        // _loc3 = encryptor
        // _loc4 = decryptedStr
        // method_198 = validateResponse
        private function validateResponse(e:Event)
        {
            var ret:Object = this.superLoader.parsedData;
            if (ret.success == true) {
                var encryptor:Encryptor = new Encryptor();
                encryptor.setKey(Env.LEVEL_PASS_KEY);
                encryptor.setIV(Env.LEVEL_PASS_IV);
                var decryptedStr:String = encryptor.decrypt(ret.result);
                var obj:Object = JSON.parse(decryptedStr);
                if (obj.level_id == this.courseID && obj.access == 1) {
                    this.m.removeChild(this.m.accessCover);
                    this.m.accessCover.passButton.removeEventListener(MouseEvent.CLICK, this.clickPassEnter);
                } else {
                    this.m.accessCover.passBox.text = "nope!";
                }
            }
            this.superLoader.removeEventListener(Event.COMPLETE, this.validateResponse);
            this.superLoader.remove();
            this.superLoader = null;
        }

        // deleted _loc1 (x remains the same at 0px)
        // _loc2 = y
        // deleted _loc3 (height incremental increase remains the same at 16px)
        // _loc4 = slot
        // _loc5 = i
        // method_535 = addSlots
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

        // _loc1 = slot
        // _loc2 = i
        // method_826 = removeSlots
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

        private function clickDelete(e:MouseEvent)
        {
            new ConfirmPopup(this.deleteLevel, "Are you sure you want to remove this level?");
        }

        // _loc1 = vars
        // _loc2 = request
        // method_816 = deleteLevel
        public function deleteLevel()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.courseID;
            var request:URLRequest = new URLRequest(Main.baseURL + "/remove_level.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            new UploadingPopup(request, 'json');
        }

        // method_618 = sendFillSlot
        public function sendFillSlot(slotNum:int)
        {
            var pageNum:int = LevelListing.levelListing.getPageNum();
            Main.socket.write("fill_slot`" + this.courseID + "_" + this.version + "`" + slotNum + "`" + pageNum);
        }

        // method_180 = sendClearSlot
        public function sendClearSlot()
        {
            Main.socket.write("clear_slot`");
        }

        // method_178 = sendConfirmSlot
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
                Main.var_583 = this.courseID;
                Main.var_514 = this.version;
            }
        }

        private function confirmSlot(_arg_1:Array)
        {
            var _local_3:Slot;
            var _local_2:Number = Number(_arg_1[0]);
            if (this.slotArray != null) {
                _local_3 = this.slotArray[_local_2];
                _local_3.confirmSlot();
            }
        }

        private function clearSlot(_arg_1:Array)
        {
            var _local_3:Slot;
            var _local_2:Number = Number(_arg_1[0]);
            if (this.slotArray != null) {
                _local_3 = this.slotArray[_local_2];
                _local_3.clearSlot();
            }
        }

        private function overInfoHandler(e:MouseEvent)
        {
            var popupTitle:String = "-- " + class_28.escapeString(this.title) + " --";
            var byText:String = "By: " + class_28.escapeString(this.userName) + "<br/>";
            var versionText:String = "Version: " + this.version + "<br/>";
            var minRankText:String = "Min Rank: " + this.minRank + "<br/>";
            var playsText:String = "Plays: " + this.playCount + "<br/>";
            var ratingText:String = "Rating: " + this.rating + "<br/>";
            var updatedText:String = "Updated: "  + this.lastUpdated.date + '/' + class_28.getMonthStr(this.lastUpdated.month) + '/' + this.lastUpdated.fullYear;
            var noteText:String = "";
            if (class_28.escapeString(this.note) != "") {
                noteText = "<br/>-----<br/>" + class_28.escapeString(this.note, true);
            }
            var levelInfoText:String = byText + versionText + minRankText + playsText + ratingText + updatedText + noteText;
            this.infoPopup = new HoverPopup(popupTitle, levelInfoText, this.m.infoButton);
        }

        private function outInfoHandler(e:MouseEvent)
        {
            this.infoPopup.remove();
            this.infoPopup = null;
        }

        // ?
        /*private function method_847()
        {
        }*/

        override public function remove()
        {
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overInfoHandler);
            this.m.infoButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outInfoHandler);
            if (this.m.deleteButton != null) {
                this.m.deleteButton.removeEventListener(MouseEvent.CLICK, this.clickDelete);
            }
            this.removeSlots();
            this.slotArray = null;
            if (this.infoPopup != null) {
                this.infoPopup.remove();
            }
            if (this.superLoader != null) {
                this.superLoader.removeEventListener(Event.COMPLETE, this.validateResponse);
                this.superLoader.remove();
                this.superLoader = null;
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
}//package package_22

