//package_6.Game = package_6.class_31

package package_6
{
    import com.adobe.crypto.MD5;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import sounds.SoundEffects;
    import package_4.MessagePopup;
    import package_8.Character;
    import package_8.RemoteCharacter;
    import package_8.LocalCharacter;
    import package_9.Egg;
    import package_9.Hat;

    public class Game extends Course 
    {

        private var superLoader:SuperLoader = new SuperLoader(false);
        private var quitButton:QuitButton; // var_285
        // moved chatBox to Course and changed visibility from private -> public (var_305)
        private var cm:CommandHandler = CommandHandler.commandHandler;
        protected var drawingInfo:DrawingInfo; // var_125
        public var prize:Object;
        //private var prizePop:PrizePopup; // var_198 REMOVED AFTER PrizePopup GOT A STATIC SELF REFERENCE
        private var luxPop:LuxPopup; // var_350
        private var levelHash:String = ""; // var_579
        private var specialEvent:SpecialEvent; // var_436, then placeArtifact, then SpecialEvent
        private var var_634:Array = new Array();
        public var var_202:FinishedPage;
        public var var_463:Array = new Array();
        public var var_452:int;
        public var var_465:int;
        public var var_347:int;
        private var hatCountdown:uint;

        public function Game(id:int, v:int)
        {
            this.courseID = id;
            this.version = v;
            this.quitButton = new QuitButton(this);
            this.specialEvent = new SpecialEvent(Main.stage, this);
            Egg.method_333(0);
        }

        override public function initialize()
        {
            this.chatBox = new RaceChat();
            this.chatBox.x = -271;
            this.chatBox.y = 49;
            holder.addChild(this.chatBox);
            this.drawingInfo = new DrawingInfo();
            this.drawingInfo.x = -273;
            this.drawingInfo.y = -104;
            holder.addChild(this.drawingInfo);
            holder.addChild(this.quitButton);
            this.cm.defineCommand("createRemoteCharacter", this.createRemoteCharacter);
            this.cm.defineCommand("createLocalCharacter", this.createLocalCharacter);
            this.cm.defineCommand("award", this.award);
            this.cm.defineCommand("setExpGain", this.setExpGain);
            this.cm.defineCommand("setLuxGain", this.setLuxGain);
            this.cm.defineCommand("setPrize", this.setPrize);
            this.cm.defineCommand('cancelPrize', this.cancelPrize);
            this.cm.defineCommand("winPrize", this.winPrize);
            this.cm.defineCommand("cowboyMode", this.cowboyMode);
            this.cm.defineCommand("happyHour", this.happyHour);
            this.cm.defineCommand("setEggSeed", setEggSeed);
            this.cm.defineCommand("addEggs", addEggs);
            this.cm.defineCommand("superBooster", this.superBooster);
            this.cm.defineCommand('maybeReturnHatToStart', this.maybeReturnHatToStart);
            this.cm.defineCommand("startHatCountdown", this.startHatCountdown);
            this.cm.defineCommand('forceQuit', this.quitGame);
            super.initialize();
            this.getLevelData();
        }

        override protected function onCountdownFinish(e:Event)
        {
            if (PrizePopup.instance != null) {
                PrizePopup.instance.startFadeOut();
            }
            super.onCountdownFinish(e);
        }

        // method_647 = getLevelData
        private function getLevelData()
        {
            var URLReq:URLRequest = new URLRequest(Main.levelsURL + "/" + courseID + ".txt?version=" + version);
            this.superLoader.addEventListener(Event.COMPLETE, this.loadHandler, false, 0, true);
            this.superLoader.load(URLReq);
        }

        // _loc2 = levelTxt
        // _loc3 = hashPos
        // _loc4 = levelHash
        // _loc5 = levelData
        // _loc7 = gameHash
        private function loadHandler(e:Event)
        {
            this.superLoader.removeEventListener(Event.COMPLETE, this.loadHandler);
            var levelTxt:String = e.target.data;
            var hashPos:int = levelTxt.length - 32;
            var levelHash:String = levelTxt.substr(hashPos);
            var levelData:String = levelTxt.substr(0, hashPos);
            var gameHash:String = MD5.hash(version.toString() + courseID.toString() + levelData + Env.LEVEL_SALT_2);
            if (gameHash != levelHash) {
                new MessagePopup("Error: The course did not download correctly.");
            } else if (levelData == "") {
                new MessagePopup("Error: The course did not load.");
            } else {
                this.superLoader.remove();
                this.superLoader = null;
                levelData = validateSaveString(levelData);
                this.levelHash = MD5.hash(levelData + courseID + version + Env.LEVEL_HASH_SALT);
                var raceVars:URLVariables = new URLVariables(levelData);
                setVariables(raceVars);
            }
        }

        override public function beginRace(_arg_1:Array)
        {
            this.drawingInfo.clear();
            super.beginRace(_arg_1);
        }

        public function award(_arg_1:Array)
        {
            this.var_463.push(_arg_1);
            if (this.var_202 != null) {
                this.var_202.award(_arg_1);
            }
        }

        public function setExpGain(_arg_1:Array)
        {
            this.var_452 = int(_arg_1[0]);
            this.var_465 = int(_arg_1[1]);
            this.var_347 = int(_arg_1[2]);
            this.finish();
            this.method_196();
            if (this.var_202 != null) {
                this.var_202.setExpGain(this.var_452, this.var_465, this.var_347);
            }
        }

        public function setLuxGain(arr:Array)
        {
            this.luxPop = new LuxPopup(int(arr[0]));
        }

        // _loc3 = prize
        public function setPrize(arr:Array)
        {
            this.prize = JSON.parse(arr[0]);
            new PrizePopup(this.prize.type, this.prize.id, this.prize.name, this.prize.desc, this.prize.universal, false);
        }

        public function cancelPrize(arr:Array)
        {
            this.prize = null;
            new PrizePopup('cancel', 0, 'Prize Cancelled', arr[0]);
        }

        // _loc3 = prize
        public function winPrize(arr:Array)
        {
            this.prize = JSON.parse(arr[0]);
            new PrizePopup(this.prize.type, this.prize.id, this.prize.name, this.prize.desc, this.prize.universal, true);
            if (Main.instance.kongAPI != null && this.prize.type == "hat") {
                Main.instance.kongAPI.stats.submit(this.prize.name, 1);
            }
        }

        public function cowboyMode(a:Array)
        {
            addChild(new CowboyMode());
        }

        public function happyHour(a:Array)
        {
            addChild(new HappyHour());
        }

        // _loc2 = tempId
        // _loc3 = c
        private function superBooster(arr:Array)
        {
            var tempId:int = int(arr[0]);
            var c:Character = playerArray[tempId];
            c.method_576();
        }

        private function maybeReturnHatToStart(a:Array)
        {
            var hat:Hat = looseHats[int(a[0])];
            if (hat != null) {
                var hatPos:Point = hat.getPos();
                var hatRot:int = hat.getRot();
                hatPos = Data.method_9(hatPos.x, hatPos.y, hatRot);
                if ((hatPos.y > blockBackground.maxY + 500 && hatRot == 0) || (hatPos.y < blockBackground.minY - 500 && Math.abs(hatRot) == 180) || (hatPos.x > blockBackground.maxX + 500 && hatRot == 90) || (hatPos.x < blockBackground.minX - 500 && hatRot == -90)) {
                    this.returnHatToStart(hat);
                }
            }
        }

        private function returnHatToStart(hat:Hat)
        {
            var info:Object = hat.getInfo();
            hat.remove();
            if (info.id < startPosArray.length) {
                new Hat(startPosArray[info.id].x, startPosArray[info.id].y, 0, info.num, info.color, info.color2, info.id);
            }
        }

        private function startHatCountdown(a:Array = null)
        {
            this.cm.defineCommand('cancelHatCountdown', this.cancelHatCountdown);
            this.hatCountdown = setInterval(this.checkHatCountdown, 1000);
        }

        private function checkHatCountdown()
        {
            Main.socket.write('check_hat_countdown`');
        }

        private function cancelHatCountdown(a:Array = null)
        {
            this.cm.defineCommand('cancelHatCountdown', null);
            clearInterval(this.hatCountdown);
        }

        // _loc2 = tempId
        // _loc3 = userName
        // _loc4 = hatColor
        // _loc5 = headColor
        // _loc6 = bodyColor
        // _loc7 = feetColor
        // _loc8 = hatId
        // _loc9 = headId
        // _loc10 = bodyId
        // _loc11 = feetId
        // _loc12 = hatColor2
        // _loc13 = headColor2
        // _loc14 = bodyColor2
        // _loc15 = feetColor2
        // _loc16 = c
        private function createRemoteCharacter(a:Array)
        {
            var tempId:int = int(a[0]);
            var userName:String = a[1];
            var hatColor:Number = Number(a[2]);
            var headColor:Number = Number(a[3]);
            var bodyColor:Number = Number(a[4]);
            var feetColor:Number = Number(a[5]);
            var hatId:Number = Number(a[6]);
            var headId:Number = Number(a[7]);
            var bodyId:Number = Number(a[8]);
            var feetId:Number = Number(a[9]);
            var hatColor2:Number = Number(a[10]);
            var headColor2:Number = Number(a[11]);
            var bodyColor2:Number = Number(a[12]);
            var feetColor2:Number = Number(a[13]);
            var c:RemoteCharacter = new RemoteCharacter(tempId, miniMap.getDot(), userName, hatId, headId, bodyId, feetId);
            c.setColors(hatColor, hatColor2, headColor, headColor2, bodyColor, bodyColor2, feetColor, feetColor2);
            playerArray[tempId] = c;
            this.drawingInfo.method_138(userName, tempId);
            method_80();
        }

        // _loc2 = tempId
        // _loc3 = userName
        // _loc4 = speed
        // _loc5 = accel
        // _loc6 = jumpn
        // _loc6 = hatColor
        // _loc7 = headColor
        // _loc8 = bodyColor
        // _loc9 = feetColor
        // _loc10 = hatId
        // _loc11 = headId
        // _loc12 = bodyId
        // _loc13 = feetId
        // _loc14 = hatColor2
        // _loc15 = headColor2
        // _loc16 = bodyColor2
        // _loc17 = feetColor2
        // _loc18 = c
        private function createLocalCharacter(a:Array)
        {
            var tempId:int = int(a[0]);
            var speed:Number = a[1];
            var accel:Number = a[2];
            var jumpn:Number = a[3];
            var hatColor:Number = Number(a[4]);
            var headColor:Number = Number(a[5]);
            var bodyColor:Number = Number(a[6]);
            var feetColor:Number = Number(a[7]);
            var hatId:Number = Number(a[8]);
            var headId:Number = Number(a[9]);
            var bodyId:Number = Number(a[10]);
            var feetId:Number = Number(a[11]);
            var hatColor2:Number = Number(a[12]);
            var headColor2:Number = Number(a[13]);
            var bodyColor2:Number = Number(a[14]);
            var feetColor2:Number = Number(a[15]);
            var c:LocalCharacter = new LocalCharacter(tempId, this, blockBackground, miniMap.getDot(), itemDisplay, Number(gravity), speed, accel, jumpn, hatId, headId, bodyId, feetId);
            c.setColors(hatColor, hatColor2, headColor, headColor2, bodyColor, bodyColor2, feetColor, feetColor2);
            playerArray[tempId] = c;
            this.drawingInfo.method_138(Main.loggedInAs, tempId);
            var_9 = c;
            method_80();
        }

        override public function collectEgg(_arg_1:int)
        {
            if (this.gameMode == "egg") {
                Main.socket.write("grab_egg`" + _arg_1);
            }
        }

        public function method_196()
        {
            if (this.var_202 == null) {
                this.method_185();
                this.quitButton.stopGlow();
                this.var_202 = new FinishedPage(this);
            }
        }

        // deleted _loc1 (this.getFinishPositions())
        // deleted _loc2 (finishBlocks.length)
        override protected function endIntro()
        {
            Main.socket.write("finish_drawing`" + this.levelHash + "`" + this.gameMode + "`" + this.getFinishBlockPositions() + "`" + finishBlocks.length + "`" + cowboyChance + "`" + badHats.join(','));
            super.endIntro();
        }

        // deleted _loc1 (condensed fn)
        // method_742 = getFinishBlockPositions
        private function getFinishBlockPositions():String
        {
            return finishBlocks.length > 5 ? 'all' : JSON.stringify(finishBlocks);
        }

        override public function outOfTimeHandler()
        {
            this.cancelHatCountdown();
            if (this.gameMode == Modes.egg) {
                this.finish();
                this.method_196();
            } else {
                this.quitGame();
            }
        }

        override public function finish(finishId:int=-1, finishX:int=0, finishY:int=0)
        {
            if (!playerDone) {
                if (this.gameMode == Modes.obj) {
                    if (finishId != -1) {
                        miniMap.removeFinish(finishX, finishY);
                        Main.socket.write("objective_reached`" + finishId + "`" + finishX + "`" + finishY);
                    }
                } else {
                    Main.socket.write("finish_race`" + finishId + "`" + finishX + "`" + finishY);
                    if (this.gameMode != Modes.hat) {
                        this.quitButton.startGlow();
                        this.method_185();
                        this.method_682();
                        timer.pause();
                    }
                }
                SoundEffects.playSound(new VictorySound(), 1 * (Settings.soundLevel / 100));
            }
        }

        // method_209 = quitGame
        public function quitGame(arr:Array = null)
        {
            if (!playerDone) {
                if (this.gameMode == Modes.dm) {
                    this.finish();
                } else {
                    Main.socket.write("quit_race`");
                }
            }
            this.method_185();
            this.method_196();
        }

        private function method_682()
        {
            var _local_1:int;
            var _local_2:int;
            if (var_9 != null) {
                _local_1 = 1;
                while (_local_1 <= 4) {
                    if (var_9["hat" + _local_1] <= 1) {
                        break;
                    }
                    _local_1++;
                }
                _local_2 = _local_1 - 1;
                if (Main.instance.kongAPI != null) {
                    Main.instance.kongAPI.stats.submit("Hat Finish", _local_2);
                }
            }
        }

        private function method_185()
        {
            if (!playerDone) {
                playerDone = true;
                if (var_9 != null) {
                    var_9.beginRemove();
                }
                removeEventListener(Event.ENTER_FRAME, method_82);
                addEventListener(Event.ENTER_FRAME, keyScroll, false, 0, true);
                Main.stage.focus = Main.stage;
            }
        }

        public function isDonePlaying() : Boolean
        {
            return playerDone;
        }

        override public function remove()
        {
            this.cm.defineCommand("createRemoteCharacter", null);
            this.cm.defineCommand("createLocalCharacter", null);
            this.cm.defineCommand("award", null);
            this.cm.defineCommand("setExpGain", null);
            this.cm.defineCommand("setLuxGain", null);
            this.cm.defineCommand("setPrize", null);
            this.cm.defineCommand('cancelPrize', null);
            this.cm.defineCommand("winPrize", null);
            this.cm.defineCommand("cowboyMode", null);
            this.cm.defineCommand("setEggSeed", null);
            this.cm.defineCommand("addEggs", null);
            this.cm.defineCommand("superBooster", null);
            this.cm.defineCommand('maybeReturnHatToStart', null);
            this.cm.defineCommand('startHatCountdown', null); // this.cancelHatCountdown called farther down
            this.cm.defineCommand('forceQuit', null);
            removeEventListener(Event.ENTER_FRAME, method_85);
            removeEventListener(Event.ENTER_FRAME, method_82);
            removeEventListener(Event.ENTER_FRAME, keyScroll);
            if (this.drawingInfo != null) {
                this.drawingInfo.remove();
                this.drawingInfo = null;
            }
            if (this.superLoader != null) {
                this.superLoader.removeEventListener(Event.COMPLETE, this.loadHandler);
                this.superLoader.remove();
                this.superLoader = null;
            }
            this.prize = null;
            if (PrizePopup.instance !== null) {
                PrizePopup.instance.startFadeOut();
            }
            if (PlaceArtifact.instance !== null) {
                PlaceArtifact.instance.startFadeOut();
            }
            if (this.luxPop != null) {
                this.luxPop.remove();
                this.luxPop = null;
            }
            this.quitButton.remove();
            this.chatBox.remove();
            this.specialEvent.remove();
            this.specialEvent = null;
            this.cancelHatCountdown();
            super.remove();
        }


    }
}
