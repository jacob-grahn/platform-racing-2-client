// character.Character = character.class_76

package character
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

        public static const PROP:String = 'p';
        public static const CROWN:String = 'c';
        public static const COWBOY:String = 'g';
        public static const SANTA:String = 's';
        public static const PARTY:String = 'a';
        public static const TOP:String = 't';
        public static const JUMP_START:String = 'h';
        public static const MOON:String = 'm';
        public static const JIGG:String = 'j';
        public static const ARTIFACT:String = 'b';
        public static const JELLYFISH:String = 'f'; // (fish)
        public static const CHEESE:String = 'ch';

        private var djinnEffects:DjinnEffects;
        private var jetSoundChannel:SoundChannel;
        public var m:CharacterGraphic = new CharacterGraphic();
        public var curAnim:MovieClip;
        private var characterStatesArray:Array = new Array(m.runAnim, m.standAnim, m.jumpAnim, m.superJumpAnim, m.bumpedAnim, m.crouchAnim, m.crouchWalkAnim, m.swimAnim, m.frozenSolidAnim);
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
        public var _unused670:Number;
        protected var reversedControls:Boolean = false;
        public var state:String;
        public var recoveryFrames:Number = 0;
        public var tempID:int;
        protected var updateInterval:int = 5;
        protected var framesSinceUpdate:int = 0;
        protected var fadeOutStarted:Boolean = false;
        public var removed:Boolean = false;
        public var store:SecureStore;
        private var activeEmitter:ParticleEmitter;

        public function Character(hatId:int = 1, headId:int = 1, bodyId:int = 1, feetId:int = 1)
        {
            this.djinnEffects = new DjinnEffects(this);
            this.hat1 = hatId;
            this.head = headId;
            this.body = bodyId;
            this.feet = feetId;
            if (Data.getDateStr(new Date().getTime()) === "Apr 1") {
                this.reversedControls = true;
            }
            this.store = new SecureStore();
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

        private function resetHats()
        {
            this.store.setBool(PROP, false);
            this.store.setBool(CROWN, false);
            this.store.setBool(COWBOY, false);
            this.store.setBool(SANTA, false);
            this.store.setBool(PARTY, false);
            this.store.setBool(TOP, false);
            this.store.setBool(JUMP_START, false);
            this.store.setBool(MOON, false);
            this.store.setBool(JIGG, false);
            this.store.setBool(ARTIFACT, false);
            this.store.setBool(JELLYFISH, false);
            this.store.setBool(CHEESE, false);
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
                    this.store.setBool(PROP, true);
                } else if (hatId === 5) {
                    this.store.setBool(COWBOY, true);
                } else if (hatId === 6) {
                    this.store.setBool(CROWN, true);
                } else if (hatId === 7) {
                    this.store.setBool(SANTA, true);
                } else if (hatId === 8) {
                    this.store.setBool(PARTY, true);
                } else if (hatId === 9) {
                    this.store.setBool(TOP, true);
                } else if (hatId === 10) {
                    this.store.setBool(JUMP_START, true);
                } else if (hatId === 11) {
                    this.store.setBool(MOON, true);
                } else if (hatId === 13) {
                    this.store.setBool(JIGG, true);
                } else if (hatId === 14) {
                    this.store.setBool(ARTIFACT, true);
                } else if (hatId === 15) {
                    this.store.setBool(JELLYFISH, true);
                } else if (hatId === 16) {
                    this.store.setBool(CHEESE, true);
                }
                hatSlot++;
                _local_7 = _local_7 + 3;
            }
            this.applyAppearance();
        }

        public function setHatId(id:Number)
        {
            this.hat1 = id;
            this.applyAppearance();
        }

        public function setHeadId(id:Number)
        {
            this.head = id;
            this.applyAppearance();
        }

        public function setBodyId(id:Number)
        {
            this.body = id;
            this.applyAppearance();
        }

        public function setFeetId(id:Number)
        {
            this.feet = id;
            this.applyAppearance();
        }

        public function setHatColors(color:int, epic:int, hatNum:int = 1)
        {
            hatNum = Data.numLimit(hatNum, 1, 4);
            this['hat' + hatNum + 'Color'] = color;
            this['hat' + hatNum + 'Color2'] = epic;
            this.applyAppearance();
        }

        public function setHeadColors(color:int, epic:int)
        {
            this.headColor = color;
            this.headColor2 = epic;
            this.applyAppearance();
        }

        public function setBodyColors(color:int, epic:int)
        {
            this.bodyColor = color;
            this.bodyColor2 = epic;
            this.applyAppearance();
        }

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
            this.djinnEffects.update();
        }

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
                for each (var charMC:MovieClip in this.characterStatesArray) {
                    var partId:int = this[partType];
                    if (type == "hat") {
                        if (this.body == 29) {
                            part = charMC.body[partType]; // get hat from bodyMC if fred body is selected
                        } else {
                            part = charMC.head[partType]; // otherwise, get hat from headMC
                        }
                    } else {
                        part = charMC[propName];
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

        private function hideHeadFeetIfFredBody()
        {
            for each (var charMC:MovieClip in this.characterStatesArray) {
                if (this.body == 29) {
                    charMC.head.visible = false;
                    charMC.foot1.visible = false;
                    charMC.foot2.visible = false;
                } else {
                    charMC.head.visible = true;
                    charMC.foot1.visible = true;
                    charMC.foot2.visible = true;
                }
            }
        }

        private function applyPartColor(mc:MovieClip, color:int)
        {
            var ct:ColorTransform = new ColorTransform();
            ct.color = color;
            mc.transform.colorTransform = ct;
        }

        private function applyItem()
        {
            for each (var charMC:MovieClip in this.characterStatesArray) {
                charMC.weapon.gotoAndStop(Items.getNameFromCode(this.item));
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

        protected function updateSegs(_arg_1:Number)
        {
            var _local_2:Point = new Point(Math.floor(x / 30), Math.floor(y / 30));
            this.seg1 = Data.rotatePoint(_local_2.x, _local_2.y, _arg_1);
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

        public function beginRecovery(_arg_1:Number)
        {
            this.recoveryFrames = _arg_1;
            removeEventListener(Event.ENTER_FRAME, this.recoveryTick);
            addEventListener(Event.ENTER_FRAME, this.recoveryTick, false, 0, true);
        }

        private function recoveryTick(_arg_1:Event)
        {
            var _local_2:Number = this.recoveryFrames % 8;
            if (!this.fadeOutStarted) {
                alpha = _local_2 >= 4 ? 0.5 : 0.75;
            }
            this.recoveryFrames--;
            if (this.recoveryFrames <= 0) {
                this.endRecovery();
            }
        }

        protected function endRecovery()
        {
            alpha = 1;
            removeEventListener(Event.ENTER_FRAME, this.recoveryTick);
        }

        public function changeState(s:String)
        {
            if (this.state != s) {
                if (this.state == "superJump") {
                    this.endSuperJumpWobble();
                }
                if (s == "superJump") {
                    this.startSuperJumpWobble();
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
                    this.curAnim = characterMC;
                }
                this.djinnEffects.update();
            }
        }

        public function djinnUpdateAlpha(newAlpha:Number)
        {
            this.djinnEffects.newAlpha(newAlpha);
        }

        public function gainHeart()
        {
            SoundEffects.playGameSound(new BumpHappySound(), x, y, 0.75);
            this.becomeInvincible(Main.instance.stage.frameRate * 5);
        }

        public function becomeInvincible(_arg_1:int)
        {
            this.beginRecovery(_arg_1);
            this.setEmitter(new RainbowStarEmitter(33, 5000, this));
        }

        public function beginSparkles(_arg_1:int=5000)
        {
            SoundEffects.playGameSound(new SpeedUpSound(), x, y);
            this.setEmitter(new ParticleEmitter(33, _arg_1, this));
        }

        public function endSparkles(used:Boolean = false)
        {
            if (used == true) {
                SoundEffects.playGameSound(new SlowDownSound(), x, y);
            }
            this.clearEmitter();
        }

        protected function startSuperJumpWobble()
        {
            addEventListener(Event.ENTER_FRAME, this.superJumpWobbleTick, false, 0, true);
        }

        protected function endSuperJumpWobble()
        {
            removeEventListener(Event.ENTER_FRAME, this.superJumpWobbleTick);
            scaleY = 1;
        }

        private function superJumpWobbleTick(_arg_1:Event)
        {
            var _local_2:Number = this.m.superJumpAnim.currentFrame / 2;
            scaleY = ((Math.random() * _local_2) + (100 - (_local_2 / 2))) / 100;
        }

        public function beginJet()
        {
            addEventListener(Event.ENTER_FRAME, this.jetPackTick, false, 0, true);
            if (this.curWeapon != null && this.curWeapon.jetPack != null) {
                this.curWeapon.jetPack.gotoAndStop("on");
            }
            if (this.jetSoundChannel != null) {
                this.jetSoundChannel.stop();
            }
            this.jetSoundChannel = SoundEffects.playGameSound(new EngineSound(), x, y, 0.6, 0, 999);
        }

        public function endJet()
        {
            var _local_1:MovieClip;
            removeEventListener(Event.ENTER_FRAME, this.jetPackTick);
            if (this.jetSoundChannel != null) {
                this.jetSoundChannel.stop();
                this.jetSoundChannel = null;
            }
            for each (_local_1 in this.characterStatesArray) {
                if (_local_1.weapon.jetPack != null) {
                    _local_1.weapon.jetPack.gotoAndStop("off");
                }
            }
        }

        private function jetPackTick(_arg_1:Event)
        {
            var _local_2:MovieClip;
            if (this.curWeapon != null && this.curWeapon.jetPack != null && this.curWeapon.jetPack.anim != null && this.jetSoundChannel != null) {
                this.curWeapon.jetPack.gotoAndStop("on");
                _local_2 = this.curWeapon.jetPack.anim;
                if (_local_2 != null && _local_2.fire1 != null) {
                    _local_2.fire1.scaleY = (Math.random() * 0.5) + 0.5;
                    _local_2.fire2.alpha = (Math.random() * 0.5) + 0.5;
                }
            }
        }

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

        public function beginArrowSparkles()
        {
            this.setEmitter(new ArrowSparkleEmitter(33, 5000, this));
        }

        private function setEmitter(_arg_1:ParticleEmitter)
        {
            this.clearEmitter();
            this.activeEmitter = _arg_1;
        }

        private function clearEmitter()
        {
            if (this.activeEmitter != null) {
                this.activeEmitter.remove();
                this.activeEmitter = null;
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
            removeEventListener(Event.ENTER_FRAME, this.recoveryTick);
            removeEventListener(Event.ENTER_FRAME, this.superJumpWobbleTick);
            removeEventListener(Event.ENTER_FRAME, this.jetPackTick);
        }

        override public function remove()
        {
            this.removeListeners();
            this.clearEmitter();
            this.djinnEffects.remove();
            if (!this.removed) {
                this.removed = this.fadeOutStarted = true;
                removeEventListener(Event.ENTER_FRAME, this.fadeOut);
                if (this.jetSoundChannel != null) {
                    this.jetSoundChannel.stop();
                    this.jetSoundChannel = null;
                }
                this.m = null;
                this.curWeapon = null;
                this.characterStatesArray = new Array();
                this.store.remove();
                this.store = null;
                super.remove();
            }
        }


    }
}//package character

