// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_8.Character = package_8.class_76

package package_8
{
    import flash.media.SoundChannel;
    import flash.display.MovieClip;
    import flash.geom.Point;
    import data.class_20;
    import data.class_28;
    import flash.geom.ColorTransform;
    import items.Items;
    import flash.events.Event;
    import sounds.SoundEffects;

    public class Character extends class_7 
    {

        public static const PROP:String = 'p'; // const_52
        public static const CROWN:String = 'c'; // const_31
        public static const COWBOY:String = 'g'; // const_13 (gallon)
        public static const SANTA:String = 's'; // const_11
        public static const PARTY:String = 'a'; // const_56
        public static const TOP:String = 't'; // const_55
        public static const JUMP_START:String = 'h'; // const_27
        public static const MOON:String = 'm';
        public static const JIGG:String = 'j'; // const_51
        public static const ARTIFACT:String = 'b'; // const_25

        private var var_387:class_127;
        private var var_140:SoundChannel;
        public var m:CharacterGraphic = new CharacterGraphic();
        public var var_301:MovieClip;
        private var var_217:Array = new Array(m.runAnim, m.standAnim, m.jumpAnim, m.superJumpAnim, m.bumpedAnim, m.crouchAnim, m.crouchWalkAnim, m.swimAnim, m.frozenSolidAnim);
        public var curWeapon:MovieClip;
        public var hat1:int;
        public var hat2:int = 1;
        public var hat3:int = 1;
        public var hat4:int = 1;
        public var head:int;
        public var body:int;
        public var feet:int;
        public var headColor:int;
        public var bodyColor:int;
        public var feetColor:int;
        public var hat1Color:int;
        public var hat2Color:int;
        public var hat3Color:int;
        public var hat4Color:int;
        public var headColor2:int = -1;
        public var bodyColor2:int = -1;
        public var feetColor2:int = -1;
        public var hat1Color2:int = -1;
        public var hat2Color2:int = -1;
        public var hat3Color2:int = -1;
        public var hat4Color2:int = -1;
        public var item:int = 0;
        public var seg1:Point;
        public var seg2:Point;
        public var velX:Number = 0;
        public var velY:Number = 0;
        public var type:String = "remote";
        public var var_670:Number;
        protected var var_241:Boolean = false;
        public var state:String;
        public var var_269:Number = 0;
        public var tempID:int;
        protected var var_448:int = 5;
        protected var var_215:int = 0;
        protected var var_304:Boolean = false;
        public var var_214:Boolean = false;
        public var var_4:class_20;
        private var var_375:class_125;

        public function Character(hatId:int = 1, headId:int = 1, bodyId:int = 1, feetId:int = 1)
        {
            this.var_387 = new class_127(this);
            this.hat1 = hatId;
            this.head = headId;
            this.body = bodyId;
            this.feet = feetId;
            if (class_28.getDateStr(new Date().getTime()) === "Apr 1") {
                this.var_241 = true;
            }
            this.var_4 = new class_20();
            this.resetHats();
            this.changeState("stand");
            this.method_25();
            addChild(this.m);
        }

        public function setColors(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:int, _arg_6:int, _arg_7:int, _arg_8:int)
        {
            this.method_133(_arg_1, _arg_2);
            this.method_132(_arg_3, _arg_4);
            this.method_134(_arg_5, _arg_6);
            this.method_90(_arg_7, _arg_8);
        }

        // method_375 = resetHats
        private function resetHats()
        {
            this.var_4.setBool(PROP, false);
            this.var_4.setBool(CROWN, false);
            this.var_4.setBool(COWBOY, false);
            this.var_4.setBool(SANTA, false);
            this.var_4.setBool(PARTY, false);
            this.var_4.setBool(TOP, false);
            this.var_4.setBool(JUMP_START, false);
            this.var_4.setBool(MOON, false);
            this.var_4.setBool(JIGG, false);
            this.var_4.setBool(ARTIFACT, false);
        }

        // _loc2 = hatId
        // _loc3 = hatColor
        // _loc4 = hatColor2
        // _loc5 = hatSlot
        public function setHats(hatArray:Array)
        {
            this.hat1 = this.hat2 = this.hat3 = this.hat4 = 1;
            this.hat1Color = this.hat2Color = this.hat3Color = this.hat4Color = 0xFFFFFF;
            this.hat1Color2 = this.hat2Color2 = this.hat3Color2 = this.hat4Color2 = -1;
            this.resetHats();
            var hatSlot:int = 1;
            var _local_6:int = hatArray.length;
            var _local_7:int;
            while (_local_7 < _local_6) {
                var hatId:int = int(hatArray[_local_7]);
                var hatColor:int = int(hatArray[_local_7 + 1]);
                var hatColor2:int = int(hatArray[_local_7 + 2]);
                if (hatSlot === 1) {
                    this.hat1 = hatId;
                    this.hat1Color = hatColor;
                    this.hat1Color2 = hatColor2;
                } else if (hatSlot === 2) {
                    this.hat2 = hatId;
                    this.hat2Color = hatColor;
                    this.hat2Color2 = hatColor2;
                } else if (hatSlot === 3) {
                    this.hat3 = hatId;
                    this.hat3Color = hatColor;
                    this.hat3Color2 = hatColor2;
                } else if (hatSlot === 4) {
                    this.hat4 = hatId;
                    this.hat4Color = hatColor;
                    this.hat4Color2 = hatColor2;
                }

                if (hatId === 4) {
                    this.var_4.setBool(PROP, true);
                } else if (hatId === 5) {
                    this.var_4.setBool(COWBOY, true);
                } else if (hatId === 6) {
                    this.var_4.setBool(CROWN, true);
                } else if (hatId === 7) {
                    this.var_4.setBool(SANTA, true);
                } else if (hatId === 8) {
                    this.var_4.setBool(PARTY, true);
                } else if (hatId === 9) {
                    this.var_4.setBool(TOP, true);
                } else if (hatId === 10) {
                    this.var_4.setBool(JUMP_START, true);
                } else if (hatId === 11) {
                    this.var_4.setBool(MOON, true);
                } else if (hatId === 13) {
                    this.var_4.setBool(JIGG, true);
                } else if (hatId === 14) {
                    this.var_4.setBool(ARTIFACT, true);
                }
                hatSlot++;
                _local_7 = _local_7 + 3;
            }
            this.method_25();
        }

        public function method_395(_arg_1:Number)
        {
            this.hat1 = _arg_1;
            this.method_25();
        }

        public function method_250(_arg_1:Number)
        {
            this.head = _arg_1;
            this.method_25();
        }

        public function method_217(_arg_1:Number)
        {
            this.body = _arg_1;
            this.method_25();
        }

        public function method_326(_arg_1:Number)
        {
            this.feet = _arg_1;
            this.method_25();
        }

        public function method_133(_arg_1:int, _arg_2:int)
        {
            this.hat1Color = _arg_1;
            this.hat1Color2 = _arg_2;
            this.method_25();
        }

        public function method_132(_arg_1:int, _arg_2:int)
        {
            this.headColor = _arg_1;
            this.headColor2 = _arg_2;
            this.method_25();
        }

        public function method_134(_arg_1:int, _arg_2:int)
        {
            this.bodyColor = _arg_1;
            this.bodyColor2 = _arg_2;
            this.method_25();
        }

        public function method_90(_arg_1:int, _arg_2:int)
        {
            this.feetColor = _arg_1;
            this.feetColor2 = _arg_2;
            this.method_25();
        }

        public function setItem(_arg_1:int)
        {
            this.item = _arg_1;
            this.method_229();
        }

        private function method_25()
        {
            this.method_39("head", "head");
            this.method_39("body", "body");
            this.method_39("foot1", "feet");
            this.method_39("foot2", "feet");
            this.method_39("hat1", "hat1");
            this.method_39("hat2", "hat2");
            this.method_39("hat3", "hat3");
            this.method_39("hat4", "hat4");
            this.method_229();
            this.method_562();
            this.var_387.update();
        }

        private function method_39(_arg_1:String, _arg_2:String)
        {
            var _local_3:MovieClip;
            var _local_4:int;
            var _local_5:int;
            var _local_6:String;
            var _local_7:MovieClip;
            var _local_8:int;
            if (this.m != null) {
                _local_4 = this[_arg_2 + "Color"];
                _local_5 = this[_arg_2 + "Color2"];
                _local_6 = _arg_2;
                if (_arg_2.indexOf("hat") != -1) {
                    _local_6 = "hat";
                }
                for each (_local_7 in this.var_217) {
                    _local_8 = this[_arg_2];
                    if (_local_6 == "hat") {
                        if (this.body == 29) {
                            _local_3 = _local_7.body[_arg_2];
                        } else {
                            _local_3 = _local_7.head[_arg_2];
                        }
                    } else {
                        _local_3 = _local_7[_arg_1];
                    }
                    _local_3.gotoAndStop(_local_8);
                    _local_3.colorMC.gotoAndStop(_local_8);
                    _local_3.colorMC2.gotoAndStop(_local_8);
                    this.method_383(_local_3.colorMC, _local_4);
                    if (_local_5 != -1) {
                        _local_3.colorMC2.visible = true;
                        this.method_383(_local_3.colorMC2, _local_5);
                    } else {
                        _local_3.colorMC2.visible = false;
                    }
                }
            }
        }

        private function method_562()
        {
            var _local_1:MovieClip;
            for each (_local_1 in this.var_217) {
                if (this.body == 29) {
                    _local_1.head.visible = false;
                    _local_1.foot1.visible = false;
                    _local_1.foot2.visible = false;
                } else {
                    _local_1.head.visible = true;
                    _local_1.foot1.visible = true;
                    _local_1.foot2.visible = true;
                }
            }
        }

        private function method_383(_arg_1:MovieClip, _arg_2:int)
        {
            var _local_3:ColorTransform = new ColorTransform();
            _local_3.color = _arg_2;
            _arg_1.transform.colorTransform = _local_3;
        }

        // _loc1 = mc
        private function method_229()
        {
            for each (var mc:MovieClip in this.var_217) {
                mc.weapon.gotoAndStop(Items.getNameFromCode(this.item));
            }
        }

        public function setPos(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
        }

        public function rotate(_arg_1:String)
        {
            var _local_2:Number;
            var _local_3:Number;
            if (_arg_1 == "right") {
                _local_2 = -y;
                _local_3 = x;
            } else {
                _local_2 = y;
                _local_3 = -x;
            }
            x = _local_2;
            y = _local_3;
        }

        protected function method_58(_arg_1:Number)
        {
            var _local_2:Point = new Point(Math.floor(x / 30), Math.floor(y / 30));
            this.seg1 = class_28.method_9(_local_2.x, _local_2.y, _arg_1);
            this.seg2 = new Point(this.seg1.x, this.seg1.y - 1);
            if (_arg_1 == 90) {
                this.seg1.x--;
                this.seg2.x--;
            } else if (Math.abs(_arg_1) == 180) {
                this.seg1.x--;
                this.seg2.x--;
                this.seg1.y++;
                this.seg2.y++;
            } else if (_arg_1 == -90) {
                this.seg1.y++;
                this.seg2.y++;
            }
        }

        public function method_51(_arg_1:Number)
        {
            this.var_269 = _arg_1;
            removeEventListener(Event.ENTER_FRAME, this.method_106);
            addEventListener(Event.ENTER_FRAME, this.method_106, false, 0, true);
        }

        private function method_106(_arg_1:Event)
        {
            var _local_2:Number = this.var_269 % 8;
            if (!this.var_304) {
                if (_local_2 >= 4) {
                    alpha = 0.5;
                } else {
                    alpha = 0.75;
                }
            }
            this.var_269--;
            if (this.var_269 <= 0) {
                this.endRecovery();
            }
        }

        protected function endRecovery()
        {
            alpha = 1;
            removeEventListener(Event.ENTER_FRAME, this.method_106);
        }

        // _loc2 = mc
        // method_11 = changeState
        public function changeState(s:String)
        {
            if (this.state != s) {
                if (this.state == "superJump") {
                    this.method_820();
                }
                if (s == "superJump") {
                    this.method_623();
                }
                if (s == "jump") {
                    if (this.velY <= 0) {
                        SoundEffects.playGameSound(new JumpSound(), x, y, 0.75);
                    }
                }
                this.state = s;
                if (this.m != null) {
                    var mc:MovieClip;
                    for each (mc in this.var_217) {
                        mc.stop();
                        if (mc.parent != null) {
                            mc.parent.removeChild(mc);
                        }
                    }
                    mc = this.m[this.state + "Anim"];
                    this.m.addChild(mc);
                    this.curWeapon = mc.weapon;
                    mc.gotoAndPlay(1);
                    this.var_301 = mc;
                }
                this.var_387.update();
            }
        }

        public function gainHeart()
        {
            SoundEffects.playGameSound(new BumpHappySound(), x, y, 0.75);
            this.becomeInvincible(Main.instance.stage.frameRate * 5);
        }

        public function becomeInvincible(_arg_1:int)
        {
            this.method_51(_arg_1);
            this.method_200(new class_126(33, 5000, this));
        }

        public function beginSparkles(_arg_1:int=5000)
        {
            SoundEffects.playGameSound(new SpeedUpSound(), x, y);
            this.method_200(new class_125(33, _arg_1, this));
        }

        public function endSparkles(used:Boolean = false)
        {
            if (used == true) {
                SoundEffects.playGameSound(new SlowDownSound(), x, y);
            }
            this.method_190();
        }

        protected function method_623()
        {
            addEventListener(Event.ENTER_FRAME, this.method_156, false, 0, true);
        }

        protected function method_820()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_156);
            scaleY = 1;
        }

        private function method_156(_arg_1:Event)
        {
            var _local_2:Number = this.m.superJumpAnim.currentFrame / 2;
            scaleY = (((Math.random() * _local_2) + (100 - (_local_2 / 2))) / 100);
        }

        public function beginJet()
        {
            addEventListener(Event.ENTER_FRAME, this.method_207, false, 0, true);
            if (this.curWeapon != null && this.curWeapon.jetPack != null) {
                this.curWeapon.jetPack.gotoAndStop("on");
            }
            if (this.var_140 != null) {
                this.var_140.stop();
            }
            this.var_140 = SoundEffects.playGameSound(new EngineSound(), x, y, 0.6, 0, 999);
        }

        public function endJet()
        {
            var _local_1:MovieClip;
            removeEventListener(Event.ENTER_FRAME, this.method_207);
            if (this.var_140 != null) {
                this.var_140.stop();
                this.var_140 = null;
            }
            for each (_local_1 in this.var_217) {
                if (_local_1.weapon.jetPack != null) {
                    _local_1.weapon.jetPack.gotoAndStop("off");
                }
            }
        }

        private function method_207(_arg_1:Event)
        {
            var _local_2:MovieClip;
            if (this.curWeapon != null && this.curWeapon.jetPack != null && this.curWeapon.jetPack.anim != null && this.var_140 != null) {
                this.curWeapon.jetPack.gotoAndStop("on");
                _local_2 = this.curWeapon.jetPack.anim;
                if (_local_2 != null && _local_2.fire1 != null) {
                    _local_2.fire1.scaleY = (Math.random() * 0.5) + 0.5;
                    _local_2.fire2.alpha = (Math.random() * 0.5) + 0.5;
                }
            }
        }

        protected function method_380():Object
        {
            var _local_1:int;
            var _local_2:int;
            var _local_3:int = 4;
            while (_local_3 >= 1) {
                if (this[("hat" + _local_3)] != 1) {
                    _local_1 = this[("hat" + _local_3)];
                    _local_2 = this[(("hat" + _local_3) + "Color")];
                    this[("hat" + _local_3)] = 1;
                    break;
                }
                _local_3--;
            }
            this.method_25();
            var _local_4:Object = new Object();
            _local_4.hatNum = _local_1;
            _local_4.hatColor = _local_2;
            return (_local_4);
        }

        public function method_576()
        {
            this.method_200(new class_129(33, 5000, this));
        }

        private function method_200(_arg_1:class_125)
        {
            this.method_190();
            this.var_375 = _arg_1;
        }

        private function method_190()
        {
            if (this.var_375 != null) {
                this.var_375.remove();
                this.var_375 = null;
            }
        }

        private function fadeOut(_arg_1:Event)
        {
            alpha = (alpha - 0.02);
            if (alpha <= 0) {
                this.remove();
            }
        }

        public function beginRemove()
        {
            this.removeListeners();
            if (!this.var_304 && !this.var_214) {
                this.var_304 = true;
                addEventListener(Event.ENTER_FRAME, this.fadeOut, false, 0, true);
            }
        }

        protected function removeListeners()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_106);
            removeEventListener(Event.ENTER_FRAME, this.method_156);
            removeEventListener(Event.ENTER_FRAME, this.method_207);
        }

        override public function remove()
        {
            this.removeListeners();
            this.method_190();
            this.var_387.remove();
            if (!this.var_214) {
                this.var_214 = this.var_304 = true;
                removeEventListener(Event.ENTER_FRAME, this.fadeOut);
                if (this.var_140 != null) {
                    this.var_140.stop();
                    this.var_140 = null;
                }
                this.m = null;
                this.curWeapon = null;
                this.var_217 = new Array();
                this.var_4.remove();
                this.var_4 = null;
                super.remove();
            }
        }


    }
}//package package_8

