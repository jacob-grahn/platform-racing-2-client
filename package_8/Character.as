// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_8.Character = package_8.class_76

package package_8
{
    import flash.media.SoundChannel;
    import flash.display.MovieClip;
    import flash.geom.Point;
    import com.jiggmin.data.SecureStore;
    import com.jiggmin.data.Data;
    import flash.geom.ColorTransform;
    import items.Items;
    import flash.events.Event;
    import sounds.SoundEffects;

    public class Character extends Removable 
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
        public static const JELLYFISH:String = 'f'; // (fish)
        public static const CHEESE:String = 'ch';

        private var var_387:class_127;
        private var var_140:SoundChannel;
        public var m:CharacterGraphic = new CharacterGraphic();
        public var var_301:MovieClip;
        private var characterStatesArray:Array = new Array(m.runAnim, m.standAnim, m.jumpAnim, m.superJumpAnim, m.bumpedAnim, m.crouchAnim, m.crouchWalkAnim, m.swimAnim, m.frozenSolidAnim); // var_217
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
        public var userName:String = '';
        public var groupStr:String = '0';
        public var item:int = 0;
        public var seg1:Point;
        public var seg2:Point;
        public var velX:Number = 0;
        public var velY:Number = 0;
        public var type:String = "remote";
        public var var_670:Number;
        protected var reversedControls:Boolean = false; // var_241
        public var state:String;
        public var var_269:Number = 0;
        public var tempID:int;
        protected var var_448:int = 5;
        protected var var_215:int = 0;
        protected var fadeOutStarted:Boolean = false; // var_304
        public var removed:Boolean = false; // var_214
        public var var_4:SecureStore;
        private var var_375:class_125;

        public function Character(hatId:int = 1, headId:int = 1, bodyId:int = 1, feetId:int = 1)
        {
            this.var_387 = new class_127(this);
            this.hat1 = hatId;
            this.head = headId;
            this.body = bodyId;
            this.feet = feetId;
            if (Data.getDateStr(new Date().getTime()) === "Apr 1") {
                this.reversedControls = true;
            }
            this.var_4 = new SecureStore();
            this.resetHats();
            this.changeState("stand");
            this.applyAppearance();
            addChild(this.m);
        }

        public function setColors(hatColor:int, hatColor2:int, headColor:int, headColor2:int, bodyColor:int, bodyColor2:int, feetColor:int, feetColor2:int)
        {
            this.setHatColors(hatColor, hatColor2);
            this.setHeadColors(headColor, headColor2);
            this.setBodyColors(bodyColor, bodyColor2);
            this.setFeetColors(feetColor, feetColor2);
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
            this.var_4.setBool(JELLYFISH, false);
            this.var_4.setBool(CHEESE, false);
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
                } else if (hatId === 15) {
                    this.var_4.setBool(JELLYFISH, true);
                } else if (hatId === 16) {
                    this.var_4.setBool(CHEESE, true);
                }
                hatSlot++;
                _local_7 = _local_7 + 3;
            }
            this.applyAppearance();
        }

        // method_395 = setHatId
        public function setHatId(id:Number)
        {
            this.hat1 = id;
            this.applyAppearance();
        }

        // method_250 = setHeadId
        public function setHeadId(id:Number)
        {
            this.head = id;
            this.applyAppearance();
        }

        // method_217 = setBodyId
        public function setBodyId(id:Number)
        {
            this.body = id;
            this.applyAppearance();
        }

        // method_326 = setFeetId
        public function setFeetId(id:Number)
        {
            this.feet = id;
            this.applyAppearance();
        }

        // method_133 = setHatColors
        public function setHatColors(color:int, epic:int, hatNum:int = 1)
        {
            hatNum = Data.numLimit(hatNum, 1, 4);
            this['hat' + hatNum + 'Color'] = color;
            this['hat' + hatNum + 'Color2'] = epic;
            this.applyAppearance();
        }

        // method_132 = setHeadColors
        public function setHeadColors(color:int, epic:int)
        {
            this.headColor = color;
            this.headColor2 = epic;
            this.applyAppearance();
        }

        // method_134 = setBodyColors
        public function setBodyColors(color:int, epic:int)
        {
            this.bodyColor = color;
            this.bodyColor2 = epic;
            this.applyAppearance();
        }

        // method_90 = setFeetColors
        public function setFeetColors(color:int, epic:int)
        {
            this.feetColor = color;
            this.feetColor2 = epic;
            this.applyAppearance();
        }

        public function setItem(_arg_1:int)
        {
            this.item = _arg_1;
            this.applyItem();
        }

        // method_25 = applyAppearance
        private function applyAppearance()
        {
            this.updatePartMC("head", "head");
            this.updatePartMC("body", "body");
            this.updatePartMC("foot1", "feet");
            this.updatePartMC("foot2", "feet");
            this.updatePartMC("hat1", "hat1");
            this.updatePartMC("hat2", "hat2");
            this.updatePartMC("hat3", "hat3");
            this.updatePartMC("hat4", "hat4");
            this.applyItem();
            this.hideHeadFeetIfFredBody();
            this.var_387.update();
        }

        // _loc3 = part
        // _loc4 = color
        // _loc5 = color2
        // _loc6 = type
        // _loc7 = character
        // _loc8 = partId
        // method_39 = updatePartMC
        private function updatePartMC(propName:String, partType:String)
        {
            var part:MovieClip;
            if (this.m != null) {
                var color:int = this[partType + "Color"];
                var color2:int = this[partType + "Color2"];
                var type:String = partType;
                if (partType.indexOf("hat") != -1) {
                    type = "hat";
                }
                for each (var character:MovieClip in this.characterStatesArray) {
                    var partId:int = this[partType];
                    if (type == "hat") {
                        if (this.body == 29) {
                            part = character.body[partType]; // get hat from bodyMC if fred body is selected
                        } else {
                            part = character.head[partType]; // otherwise, get hat from headMC
                        }
                    } else {
                        part = character[propName];
                    }
                    part.gotoAndStop(partId);
                    part.colorMC.gotoAndStop(partId);
                    part.colorMC2.gotoAndStop(partId);
                    this.applyPartColor(part.colorMC, color);
                    color2 = type == 'hat' && partId == 16 && color2 == -1 ? 0 : color2; // transparency workaround for cheese hat. I am being so lazy with this... but do I care???
                    if (color2 != -1) {
                        part.colorMC2.visible = true;
                        this.applyPartColor(part.colorMC2, color2);
                    } else {
                        part.colorMC2.visible = false;
                    }
                }
            }
        }

        // _loc1 = character
        // method_562 = hideHeadFeetIfFredBody
        private function hideHeadFeetIfFredBody()
        {
            for each (var character:MovieClip in this.characterStatesArray) {
                if (this.body == 29) {
                    character.head.visible = false;
                    character.foot1.visible = false;
                    character.foot2.visible = false;
                } else {
                    character.head.visible = true;
                    character.foot1.visible = true;
                    character.foot2.visible = true;
                }
            }
        }

        // _loc3 = ct
        // method_383 = applyPartColor
        private function applyPartColor(mc:MovieClip, color:int)
        {
            var ct:ColorTransform = new ColorTransform();
            ct.color = color;
            mc.transform.colorTransform = ct;
        }

        // _loc1 = character
        // method_229 = applyItem
        private function applyItem()
        {
            for each (var character:MovieClip in this.characterStatesArray) {
                character.weapon.gotoAndStop(Items.getNameFromCode(this.item));
            }
        }

        public function getName():String
        {
            return this.userName;
        }

        public function getGroup():String
        {
            return this.groupStr;
        }

        protected function setNameColor(color:int)
        {
            m.nameHolder.nameBox.textColor = color;
        }

        public function getPos()
        {
            var pos:Object = new Object();
            pos.x = x;
            pos.y = y;
            return pos;
        }

        public function setPos(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
        }

        public function rotate(direction:String)
        {
            var _local_2:Number;
            var _local_3:Number;
            if (direction == "right") {
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
            this.seg1 = Data.method_9(_local_2.x, _local_2.y, _arg_1);
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
            if (!this.fadeOutStarted) {
                alpha = _local_2 >= 4 ? 0.5 : 0.75;
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

        // _loc2 = character
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
                    for each (var characterMC:MovieClip in this.characterStatesArray) {
                        characterMC.stop();
                        if (characterMC.parent != null) {
                            characterMC.parent.removeChild(characterMC);
                        }
                    }
                    characterMC = this.m[this.state + "Anim"];
                    this.m.addChild(characterMC);
                    this.curWeapon = characterMC.weapon;
                    characterMC.gotoAndPlay(1);
                    this.var_301 = characterMC;
                }
                this.var_387.update();
            }
        }

        public function djinnUpdateAlpha(newAlpha:Number)
        {
            this.var_387.newAlpha(newAlpha);
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
            scaleY = ((Math.random() * _local_2) + (100 - (_local_2 / 2))) / 100;
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
            for each (_local_1 in this.characterStatesArray) {
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

        // _loc1 = hatNum
        // _loc2 = hatColor
        // _loc3 = hatSlot
        // method_380 = getHighestHat
        protected function getHighestHat():Object
        {
            var hatSlot:int = 4;
            while (hatSlot >= 1) {
                if (this["hat" + hatSlot] != 1) {
                    var hatNum:int = this["hat" + hatSlot];
                    var hatColor:int = this["hat" + hatSlot + "Color"];
                    this["hat" + hatSlot] = 1;
                    break;
                }
                hatSlot--;
            }
            this.applyAppearance();
            var _local_4:Object = new Object();
            _local_4.hatNum = hatNum;
            _local_4.hatColor = hatColor;
            return _local_4;
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
            alpha -= 0.02;
            if (alpha <= 0) {
                this.remove();
            }
        }

        public function beginRemove()
        {
            this.removeListeners();
            if (!this.fadeOutStarted && !this.removed) {
                this.fadeOutStarted = true;
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
            if (!this.removed) {
                this.removed = this.fadeOutStarted = true;
                removeEventListener(Event.ENTER_FRAME, this.fadeOut);
                if (this.var_140 != null) {
                    this.var_140.stop();
                    this.var_140 = null;
                }
                this.m = null;
                this.curWeapon = null;
                this.characterStatesArray = new Array();
                this.var_4.remove();
                this.var_4 = null;
                super.remove();
            }
        }


    }
}//package package_8

