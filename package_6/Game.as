//package_6.Game = package_6.class_31

package package_6
{
    import com.adobe.crypto.MD5;
    import data.CommandHandler;
    import data.Settings;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import sounds.SoundEffects;
    import package_4.MessagePopup;
    import package_8.Character;
    import package_8.RemoteCharacter;
    import package_8.LocalCharacter;
    import package_9.Egg;

    public class Game extends Course 
    {

        private var superLoader:SuperLoader = new SuperLoader(false);
        private var quitButton:QuitButton; // var_285
        private var chatBox:RaceChat; // chatBox = var_305
        private var cm:CommandHandler = CommandHandler.commandHandler;
        protected var drawingInfo:DrawingInfo; // var_125
        private var prizePop:PrizePopup; // var_198
        private var luxPop:LuxPopup; // var_350
        private var levelHash:String = ""; // var_579
        private var placeArtifact:PlaceArtifact; // var_436
        private var var_634:Array = new Array();
        private var var_370:Boolean = false;
        public var var_202:FinishedPage;
        public var var_463:Array = new Array();
        public var var_452:int;
        public var var_465:int;
        public var var_347:int;

        public function Game(id:int, v:int)
        {
            this.courseID = id;
            this.version = v;
            this.quitButton = new QuitButton(this);
            this.placeArtifact = new PlaceArtifact(Main.stage);
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
            this.cm.defineCommand("winPrize", this.winPrize);
            this.cm.defineCommand("cowboyMode", this.cowboyMode);
            this.cm.defineCommand("happyHour", this.happyHour);
            this.cm.defineCommand("setEggSeed", setEggSeed);
            this.cm.defineCommand("addEggs", addEggs);
            this.cm.defineCommand("superBooster", this.superBooster);
            super.initialize();
            this.getLevelData();
        }

        override protected function onCountdownFinish(e:Event)
        {
            if (this.prizePop != null) {
                this.prizePop.startFadeOut();
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
                levelData = method_158(levelData);
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
            var prize:Object = JSON.parse(arr[0]);
            this.prizePop = new PrizePopup(prize.type, prize.id, prize.name, prize.desc, prize.universal, false);
        }

        // _loc3 = prize
        public function winPrize(arr:Array)
        {
            var prize:Object = JSON.parse(arr[0]);
            this.prizePop = new PrizePopup(prize.type, prize.id, prize.name, prize.desc, prize.universal, true);
            if (Main.instance.kongAPI != null && prize.type == "hat") {
                Main.instance.kongAPI.stats.submit(prize.name, 1);
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

        private function superBooster(arr:Array)
        {
            var _local_2:int = int(arr[0]);
            var _local_3:Character = playerArray[_local_2];
            _local_3.method_576();
        }

        private function createRemoteCharacter(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:String = _arg_1[1];
            var _local_4:Number = Number(_arg_1[2]);
            var _local_5:Number = Number(_arg_1[3]);
            var _local_6:Number = Number(_arg_1[4]);
            var _local_7:Number = Number(_arg_1[5]);
            var _local_8:Number = Number(_arg_1[6]);
            var _local_9:Number = Number(_arg_1[7]);
            var _local_10:Number = Number(_arg_1[8]);
            var _local_11:Number = Number(_arg_1[9]);
            var _local_12:Number = Number(_arg_1[10]);
            var _local_13:Number = Number(_arg_1[11]);
            var _local_14:Number = Number(_arg_1[12]);
            var _local_15:Number = Number(_arg_1[13]);
            var _local_16:RemoteCharacter = new RemoteCharacter(_local_2, miniMap.getDot(), _local_3, _local_8, _local_9, _local_10, _local_11);
            _local_16.setColors(_local_4, _local_12, _local_5, _local_13, _local_6, _local_14, _local_7, _local_15);
            playerArray[_local_2] = _local_16;
            this.drawingInfo.method_138(_local_3, _local_2);
            method_80();
        }

        private function createLocalCharacter(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:Number = _arg_1[1];
            var _local_4:Number = _arg_1[2];
            var _local_5:Number = _arg_1[3];
            var _local_6:Number = Number(_arg_1[4]);
            var _local_7:Number = Number(_arg_1[5]);
            var _local_8:Number = Number(_arg_1[6]);
            var _local_9:Number = Number(_arg_1[7]);
            var _local_10:Number = Number(_arg_1[8]);
            var _local_11:Number = Number(_arg_1[9]);
            var _local_12:Number = Number(_arg_1[10]);
            var _local_13:Number = Number(_arg_1[11]);
            var _local_14:Number = Number(_arg_1[12]);
            var _local_15:Number = Number(_arg_1[13]);
            var _local_16:Number = Number(_arg_1[14]);
            var _local_17:Number = Number(_arg_1[15]);
            var _local_18:LocalCharacter = new LocalCharacter(_local_2, this, blockBackground, miniMap.getDot(), itemDisplay, Number(gravity), _local_3, _local_4, _local_5, _local_10, _local_11, _local_12, _local_13);
            _local_18.setColors(_local_6, _local_14, _local_7, _local_15, _local_8, _local_16, _local_9, _local_17);
            playerArray[_local_2] = _local_18;
            this.drawingInfo.method_138(Main.loggedInAs, _local_2);
            var_9 = _local_18;
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

        override protected function endIntro()
        {
            var _local_1:String = this.method_742();
            var _local_2:int = var_313.length;
            Main.socket.write("finish_drawing`" + this.levelHash + "`" + this.gameMode + "`" + _local_1 + "`" + _local_2 + "`" + cowboyChance);
            super.endIntro();
        }

        private function method_742():String
        {
            var _local_1:String;
            if (var_313.length > 5) {
                _local_1 = "all";
            } else {
                _local_1 = JSON.stringify(var_313);
            }
            return (_local_1);
        }

        override public function outOfTimeHandler()
        {
            if (this.gameMode == Modes.egg) {
                this.finish();
                this.method_196();
            } else {
                this.quitGame();
            }
        }

        override public function finish(finishId:int=-1, finishX:int=0, finishY:int=0)
        {
            if (!this.var_370) {
                if (this.gameMode == Modes.obj) {
                    if (finishId != -1) {
                        miniMap.removeFinish(finishX, finishY);
                        Main.socket.write("objective_reached`" + finishId + "`" + finishX + "`" + finishY);
                    }
                } else {
                    Main.socket.write("finish_race`" + finishId + "`" + finishX + "`" + finishY);
                    this.quitButton.startGlow();
                    this.method_185();
                    this.method_682();
                    timer.pause();
                }
                SoundEffects.playSound(new VictorySound(), 1 * (Settings.soundLevel / 100));
            }
        }

        // method_209 = quitGame
        public function quitGame()
        {
            if (!this.var_370) {
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
            if (!this.var_370) {
                this.var_370 = true;
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
            return this.var_370;
        }

        override public function remove()
        {
            this.cm.defineCommand("createRemoteCharacter", null);
            this.cm.defineCommand("createLocalCharacter", null);
            this.cm.defineCommand("award", null);
            this.cm.defineCommand("setExpGain", null);
            this.cm.defineCommand("setLuxGain", null);
            this.cm.defineCommand("setPrize", null);
            this.cm.defineCommand("winPrize", null);
            this.cm.defineCommand("cowboyMode", null);
            this.cm.defineCommand("setEggSeed", null);
            this.cm.defineCommand("addEggs", null);
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
            if (this.prizePop != null) {
                this.prizePop.remove();
                this.prizePop = null;
            }
            if (this.luxPop != null) {
                this.luxPop.remove();
                this.luxPop = null;
            }
            this.quitButton.remove();
            this.chatBox.remove();
            this.placeArtifact.remove();
            this.placeArtifact = null;
            super.remove();
        }


    }
}
