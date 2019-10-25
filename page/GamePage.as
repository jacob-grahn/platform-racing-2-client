// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//page.GamePage

package page
{
    import data.Settings;
    import flash.display.Sprite;
    import background.class_75;
    import items.Items;
    import flash.net.URLVariables;
    import flash.display.StageQuality;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.ui.Keyboard;
    import background.*;

    public class GamePage extends Page 
    {

        public static var course:GamePage;

        public var var_86:Vector.<int>;
        public var var_14:Sprite = new Sprite();
        protected var color:Number = 0;
        protected var var_133:Array = new Array();
        protected var var_233:Number = 1;
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
        private var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);

        public function GamePage()
        {
        }

        override public function initialize()
        {
            GamePage.course = this;
            x = (550 / 2);
            y = (400 / 2);
            addChild(this.var_14);
            Main.stage.focus = Main.stage;
            super.initialize();
            this.method_96("all");
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

        // method_12 = getColor
        public function getColor():int
        {
            return this.color;
        }

        public function setSaveString(_arg_1:String)
        {
        }

        public function startDrawing(_arg_1:class_75)
        {
            var _local_2:int = this.var_133.indexOf(_arg_1);
            if (_local_2 == -1) {
                this.var_133.push(_arg_1);
            }
            this.drawing = true;
        }

        public function finishDrawing(_arg_1:class_75)
        {
            var _local_2:int = this.var_133.indexOf(_arg_1);
            if (_local_2 != -1) {
                this.var_133.splice(_local_2, 1);
            }
            if (this.var_133.length <= 0) {
                this.drawing = false;
            }
        }

        public function goodToDraw(_arg_1:class_75):Boolean
        {
            var _local_2:Boolean;
            if (this.var_133[0] == _arg_1 || this.var_133.length <= 0) {
                _local_2 = true;
            }
            return _local_2;
        }

        public function method_403():String
        {
            return this.credits.join("`");
        }

        public function method_828(_arg_1:String)
        {
            if (_arg_1 == null) {
                _arg_1 = "";
            }
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

        public function setCowboyChance(_arg_1:String)
        {
            var _local_2:int;
            if (_arg_1 == null || _arg_1 == "") {
                _local_2 = 5;
            } else {
                _local_2 = parseInt(_arg_1);
                _local_2 = class_74.numLimit(_local_2, 0, 100);
            }
            _arg_1 = _local_2.toString();
            this.cowboyChance = _arg_1;
        }

        public function method_96(_arg_1:String)
        {
            var _local_2:Array;
            var _local_3:int;
            var _local_4:int;
            var _local_5:String;
            var _local_6:int;
            var _local_7:int;
            if (_arg_1 == "") {
                this.var_86 = new Vector.<int>();
            } else if (_arg_1 == "all" || _arg_1 == null) {
                this.var_86 = Items.method_188();
            } else {
                this.var_86 = new Vector.<int>();
                _local_2 = _arg_1.split("`");
                _local_4 = _local_2.length;
                _local_7 = Items.method_188().length;
                _local_3 = 0;
                while (_local_3 < _local_4) {
                    _local_5 = _local_2[_local_3];
                    if (_local_5.length > 1) {
                        _local_6 = Items.getCodeFromName(_local_5);
                    } else {
                        _local_6 = Number(_local_5);
                    }
                    if (!isNaN(_local_6) && _local_6 >= 1 && _local_6 <= _local_7) {
                        this.var_86.push(_local_6);
                    }
                    _local_3++;
                }
            }
        }

        public function setVariables(vars:URLVariables)
        {
            this.updatedTime = vars.time is Array ? vars.time[0] : vars.time;
            this.method_828(vars.credits);
            this.setSaveString(this.method_645(vars.data));
            this.title = vars.title;
            this.note = vars.note;
            this.setSong(vars.song);
            if (vars.gameMode == null) {
                vars.gameMode = "race";
            }
            this.setGameMode(vars.gameMode);
            this.setCowboyChance(vars.cowboyChance);
            var _local_2:String = vars.gravity;
            var _local_3:Number = Number(_local_2);
            if (isNaN(_local_3)) {
                _local_3 = 0;
            }
            _local_3 = class_74.numLimit(_local_3, -99, 99);
            _local_2 = String(_local_3);
            if (_local_2.indexOf(".") == -1) {
                _local_2 = (_local_2 + ".0");
            }
            this.setGravity(_local_2);
            var _local_4:String = vars.max_time;
            var _local_5:Number = Number(_local_4);
            _local_5 = class_74.numLimit(_local_5, 0, 9999);
            _local_4 = String(_local_5);
            this.setMaxTime(_local_4);
            this.method_96(vars.items);
            this.levelID = vars.level_id;
        }

        public function method_158(_arg_1:String):String
        {
            var _local_6:String;
            var _local_7:Boolean;
            var _local_8:String;
            var _local_9:String;
            var _local_10:String;
            var _local_2:Array = new Array("credits=", "data=", "title=", "note=", "song=", "gravity=", "max_time=", "items=", "level_id=", "live=", "time=", "min_level=", "level_id=", "has_pass=", "gameMode=", "version=", "user_id=", "cowboyChance=");
            var _local_3:* = "and";
            var _local_4:* = "";
            _arg_1 = _arg_1.replace(/&/g, _local_3);
            var _local_5:Array = _arg_1.split("and");
            for each (_local_8 in _local_5) {
                _local_7 = false;
                for each (_local_9 in _local_2) {
                    _local_6 = _local_8.substr(0, _local_9.length);
                    if (_local_6 == _local_9) {
                        _local_7 = true;
                        break;
                    }
                }
                _local_10 = "and";
                if (_local_7) {
                    _local_10 = "&";
                }
                if (_local_4 == "") {
                    _local_10 = "";
                }
                _local_4 = _local_4 + _local_10 + _local_8;
            }
            return _local_4;
        }

        protected function method_645(_arg_1:String):String
        {
            var _local_4:Number;
            var _local_5:String;
            var _local_2:Array = _arg_1.split("`");
            var _local_3:String = _local_2[0];
            if (_local_3 == "m1" || _local_3 == "m2" || _local_3 == "m3") {
                _local_2.splice(0, 1);
                _local_4 = Number("0x" + _local_2[0]);
                _local_2[0] = _local_4;
                if (_local_3 == "m1") {
                    _local_2[1] = this.method_137(_local_2[1]);
                    _local_2[2] = this.method_137(_local_2[2]);
                    _local_2[3] = this.method_137(_local_2[3]);
                    _local_2[4] = this.method_137(_local_2[4]);
                }
                if (_local_3 == "m2" || _local_3 == "m3") {
                    if (_local_3 == "m2") {
                        _local_2[1] = this.decodeObjectString2(_local_2[1]);
                    } else {
                        _local_2[1] = this.decodeObjectString2(_local_2[1], 30);
                    }
                    _local_2[2] = this.decodeObjectString2(_local_2[2]);
                    _local_2[3] = this.decodeObjectString2(_local_2[3]);
                    _local_2[4] = this.decodeObjectString2(_local_2[4]);
                    _local_2[9] = this.decodeObjectString2(_local_2[9]);
                    _local_2[10] = this.decodeObjectString2(_local_2[10]);
                }
                _local_5 = _local_2.join("`");
                return _local_5;
            }
            return _arg_1;
        }

        private function method_137(_arg_1:String):String
        {
            var _local_6:int;
            var _local_8:String;
            var _local_9:Number;
            var _local_10:Number;
            var _local_11:Number;
            var _local_12:Number;
            var _local_13:int;
            var _local_2:Array = _arg_1.split(",");
            var _local_3:Array = _local_2.shift().split(";");
            var _local_4:Number = Number("0x" + _local_3[0]);
            var _local_5:Number = Number("0x" + _local_3[1]);
            var _local_7:int = _local_2.length;
            _local_6 = 0;
            while (_local_6 < _local_7) {
                _local_3 = _local_2[_local_6].split(";");
                _local_13 = Number("0x" + _local_3[0]);
                _local_9 = Number("0x" + _local_3[1]) + _local_4;
                _local_10 = Number("0x" + _local_3[2]) + _local_5;
                _local_2[_local_6] = "o" + _local_13 + ";" + _local_9 + ";" + _local_10;
                if (_local_3[3] != null) {
                    _local_11 = Number("0x" + _local_3[3]) / 100;
                    _local_12 = Number("0x" + _local_3[4]) / 100;
                    _local_2[_local_6] = _local_2[_local_6] + ";" + _local_11 + ";" + _local_12;
                }
                _local_6++;
            }
            var _local_14:String = _local_2.join(",");
            return _local_14;
        }

        private function decodeObjectString2(_arg_1:String, _arg_2:int=1):String
        {
            var _local_3:Array;
            var _local_4:Array;
            var _local_5:String;
            var _local_6:int;
            var _local_8:String;
            var _local_14:Number;
            var _local_15:Number;
            var _local_16:String;
            var _local_17:int;
            if (_arg_1 == null || _arg_1 == "") {
                _local_3 = new Array();
            } else {
                _local_3 = _arg_1.split(",");
            }
            var _local_7:int = _local_3.length;
            var _local_9:int;
            var _local_10:int;
            var _local_11:int;
            var _local_12:int;
            var _local_13:int;
            if (_local_7 > 0) {
                _local_6 = 0;
                while (_local_6 < _local_7) {
                    _local_14 = _local_15 = 0;
                    _local_4 = _local_3[_local_6].split(";");
                    _local_12 = Number(_local_4[0]);
                    _local_13 = Number(_local_4[1]);
                    _local_10 = _local_10 + _local_12;
                    _local_11 = _local_11 + _local_13;
                    if (_local_4[2] == "t") {
                        _local_16 = _local_4[3];
                        _local_17 = _local_4[4];
                        _local_14 = _local_4[5];
                        _local_15 = _local_4[6];
                        _local_3[_local_6] = "u" + _local_16 + ";" + _local_10 + ";" + _local_11 + ";" + _local_17 + ";" + _local_14 + ";" + _local_15;
                    } else {
                        if (_local_4[4] != null) {
                            _local_9 = int(_local_4[2]);
                            _local_14 = Number(_local_4[3]) / 100;
                            _local_15 = Number(_local_4[4]) / 100;
                        } else {
                            if (_local_4[3] != null) {
                                _local_14 = Number(_local_4[2]) / 100;
                                _local_15 = Number(_local_4[3]) / 100;
                            } else {
                                if (_local_4[2] != null) {
                                    _local_9 = int(_local_4[2]);
                                }
                            }
                        }
                        _local_3[_local_6] = "o" + _local_9 + ";" + (_local_10 * _arg_2) + ";" + (_local_11 * _arg_2);
                        if (_local_14 != 0 && _local_15 != 0) {
                            _local_3[_local_6] = _local_3[_local_6] + ";" + _local_14 + ";" + _local_15;
                        }
                    }
                    _local_6++;
                }
                _local_5 = _local_3.join(",");
            }
            return _local_5;
        }

        protected function glideToScale(_arg_1:Event)
        {
            Main.stage.quality = StageQuality.LOW;
            this.scale = this.scale + (this.var_233 - this.scale) * 0.3;
            if (Math.abs(this.scale - this.var_233) <= 0.001) {
                this.finishGlide();
            }
            scaleX = scaleY = this.scale;
        }

        protected function finishGlide()
        {
            Main.stage.quality = StageQuality.HIGH;
            this.scale = this.var_233;
            removeEventListener(Event.ENTER_FRAME, this.glideToScale);
        }

        public function setZoom(_arg_1:Number)
        {
            if (this.var_233 != _arg_1) {
                removeEventListener(Event.ENTER_FRAME, this.glideToScale);
                addEventListener(Event.ENTER_FRAME, this.glideToScale);
                this.var_233 = _arg_1;
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

