// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_6.Course = package_6.class_30

package package_6
{
	import background.class_10;
    import background.EffectBackground;
    import background.Background;
    import background.DrawableBackground;
    import background.Map;
    import blocks.FinishBlock;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Settings;
    import flash.display.Sprite;
    import flash.display.StageQuality;
    import flash.errors.Error;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.net.URLVariables;
    import package_8.Character;
    import package_8.LocalCharacter;
    import package_9.Egg;
    import page.GamePage;
    import sounds.SoundEffects;

    public class Course extends GamePage 
    {

        public static var course:Course;

        protected var courseID:int;
        protected var version:int;
        public var startPosArray:Array = new Array(); // var_197
        public var finishBlocks:Array = new Array(); // var_313
        public var playerArray:Array = new Array(); // var_40
        public var var_9:LocalCharacter;
        protected var holder:Sprite = new Sprite();
        public var timer:CourseTimer;
        protected var miniMap:MiniMap = new MiniMap();
        protected var itemDisplay:ItemDisplay = new ItemDisplay();
        public var chatBox:RaceChat; // var_305
        public var musicSelection:MusicSelection = new MusicSelection();
        protected var countdown:CountdownGraphic; // var_61
        protected var hearts:Hearts; // var_60
        protected var bg:class_10;
        public var bg1:DrawableBackground;
        protected var bg2:DrawableBackground;
        protected var bg3:DrawableBackground;
        protected var bg4:DrawableBackground;
        protected var bg5:DrawableBackground;
        public var blockBackground:Map;
        public var effectBackground:EffectBackground; // var_201
        public var frontBackground:Background;
        public var backBackground:Background;
        protected var var_689:Number = 0;
        protected var var_678:Number = 0;
        private var rotateDirection:String; // var_348
        private var varsSet:Boolean = false; // var_545
        public var countdownFinished:Boolean = false; // var_649
        protected var playerDone:Boolean = false; // Game.var_370 -- this is either finished or forfeited
        public var looseHats:Array = [];

        public function Course()
        {
            FinishBlock.var_228 = 0;
        }

        override public function initialize()
        {
            super.initialize();
            Course.course = this;
            addChild(this.holder);
            this.timer = new CourseTimer(this);
            this.timer.x = 215;
            this.timer.y = -198;
            this.timer.mouseChildren = this.timer.mouseEnabled = false;
            this.holder.addChild(this.timer);
            this.miniMap.x = -195;
            this.miniMap.y = -198;
            this.miniMap.mouseChildren = this.miniMap.mouseEnabled = false;
            this.holder.addChild(this.miniMap);
            this.itemDisplay.x = -273;
            this.itemDisplay.y = -198;
            this.itemDisplay.mouseChildren = this.itemDisplay.mouseEnabled = false;
            this.holder.addChild(this.itemDisplay);
            this.musicSelection.x = -71;
            this.musicSelection.y = 162;
            this.holder.addChild(this.musicSelection);
            this.hearts = new Hearts();
            this.hearts.x = 465 - 225;
            this.hearts.y = 45 - 200;
            this.hearts.visible = false;
            this.hearts.mouseChildren = this.hearts.mouseEnabled = false;
            this.holder.addChild(this.hearts);
            Main.stage.focus = Main.stage;
            addEventListener(Event.ENTER_FRAME, this.method_85);
            CommandHandler.commandHandler.defineCommand("beginRace", this.beginRace);
            this.attachBackgrounds();
        }

        // method_514 = addStartPos
        public function addStartPos(startNum:int, startPt:Point)
        {
            this.startPosArray[startNum] = startPt;
            this.method_80();
        }

        // _loc1 = this.playerArray.length
        // _loc2 = tempId
        // _loc3 = startPos
        // _loc4 = player
        protected function method_80()
        {
            var tempId:int;
            while (tempId < this.playerArray.length) {
                var startPos:Point = this.getStartPos(tempId);
                if (startPos != null) {
                    var player:Character = this.playerArray[tempId];
                    player.setPos(startPos.x, startPos.y);
                    this.frontBackground.addChild(player);
                }
                tempId++;
            }
        }

        // deleted _loc2 (startNum)
        // method_753 = getStartPos
        private function getStartPos(startNum:int):Point
        {
            var _local_3:Point;
            if (Main.server.tournament == 1) {
                startNum = 0;
            }
            if (this.startPosArray[startNum] != null) {
                _local_3 = this.startPosArray[startNum];
            }
            return _local_3;
        }

        public function setEggSeed(arr:Array)
        {
            Egg.method_333(int(arr[0]));
        }

        public function addEggs(arr:Array)
        {
            if (this.gameMode == "egg") {
                var _local_2:int = arr[0];
                while (_local_2 > 0) {
                    new Egg();
                    _local_2--;
                }
            }
        }

        public function collectEgg(_arg_1:int)
        {
        }

        public function setLife(_arg_1:int)
        {
            if (this.gameMode == "deathmatch") {
                this.hearts.visible = true;
                this.hearts.method_798(_arg_1);
            }
        }

        public function method_842():int
        {
            return this.hearts.method_758();
        }

        override public function setGameMode(mode:String)
        {
            mode = mode === 'eggs' ? 'egg' : mode;
            super.setGameMode(mode);
            if (mode == "deathmatch") {
                this.setLife(3);
            }
        }

        // method_206 = getCourseID
        public function getCourseID():int
        {
            return this.courseID;
        }

        protected function method_85(e:Event)
        {
            keyScroll(e);
            if (this.varsSet && var_133.length <= 0) {
                this.endIntro();
            }
        }

        protected function endIntro()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_85);
            addEventListener(Event.ENTER_FRAME, keyScroll);
        }

        protected function method_82(e:Event)
        {
            if (this.var_9 != null) {
                var _local_2:Number = -this.var_9.x;
                var _local_3:Number = -this.var_9.y + 45;
                var _local_4:Number = _local_2 - posX;
                var _local_5:Number = _local_3 - posY;
                posX += _local_4 * 0.5;
                posY += _local_5 * 0.4;
                this.setPos(posX, posY);
            }
        }

        public function beginRace(_arg_1:Array)
        {
            removeEventListener(Event.ENTER_FRAME, this.method_85);
            if (!this.playerDone) {
                removeEventListener(Event.ENTER_FRAME, keyScroll);
                addEventListener(Event.ENTER_FRAME, this.method_82);
            }
            setZoom(1);
            this.timer.init();
            this.countdown = new CountdownGraphic();
            this.countdown.addEventListener("count", this.onCountdownCount, false, 0, true);
            this.countdown.addEventListener("finish", this.onCountdownFinish, false, 0, true);
            addChild(this.countdown);
            var startPos:Object = this.var_9.getPos(); // this fixes hat attack when quitting during the countdown
            Main.socket.write('exact_pos`' + startPos.x + '`' + startPos.y);
            if (this.var_9 != null && this.var_9.var_4.getBool(Character.JUMP_START)) {
                this.var_9.init();
            }
        }

        // method_369 = onCountdownCount
        private function onCountdownCount(_arg_1:Event)
        {
            SoundEffects.playSound(new ReadySound(), 0.4 * (Settings.soundLevel / 100));
        }

        protected function onCountdownFinish(_arg_1:Event)
        {
            SoundEffects.playSound(new GoSound(), 0.5 * (Settings.soundLevel / 100));
            if (this.var_9 != null) {
                this.var_9.init();
            }
            this.blockBackground.method_578();
            this.countdownFinished = true;
        }

        override public function setVariables(v:URLVariables)
        {
            this.varsSet = true;
            super.setVariables(v);
        }

        override public function setMaxTime(s:String)
        {
            if (s == 999 && this.updatedTime < 1358640000) {
                s = '0'; // if before infinite time motley monday and time is 999, make infinite
            }
            super.setMaxTime(s);
            this.timer.setTime(Number(s));
        }

        override public function setGravity(s:String)
        {
            var newGrav:Number = Number(s);
            super.setGravity(newGrav);
            if (this.var_9 != null) {
                this.var_9.setGravity(newGrav);
            }
        }

        override protected function attachBackgrounds()
        {
            this.bg = new class_10(this);
            this.bg1 = new DrawableBackground(this);
            this.bg2 = new DrawableBackground(this);
            this.bg3 = new DrawableBackground(this);
            this.bg4 = new DrawableBackground(this);
            this.bg5 = new DrawableBackground(this);
            this.backBackground = new Background(this);
            this.blockBackground = new Map(this.miniMap, this);
            this.frontBackground = new Background(this);
            this.effectBackground = new EffectBackground(this);
            this.bg1.setScale(1);
            this.bg2.setScale(0.5);
            this.bg3.setScale(0.25);
            this.bg4.setScale(1);
            this.bg5.setScale(2);
            var_14.addChild(this.bg);
            var_14.addChild(this.bg3);
            var_14.addChild(this.bg2);
            var_14.addChild(this.bg1);
            var_14.addChild(this.backBackground);
            var_14.addChild(this.blockBackground);
            var_14.addChild(this.frontBackground);
            var_14.addChild(this.effectBackground);
            var_14.addChild(this.bg4);
            var_14.addChild(this.bg5);
            this.setColor(12303325);
        }

        override protected function removeBackgrounds()
        {
            this.bg.remove();
            this.bg1.remove();
            this.bg2.remove();
            this.bg3.remove();
            this.bg4.remove();
            this.bg5.remove();
            this.blockBackground.remove();
            this.effectBackground.remove();
            this.frontBackground.remove();
            this.backBackground.remove();
            this.bg = null;
            this.bg1 = null;
            this.bg2 = null;
            this.bg3 = null;
            this.bg4 = null;
            this.bg5 = null;
            this.blockBackground = null;
            this.effectBackground = null;
            this.frontBackground = null;
            this.backBackground = null;
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            this.bg1.setPos(_arg_1, _arg_2);
            this.bg2.setPos(_arg_1, _arg_2);
            this.bg3.setPos(_arg_1, _arg_2);
            this.bg4.setPos(_arg_1, _arg_2);
            this.bg5.setPos(_arg_1, _arg_2);
            this.blockBackground.setPos(_arg_1, _arg_2);
            this.effectBackground.setPos(_arg_1, _arg_2);
            this.frontBackground.setPos(_arg_1, _arg_2);
            this.backBackground.setPos(_arg_1, _arg_2);
        }

        override public function setColor(_arg_1:Number=0)
        {
            this.bg.setColor(_arg_1);
            this.bg1.setColor(_arg_1);
            this.bg2.setColor(_arg_1);
            this.bg3.setColor(_arg_1);
            this.bg4.setColor(_arg_1);
            this.bg5.setColor(_arg_1);
            this.blockBackground.setColor(_arg_1);
            this.effectBackground.setColor(_arg_1);
            this.frontBackground.setColor(_arg_1);
            this.backBackground.setColor(_arg_1);
        }

        // _loc2 = arr
        override public function setSaveString(s:String)
        {
            var arr:Array = s.split("`");
            this.setColor(Number(arr[0]));
            this.blockBackground.setSaveString(arr[1]);
            this.bg1.setSaveString(arr[5] + "," + arr[2], false);
            this.bg2.setSaveString(arr[6] + "," + arr[3], false);
            this.bg3.setSaveString(arr[7] + "," + arr[4], false);
            this.bg4.setSaveString(arr[11] + "," + arr[9], false);
            this.bg5.setSaveString(arr[12] + "," + arr[10], false);
            this.bg.setSaveString(arr[8], false);
        }

        override public function setSong(_arg_1:String)
        {
            super.setSong(_arg_1);
            this.musicSelection.setSong(_arg_1);
        }

        override protected function glideToScale(e:Event)
        {
            super.glideToScale(e);
            this.bg.scaleX = this.bg.scaleY = this.holder.scaleX = this.holder.scaleY = 1 / scale;
        }

        // method_654
        public function startRotate(s:String)
        {
            this.rotateDirection = s;
            addEventListener(Event.ENTER_FRAME, this.rotate);
            this.bg1.method_86();
            this.bg2.method_86();
            this.bg3.method_86();
            this.bg4.method_86();
            this.bg5.method_86();
            Main.stage.quality = StageQuality.LOW;
        }

        // _loc2 = rotateDone
        // _loc4 = player
        private function rotate(e:Event)
        {
            var rotateDone:Boolean;
            var _local_3:Number = 3;
            if (this.rotateDirection == "right") {
                rotation += _local_3;
                rotateDone = rotation >= 90;
            } else {
                rotation -= _local_3;
                rotateDone = rotation <= -90;
            }
            if (rotateDone) {
                rotation = 0;
                this.bg.rotation = 0;
                this.bg1.method_74();
                this.bg2.method_74();
                this.bg3.method_74();
                this.bg4.method_74();
                this.bg5.method_74();
                Main.stage.quality = StageQuality.HIGH;
                if (this.rotateDirection == "right") {
                    this.blockBackground.rotation = this.bg1.rotation = this.bg2.rotation = this.bg3.rotation = this.bg4.rotation = this.bg5.rotation = this.bg5.rotation + 90;
                    this.miniMap.rotate(this.blockBackground.rotation);
                } else {
                    this.blockBackground.rotation = this.bg1.rotation = this.bg2.rotation = this.bg3.rotation = this.bg4.rotation = this.bg5.rotation = this.bg5.rotation - 90;
                    this.miniMap.rotate(this.blockBackground.rotation);
                }
                for each (var player:Character in this.playerArray) {
                    player.rotate(this.rotateDirection);
                }
                this.method_82(new Event(Event.ENTER_FRAME));
                removeEventListener(Event.ENTER_FRAME, this.rotate);
            }
            this.bg.rotation = this.holder.rotation = -rotation;
            if (this.var_9 != null) {
                this.var_9.method_483(-rotation);
            }
        }

        public function outOfTimeHandler()
        {
        }

        public function finish(_arg_1:int=-1, _arg_2:int=0, _arg_3:int=0)
        {
        }

        // _loc1 = player
        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("beginRace", null);
            removeEventListener(Event.ENTER_FRAME, this.method_85);
            removeEventListener(Event.ENTER_FRAME, this.rotate);
            removeEventListener(Event.ENTER_FRAME, this.method_82);
            if (this.timer != null) {
                this.timer.remove();
                this.timer = null;
            }
            if (this.countdown != null) {
                this.countdown.removeEventListener("count", this.onCountdownCount);
                this.countdown.removeEventListener("finish", this.onCountdownFinish);
                if (this.countdown.parent != null) {
                    this.countdown.parent.removeChild(this.countdown);
                }
                this.countdown.stop();
                this.countdown = null;
            }
            this.musicSelection.remove();
            this.musicSelection = null;
            this.miniMap.remove();
            this.miniMap = null;
            this.hearts.remove();
            this.hearts = null;
            this.itemDisplay = null;
            Course.course = null;
            for each (var player:Character in this.playerArray) {
                player.remove();
            }
            this.playerArray = null;
            this.startPosArray = null;
            super.remove();
        }


    }
}
