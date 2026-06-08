// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//page.GamePage

package page
{
    import background.*;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Settings;
    import flash.display.Sprite;
    import flash.net.URLVariables;
    import flash.display.StageQuality;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    import items.Items;
    import level_browser.CourseMenu;
    import dialogs.MessagePopup;

    public class GamePage extends Page 
    {

        public static var course:GamePage;

        private var segSize:int = 30;
        public var allowedItems:Vector.<int>; // var_86
        public var badHats:Vector.<int>;
        public var var_14:Sprite = new Sprite();
        protected var color:Number = 12303325; //0;
        protected var var_133:Array = new Array();
        protected var zoom:Number = 1; // var_233
        public var scale:Number = 1;
        public var credits:Array = new Array();
        public var levelID:Number;
        public var updatedTime:Number;
        public var title:String = "";
        public var note:String = "";
        public var song:String = "";
        public var gravity:String = "1";
        public var maxTime:String = "120"; // var_378
        public var gameMode:String = "race";
        public var cowboyChance:String = "5";
        private var accel:Number = 10;
        private var friction:Number = 0.6;
        private var velX:Number = 0;
        private var velY:Number = 0;
        public var posX:Number = -20000;
        public var posY:Number = -20000;
        public var var_239:int = 60000;
        public var var_362:int = 60000;
        public var drawing:Boolean = false;
        protected var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
        private var rasterStopNotified:Boolean = false;

        public function GamePage()
        {
        }

        override public function initialize()
        {
            GamePage.course = this;
            x = 550 / 2;
            y = 400 / 2;
            addChild(this.var_14);
            Main.stage.focus = Main.stage;
            super.initialize();
            this.setItems("all");
            this.setBadHats('');
            if (CourseMenu.instance != null) {
                CourseMenu.instance.staticCloseMenu(); // should never be needed, but just in case
            }
        }

        protected function attachBackgrounds()
        {
        }

        protected function removeBackgrounds()
        {
        }

        public function setPos(_arg_1:Number, _arg_2:Number)
        {
        }

        public function setColor(_arg_1:Number=0)
        {
            this.color = _arg_1;
        }

        public function getColor():int
        {
            return this.color;
        }

        public function setSaveString(_arg_1:String)
        {
        }

        public function startDrawing(_arg_1:Background)
        {
            var _local_2:int = this.var_133.indexOf(_arg_1);
            if (_local_2 == -1) {
                this.var_133.push(_arg_1);
            }
            this.drawing = true;
        }

        public function finishDrawing(_arg_1:Background)
        {
            var _local_2:int = this.var_133.indexOf(_arg_1);
            if (_arg_1 is DrawableBackground && _arg_1.stoppedRasterizing && !this.rasterStopNotified) {
                new MessagePopup('Error: Some art didn\'t load correctly. Don\'t worry! You can still play the level.\n\nYou can prevent this in the future by enabling lossless art quality in the options menu.');
                this.rasterStopNotified = true;
            }
            if (_local_2 != -1) {
                this.var_133.splice(_local_2, 1);
            }
            if (this.var_133.length <= 0) {
                this.drawing = false;
            }
        }

        public function goodToDraw(_arg_1:Background):Boolean
        {
            return this.var_133[0] == _arg_1 || this.var_133.length <= 0;
        }

        public function getCredits():String
        {
            return this.credits.join("`");
        }

        public function setCredits(_arg_1:String)
        {
            _arg_1 = _arg_1 == null ? '' : _arg_1;
            this.credits = _arg_1.split("`");
        }

        public function setGravity(_arg_1:String)
        {
            this.gravity = _arg_1;
        }

        public function setMaxTime(s:String)
        {
            var t:String = s;
            if (t == 999 && this.updatedTime < 1358640000) {
                t = '0';
            }
            this.maxTime = s;
        }

        public function setSong(_arg_1:String)
        {
            this.song = _arg_1;
        }

        public function setGameMode(mode:String)
        {
            this.gameMode = mode === 'eggs' ? 'egg' : mode;
        }

        // _loc2 = perc
        public function setCowboyChance(chance:String)
        {
            var perc:int = 5;
            if (chance != null && chance != "") {
                perc = parseInt(chance);
                perc = Data.numLimit(perc, 0, 100);
            }
            chance = perc.toString();
            this.cowboyChance = chance;
        }

        // _loc2 = items
        // _loc3 = i
        // _loc5 = itemName
        // _loc6 = itemCode
        // removed _loc4 (itemsArr.length), _loc7 (Items.getAllCodes().length)
        public function setItems(itemsStr:String)
        {
            if (itemsStr == "") {
                this.allowedItems = new Vector.<int>();
            } else if (itemsStr == "all" || itemsStr == null) {
                this.allowedItems = Items.getAllCodes();
            } else {
                this.allowedItems = new Vector.<int>();
                var itemsArr:Array = itemsStr.split("`");
                for (var i = 0; i < itemsArr.length; i++) {
                    var itemName:String = itemsArr[i];
                    var itemCode:int;
                    if (itemName.length > 1) {
                        itemCode = Items.getCodeFromName(itemName);
                    } else {
                        itemCode = Number(itemName);
                    }
                    if (!isNaN(itemCode) && itemCode >= 1 && itemCode <= Items.getAllCodes().length) {
                        this.allowedItems.push(itemCode);
                    }
                }
            }
        }

        public function setBadHats(hatsStr:String)
        {
            this.badHats = new Vector.<int>();
            if (hatsStr == "" || hatsStr == null) {
                return; // no need to continue if no hats are excluded
            }

            var hatsArr:Array = hatsStr.split(",");
            for (var i = 0; i < hatsArr.length; i++) { // loop through and add hat ids to badHats array
                var hatCode:int = Number(hatsArr[i]);
                if (!isNaN(hatCode) && hatCode > 1 && hatCode <= Parts.getPartArray('HAT').length + 1) {
                    this.badHats.push(hatCode);
                }
            }
        }

        public function setVariables(vars:URLVariables)
        {
            this.updatedTime = vars.time is Array ? vars.time[0] : vars.time;
            this.setCredits(vars.credits);
            this.setSaveString(this.decodeLevelData(vars.data));
            this.title = vars.title;
            this.note = vars.note;
            this.setSong(vars.song);
            this.setGameMode(vars.gameMode == null ? 'race' : vars.gameMode);
            this.setCowboyChance(vars.cowboyChance);
            var _local_2:String = vars.gravity;
            var _local_3:Number = Number(_local_2);
            if (isNaN(_local_3)) {
                _local_3 = 0;
            }
            _local_3 = Data.numLimit(_local_3, -99, 99);
            _local_2 = String(_local_3);
            if (_local_2.indexOf(".") == -1) {
                _local_2 = (_local_2 + ".0");
            }
            this.setGravity(_local_2);
            var _local_4:String = vars.max_time;
            var _local_5:Number = Number(_local_4);
            _local_5 = Data.numLimit(_local_5, 0, 9999);
            _local_4 = String(_local_5);
            this.setMaxTime(_local_4);
            this.setItems(vars.items);
            this.setBadHats(vars.badHats);
            this.levelID = vars.level_id;
        }

        // _loc2 = allowedParams
        // _loc3 = "and"
        // _loc4 = ret
        // _loc5 = lDataSecs (level data sections)
        // _loc6 = passedParam
        // _loc7 = allowed
        // _loc8 = lDataSec
        // _loc9 = allowedParam
        // _loc10 = andStr
        // _arg_1 = levelData
        public function validateSaveString(levelData:String):String
        {
            var allowedParams:Array = new Array("credits=", "data=", "title=", "note=", "song=", "gravity=", "max_time=", "items=", "level_id=", "live=", "time=", "min_level=", "level_id=", "has_pass=", "gameMode=", "version=", "user_id=", "cowboyChance=", "badHats=");
            var ret:* = "";
            levelData = levelData.replace(/&/g, 'and');
            var lDataSecs:Array = levelData.split("and");
            for each (var lDataSec:String in lDataSecs) {
                var allowed:Boolean = false;
                for each (var allowedParam:String in allowedParams) {
                    var passedParam:String = lDataSec.substr(0, allowedParam.length);
                    if (passedParam == allowedParam) {
                        allowed = true;
                        break;
                    }
                }
                var andStr:String = "and";
                if (allowed) {
                    andStr = "&";
                }
                if (ret == "") {
                    andStr = "";
                }
                ret += andStr + lDataSec;
            }
            return ret;
        }

        // _loc2 = levelData
        // _loc3 = readMode
        // deleted _loc4 (decimal value of bg color hex)
        // deleted _loc5 (decoded string -- levelData.join('`'))
        protected function decodeLevelData(rawlevelData:String):String
        {
            var levelData:Array = rawlevelData.split("`");
            var readMode:String = levelData[0];
            if (readMode == "m1" || readMode == "m2" || readMode == "m3" || readMode == 'm4') {
                levelData.splice(0, 1);
                levelData[0] = Number("0x" + levelData[0]); // background color in decimal (_loc2[0] is in hex, typecast to number)
                if (readMode == "m1") {
                    levelData[1] = this.decodeObjectString(levelData[1]);
                    levelData[2] = this.decodeObjectString(levelData[2]);
                    levelData[3] = this.decodeObjectString(levelData[3]);
                    levelData[4] = this.decodeObjectString(levelData[4]);
                } else if (readMode == "m2" || readMode == "m3" || readMode == 'm4') {
                    if (readMode == "m2") {
                        levelData[1] = this.decodeObjectString2(levelData[1]); // blocks
                    } else if (readMode == 'm3') {
                        levelData[1] = this.decodeObjectString2(levelData[1], this.segSize); // blocks
                    } else {
                        levelData[1] = this.decodeBlockString(levelData[1]);
                    }
                    levelData[2] = this.decodeObjectString2(levelData[2]); // art1
                    levelData[3] = this.decodeObjectString2(levelData[3]); // art2
                    levelData[4] = this.decodeObjectString2(levelData[4]); // art3
                    levelData[9] = this.decodeObjectString2(levelData[9]); // art0
                    levelData[10] = this.decodeObjectString2(levelData[10]); // art00
                }
                return levelData.join("`");
            }
            return rawlevelData;
        }

        // _loc2 = dataArr
        // _loc3 = thisObj
        // _loc6 = i
        // _loc7 = dataArr.length
        // deleted _loc8 (unused)
        // deleted _loc14 (combined w/ return)
        private function decodeObjectString(objectString:String):String
        {
            var dataArr:Array = objectString.split(",");
            var thisObj:Array = dataArr.shift().split(";"); // ?
            var _local_4:Number = Number("0x" + thisObj[0]);
            var _local_5:Number = Number("0x" + thisObj[1]);
            var i:int = 0;
            while (i < dataArr.length) {
                thisObj = dataArr[i].split(";");
                var _local_13:int = Number("0x" + thisObj[0]);
                var _local_9:Number = Number("0x" + thisObj[1]) + _local_4;
                var _local_10:Number = Number("0x" + thisObj[2]) + _local_5;
                dataArr[i] = "o" + _local_13 + ";" + _local_9 + ";" + _local_10;
                if (thisObj[3] != null) {
                    var _local_11:Number = Number("0x" + thisObj[3]) / 100;
                    var _local_12:Number = Number("0x" + thisObj[4]) / 100;
                    dataArr[i] = dataArr[i] + ";" + _local_11 + ";" + _local_12;
                }
                i++;
            }
            return dataArr.join(",");
        }

        // _loc3 = dataArr
        // _loc4 = thisObj
        // _loc5 = decoded
        // _loc6 = i
        // deleted _loc7 (dataArr.length)
        // deleted _loc8 (unused?)
        // _loc9 = objCode
        // _loc10 = currentX
        // _loc11 = currentY
        // _loc12 = relX
        // _loc13 = relY
        // _loc14 = widthPerc
        // _loc15 = heightPerc
        // _loc16 = textContent
        // _loc17 = textColor
        private function decodeObjectString2(objectString:String, segMult:int = 1):String
        {
            var widthPerc:Number, heightPerc:Number;
            var dataArr:Array = objectString == null || objectString == "" ? new Array() : objectString.split(",");
            var decoded:String;
            var objectCode:int, currentX:int = 0, currentY:int = 0;
            if (dataArr.length > 0) {
                var i:int = 0;
                while (i < dataArr.length) {
                    widthPerc = heightPerc = 0;
                    var thisObj:Array = dataArr[i].split(";");
                    var relX:int = Number(thisObj[0]); // x relative to the last block (how far to travel horizontally to the next block)
                    var relY:int = Number(thisObj[1]); // y relative to the last block (how far to travel vertically to the next block)
                    currentX = currentX + relX; // updates x "pointer" to the relative position
                    currentY = currentY + relY; // updates y "pointer" to the relative position
                    if (thisObj[2] == "t") { // process text
                        var textContent:String = thisObj[3]; // text value
                        var textColor:int = thisObj[4]; // textColor in decimal?
                        widthPerc = thisObj[5]; // width % modifier
                        heightPerc = thisObj[6]; // height % modifier
                        dataArr[i] = "u" + textContent + ";" + currentX + ";" + currentY + ";" + textColor + ";" + widthPerc + ";" + heightPerc;
                    } else { // process other objects
                        if (thisObj[4] != null) { // resizable objects (new object code used)
                            objectCode = int(thisObj[2]);
                            widthPerc = Number(thisObj[3]) / 100;
                            heightPerc = Number(thisObj[4]) / 100;
                        } else if (thisObj[3] != null) { // takes the prev object code (didn't change)
                            widthPerc = Number(thisObj[2]) / 100;
                            heightPerc = Number(thisObj[3]) / 100;
                        } else if (thisObj[2] != null) { // blocks (new object code used)
                            objectCode = int(thisObj[2]);
                        }
                        dataArr[i] = "o" + objectCode + ";" + (currentX * segMult) + ";" + (currentY * segMult);
                        if (widthPerc != 0 && heightPerc != 0) {
                            dataArr[i] += ";" + widthPerc + ";" + heightPerc;
                        }
                    }
                    i++;
                }
                decoded = dataArr.join(",");
            }
            return decoded;
        }

        private function decodeBlockString(blockString:String)
        {
            var dataArr:Array = blockString == null || blockString == "" ? new Array() : blockString.split(",");
            var decoded:String;
            var blockCode:int, currentX:int = 0, currentY:int = 0;
            if (dataArr.length > 0) {
                var i:int = 0;
                while (i < dataArr.length) {
                    var thisBlock:Array = dataArr[i].split(";");
                    var relX:int = Number(thisBlock[0]); // x relative to the last block (how far to travel horizontally to the next block)
                    var relY:int = Number(thisBlock[1]); // y relative to the last block (how far to travel vertically to the next block)
                    currentX = currentX + relX; // updates x "pointer" to the relative position
                    currentY = currentY + relY; // updates y "pointer" to the relative position
                    if (thisBlock[2] != null) { // new block
                        blockCode = int(thisBlock[2]);
                    }
                    var options:String = '';
                    if (thisBlock[3] != null) { // block options
                        options = ';' + thisBlock[3];
                    }
                    dataArr[i] = "o" + blockCode + ";" + (currentX * this.segSize) + ";" + (currentY * this.segSize) + options;
                    i++;
                }
                decoded = dataArr.join(',');
            }
            return decoded;
        }

        protected function glideToScale(_arg_1:Event)
        {
            Main.stage.quality = StageQuality.LOW;
            this.scale = this.scale + (this.zoom - this.scale) * 0.3;
            if (Math.abs(this.scale - this.zoom) <= 0.001) {
                this.finishGlide();
            }
            scaleX = scaleY = this.scale;
        }

        protected function finishGlide()
        {
            Main.stage.quality = StageQuality.HIGH;
            this.scale = this.zoom;
            removeEventListener(Event.ENTER_FRAME, this.glideToScale);
        }

        public function setZoom(z:Number)
        {
            if (this.zoom != z) {
                removeEventListener(Event.ENTER_FRAME, this.glideToScale);
                addEventListener(Event.ENTER_FRAME, this.glideToScale);
                this.zoom = z;
            }
        }

        protected function keyScroll(e:Event)
        {
            if (!(Main.stage.focus is TextField)) {
                this.accel = Keys.isPressed(Keyboard.SHIFT) ? 20 : 10;
                if (Keys.isPressed(Keyboard.DOWN) || Keys.isPressed(this.altCtrl.down)) {
                    this.velY = this.velY - this.accel;
                }
                if (Keys.isPressed(Keyboard.UP) || Keys.isPressed(this.altCtrl.up)) {
                    this.velY = this.velY + this.accel;
                }
                if (Keys.isPressed(Keyboard.LEFT) || Keys.isPressed(this.altCtrl.left)) {
                    this.velX = this.velX + this.accel;
                }
                if (Keys.isPressed(Keyboard.RIGHT) || Keys.isPressed(this.altCtrl.right)) {
                    this.velX = this.velX - this.accel;
                }
                this.velX = this.velX * this.friction;
                this.velY = this.velY * this.friction;
                this.posX = this.posX + this.velX * 1 / scaleX;
                this.posY = this.posY + this.velY * 1 / scaleY;
            }
            this.setPos(this.posX, this.posY);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.glideToScale);
            this.removeBackgrounds();
            super.remove();
            GamePage.course = null;
        }


    }
}//package page

