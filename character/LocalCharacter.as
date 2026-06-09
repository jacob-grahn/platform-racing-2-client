// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// character.class_86 = character.LocalCharacter

package character
{
    import background.Map;
    import blocks.Block;
    import blocks.SafetyBlock;
    import blocks.TeleportBlock;
    import blocks.VanishBlock;
    import blocks.WaterBlock;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.PR2Socket;
    import com.jiggmin.data.Settings;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    import flash.media.Sound;
    import flash.net.URLRequest;
    import flash.ui.Keyboard;
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;
    import items.Item;
    import items.Items;
    import items.JetPack;
    import items.SpeedBurst;
    import sounds.SoundEffects;
    import gameplay.ItemDisplay;
    import gameplay.CourseTimer;
    import gameplay.Course;
    import gameplay.Modes;
    import gameplay.RaceChat;
    import gameplay.TestCourse;
    import effects.Hat;
    import effects.Sting;
    import effects.Zap;
    import page.GamePage;

    public class LocalCharacter extends Character 
    {

        public static const JUMP_VEL:String = "njv";
        public static const SuperJump:String = "nj";
        public static const DefaultGravity:String = "gr";
        public static const GravityMultiplied:String = "grm";

        private var socket:PR2Socket = Main.socket;
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var course:Course;
        private var map:Map;
        private var mapDot:MiniMapDot;
        private var itemDisplay:ItemDisplay;
        private var epnuInterval:uint = setInterval(setEPNU, 5000);
        private var cowboyCheckInterval:uint = setInterval(ensureCowboyStats, 250);
        private var prevParent:DisplayObject = parent;
        private var speedStat:int;
        private var accelStat:int;
        private var jumpnStat:int;
        public var accel:Number;
        public var maxVelX:Number;
        public var targetVelX:Number = 0;
        public var targetVelY:Number = 0;
        private var baseAccelFactor:Number = 0.35;
        private var baseVelFactor:Number = 1;
        public var accelFactor:Number = baseAccelFactor;
        public var velFactor:Number = baseVelFactor;
        public var halfWidth:Number = 10;
        public var charHeight:Number = 55;
        public var lastSafeX:Number = 0;
        public var lastSafeY:Number = 0;
        public var standingSegX:int;
        public var standingSegY:int;
        public var maxSpeed:Number = 28;
        private var initialized:Boolean = false;
        public var testMode:Boolean = false;
        public var grounded:Boolean = false;
        public var crouching:Boolean = false;
        public var up:Boolean = false;
        public var down:Boolean = false;
        public var right:Boolean = false;
        public var left:Boolean = false;
        public var space:Boolean = false;
        private var friction:Number = 0.985;
        private var jumpHeld:Boolean = false;
        private var crouchCharge:Number = 0;
        private var segSize:Number = 30;
        private var hurtTime:Number = 0;
        private var squashedTime:Number = 0;
        private var stingCooldown:int = 135;
        public var waterTicks:Number = 0;
        private var floorLeft:Block = null;
        private var floorCenter:Block = null;
        private var floorRight:Block = null;
        private var wallLeft:Block = null;
        private var midBlock:Block = null;
        private var wallRight:Block = null;
        private var ceilLeft:Block = null;
        private var ceiling:Block = null;
        private var ceilRight:Block = null;
        private var headBlock:Block = null;
        private var topBlock:Block = null;
        public var mode:String = "wait";
        private var curItem:Item;
        private var speedBurst:SpeedBurst;
        private var life:int = 3;
        private var invincible:Boolean = false;
        private var frozenSolid:Boolean = false;
        private var unfreezeTimer:uint;
        private var lastNetScaleX:Number;
        private var exactX:int;
        private var exactY:int;
        private var lastNetState:String;
        private var lastNetItem:int;
        private var exactPosNextUpdate:Boolean = false;
        private var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
        private var startingStats:Array = null;

        public function LocalCharacter(tId:int, c:Course, ma:Map, dot:MovieClip, itd:ItemDisplay, grav:Number, s:int=50, a:int=50, j:int=50, ha:int=1, h:int=1, b:int=1, f:int=1, groupStr:String = '0')
        {
            super(ha, h, b, f);
            store.setNumber(JUMP_VEL, 0);
            store.setNumber(SuperJump, 0);
            store.setNumber(DefaultGravity, 0.7);
            this.setStats(s, a, j);
            this.setGravity(grav);
            this.tempID = tId;
            this.course = c;
            this.map = ma;
            this.mapDot = dot;
            this.itemDisplay = itd;
            type = "local";
            this.mapDot.setTempID(this.tempID, true);
            super.userName = Main.loggedInAs;
            super.groupStr = groupStr;
            if (Main.instance.kongAPI != null && Main.instance.kongAPI.stats != null) {
                if (h == 17 && b == 13 && f == 12) {
                    Main.instance.kongAPI.stats.submit("Stickman", 1);
                }
                if (h == 14 && b == 11 && f == 11) {
                    Main.instance.kongAPI.stats.submit("Invisiman", 1);
                }
                if (h == 11 && b == 10 && f == 10) {
                    Main.instance.kongAPI.stats.submit("Birdman", 1);
                }
            }
            this.cm.defineCommand("zap", this.zap);
            this.cm.defineCommand("setHats" + this.tempID.toString(), this.setHats);
            this.cm.defineCommand("squash" + this.tempID.toString(), this.squash);
            this.cm.defineCommand("sting" + this.tempID.toString(), this.sting);
        }

        public function init()
        {
            if (!this.initialized && !removed && !fadeOutStarted) {
                this.initialized = true;
                addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
                this.setMode("land");
                this.exactPosNextUpdate = true;
                this.socket.write("p`0`0");
            }
        }

        public function setStats(s:int, a:int, j:int, reset:Boolean = false)
        {
            this.speedStat = Data.numLimit(s, 0, 100);
            this.accelStat = Data.numLimit(a, 0, 100);
            this.jumpnStat = Data.numLimit(j, 0, 100);
            // only apply speed/accel change if a speed burst isn't active.
            // wait to apply speed/accel change until after the speed burst ends and calls resetStats()
            if (!(this.curItem is SpeedBurst && this.curItem.isUsed()) || reset) {
                this.maxVelX = 2 + (this.speedStat / 10);
                this.accel = 0.2 + (this.accelStat / 60);
                this.ensureSantaStats();
            }
            store.setNumber(SuperJump, 2 + (this.jumpnStat / 40));
            if (Course.course != null && Course.course.statsDisplay != null) {
                Course.course.statsDisplay.setStats(this.speedStat, this.accelStat, this.jumpnStat);
            }
            if (this.startingStats == null && Course.course != null) {
                this.startingStats = [this.speedStat, this.accelStat, this.jumpnStat];
            }
        }

        public function resetStats()
        {
            this.setStats(this.speedStat, this.accelStat, this.jumpnStat, true);
        }

        public function resetStatsToStart()
        {
            this.setStats(this.startingStats[0], this.startingStats[1], this.startingStats[2]);
        }

        public function statsChange(changeAmt:int)
        {
            this.speedStat = this.speedStat + changeAmt;
            this.accelStat = this.accelStat + changeAmt;
            this.jumpnStat = this.jumpnStat + changeAmt;
            this.setStats(this.speedStat, this.accelStat, this.jumpnStat);
        }

        public function getStats()
        {
            return {
                "speed": this.speedStat,
                "acceleration": this.accelStat,
                "jumping": this.jumpnStat
            };
        }

        public function setGravity(_arg_1:Number)
        {
            store.setNumber(GravityMultiplied, store.getNumber(DefaultGravity) * _arg_1);
        }

        private function resetGravity()
        {
            store.setNumber(GravityMultiplied, store.getNumber(DefaultGravity) * GamePage.course.gravity);
        }

        public function squash(a:Array)
        {
            if (this.mode != "squashed" && recoveryFrames <= 0) {
                this.setMode("squashed");
                SoundEffects.playGameSound(new SquashSound(), x, y, 0.66);
            }
        }

        public function sting(a:Array)
        {
            var from:Character = this.course.playerArray[a[0]];
            if (from == null || from is LocalCharacter || from.tempID == this.tempID) {
                return; // shouldn't happen
            }
            var fromPos:Object = from.getPos();
            var fromDirection:String = fromPos.x < x ? 'left' : (fromPos.x > x ? 'right' : '');
            new Sting(this, fromDirection);
            if (!store.getBool(PARTY) && !store.getBool(JELLYFISH)) {
                this.setMode('hurt');
            }
        }

        public function zap(a:Array)
        {
            // show zap on other players
            for each (var p:Character in this.course.playerArray) {
                if (a[0] != p.tempID) {
                    new Zap(p, true, false, false);
                }
            }

            if (a[0] == this.tempID) { // skip my zap if I was the one that sent it
                return;
            } else { // zap me
                new Zap(this, true);
                if (!store.getBool(PARTY)) {
                    this.setMode("hurt");
                }
            }
        }

        // _loc2 = curX
        // _loc3 = curY
        // _loc4 = curPos
        // _loc5 = deltaX
        // _loc6 = deltaY
        private function go(e:Event)
        {
            var curX:int = x = Math.round(x);
            var curY:int = y = Math.round(y);
            if (this.map != null) {
                var curPos:Point = Data.rotatePoint(curX, curY, this.map.rotation);
                this.mapDot.x = curPos.x;
                this.mapDot.y = curPos.y;
            }
            updateSegs(this.map.rotation);
            this.hurtTime--;
            // if (this.course.playerArray.length > 1) {
                framesSinceUpdate++; // setting this to a static value greater than 16 (formerly 23) will send wholly instant position updates to players
                if (framesSinceUpdate >= updateInterval) {
                    if (this.playersInPosUpdateRange() || framesSinceUpdate >= 16) {//23) {
                        framesSinceUpdate = 0;
                    //if (curX != this.exactX || curY != this.exactY) { // if statement added by me
                        var deltaX:int = curX - this.exactX;
                        var deltaY:int = curY - this.exactY;
                        this.exactX = curX;
                        this.exactY = curY;
                        if (deltaX != 0 || deltaY != 0) {
                            this.socket.write("p`" + deltaX + "`" + deltaY);
                        }
                        if (this.exactPosNextUpdate) {
                            this.exactPosNextUpdate = false;
                            this.socket.write("exact_pos`" + curX + "`" + curY);
                        }
                    // }
                    }
                    if (this.lastNetScaleX != scaleX) {
                        this.lastNetScaleX = scaleX;
                        this.socket.write("set_var`scaleX`" + scaleX);
                    }
                    if (this.lastNetState != state) {
                        this.lastNetState = state;
                        this.socket.write("set_var`state`" + state);
                    }
                    if (this.prevParent != parent) {
                        this.prevParent = parent;
                        if (parent == Course.course.frontBackground) {
                            this.socket.write("set_var`parent`frontBackground");
                        } else {
                            this.socket.write("set_var`parent`backBackground");
                        }
                    }
                    if (Items.getCodeFromItem(this.curItem) != this.lastNetItem) {
                        this.lastNetItem = Items.getCodeFromItem(this.curItem);
                        this.socket.write("set_var`item`" + Items.getCodeFromItem(this.curItem));
                    }
                }
                if (velY > 0 && store.getBool(JIGG)) {
                    this.maybeSquash();
                }
                if (this.stingCooldown > 0) {
                    this.stingCooldown--;
                } else if (store.getBool(JELLYFISH) && Data.rand(1, 35) === 1) { // should happen within a second or so
                    this.maybeSting();
                }
            // }
        }

        // tells the game to send the exact player coordinates next update (in this.go)
        private function setEPNU()
        {
            this.exactPosNextUpdate = true;
        }

        private function maybeSquash()
        {
            for each (var p:Character in this.course.playerArray) {
                if (p is RemoteCharacter && p.state != "crouch" && p.state != "crouchWalk" && p.x > (x - 20) && p.x < (x + 20) && p.y > (y + 35) && p.y < (y + 65) && p.rotation == this.rotation) {
                    p.changeState("crouch");
                    SoundEffects.playGameSound(new SquashSound(), x, y, 0.66);
                    this.socket.write("squash`" + p.tempID + "`" + x + "`" + y);
                    velY = -3;
                    this.grounded = true;
                }
            }
        }
    
        // sting another player
        private function maybeSting()
        {
            for each (var p:Character in this.course.playerArray) {
                if (p is RemoteCharacter && p.state != "bumped" && p.x > (x - 75) && p.x < (x + 75) && p.y > (y - 100) && p.y < (y + 100)) {
                    Main.socket.write('sting`' + p.tempID + '`' + x + '`' + y); // remote tempID, local x, local y
                    this.stingCooldown = 135; // 5 seconds
                }
            }
        }

        private function waitGo(e:Event)
        {
            this.position();
            this.processBlocks();
        }

        private function hurtGo(e:Event)
        {
            this.targetVelX = 0;
            this.position();
            this.processBlocks();
            if (this.hurtTime <= 0) {
                this.setMode("land");
            }
        }

        private function frozenSolidGo(_arg_1:Event)
        {
            this.targetVelX = 0;
            this.position();
            this.processBlocks();
            this.updateKeys();
            if (!this.removed) {
                if (this.up && this.grounded && !this.crouching) {
                    velY = velY - store.getNumber(SuperJump);
                }
                if (!this.frozenSolid) {
                    this.setMode("land");
                } else {
                    changeState("frozenSolid");
                }
            }
        }

        private function squashedGo(e:Event)
        {
            this.crouching = true;
            this.landGo(e);
            this.squashedTime--;
            if (this.squashedTime <= 0) {
                velY = -5;
                this.setMode("land");
            }
        }

        private function freezeGo(e:Event)
        {
        }

        private function waterGo(_arg_1:Event)
        {
            this.updateKeys();
            if (this.right) {
                velX += this.accel * 0.5;
            }
            if (this.left) {
                velX -= this.accel * 0.5;
            }
            if (this.down) {
                velY += this.accel * 0.65;
            }
            if (this.up) {
                velY -= this.accel * 0.65;
            }
            velY += store.getNumber(DefaultGravity) * 0.25;
            velX *= 0.92;
            velY *= 0.92;
            velX = Data.numLimit(velX, -this.maxSpeed, this.maxSpeed);
            velY = Data.numLimit(velY, -this.maxSpeed, this.maxSpeed);
            x += velX;
            y += velY;
            this.processBlocks();
            this.waterTicks--;
            if (store.getBool(COWBOY) && !this.grounded) {
                this.waterTicks = 1;
            }
            if (this.waterTicks <= 0) {
                if (this.up) {
                    velY -= store.getNumber(SuperJump) * 0.5;
                    store.setNumber(JUMP_VEL, -(store.getNumber(SuperJump)) * 0.5);
                    this.jumpHeld = true;
                }
                this.setMode("land");
            }
        }

        private function landGo(e:Event)
        {
            this.updateKeys();
            if (this.right) {
                this.targetVelX += this.accel;
            }
            if (this.left) {
                this.targetVelX -= this.accel;
            }
            if (!this.right && !this.left) {
                this.targetVelX = 0;
            }
            if (this.up) {
                if (this.grounded && !this.crouching) {
                    this.jumpHeld = true;
                    velY = velY - store.getNumber(SuperJump);
                    store.setNumber(JUMP_VEL, -(store.getNumber(SuperJump)));
                } else {
                    if (this.jumpHeld) {
                        velY += store.getNumber(JUMP_VEL);
                        store.setNumber(JUMP_VEL, store.getNumber(JUMP_VEL) * 0.75);
                    }
                }
            } else {
                this.jumpHeld = false;
            }
            if (this.down) {
                if (!this.crouching) {
                    if (!this.grounded) {
                        velY += 0.5;
                        this.crouchCharge = 0;
                    } else {
                        if (this.crouchCharge < 100) {
                            this.crouchCharge += 2;
                        }
                        if (this.crouchCharge > 25) {
                            this.targetVelX = 0;
                        }
                    }
                }
            } else {
                if (this.crouchCharge > 25) {
                    velY = -this.crouchCharge * 0.24;
                    this.jumpHeld = false;
                    SoundEffects.playSound(new SuperJumpSound(), 1 * (Settings.soundLevel / 100));
                }
                this.crouchCharge = 0;
            }
            this.position();
            scaleY = 1;
            if (!this.grounded) {
                changeState("jump");
            } else {
                if (this.crouchCharge > 25) {
                    changeState("superJump");
                } else {
                    if (this.left || this.right) {
                        changeState(this.crouching ? 'crouchWalk' : 'run');
                    } else {
                        changeState(this.crouching ? 'crouch' : 'stand');
                    }
                }
            }
            this.processBlocks();
            if (store.getBool(COWBOY) && !this.grounded) {
                this.waterTicks = 2;
                this.setMode("water");
                changeState("swim");
            }
        }

        private function updateKeys()
        {
            this.up = this.down = this.right = this.left = this.space = false;
            if (Main.stage.focus == null || Main.stage.focus != RaceChat.textBox) {
                if (Keys.isPressed(Keyboard.RIGHT) || Keys.isPressed(this.altCtrl.right)) {
                    this.right = true;
                    scaleX = 1;
                }
                if (Keys.isPressed(Keyboard.LEFT) || Keys.isPressed(this.altCtrl.left)) {
                    this.left = true;
                    scaleX = -1;
                }
                if (Keys.isPressed(Keyboard.UP) || Keys.isPressed(this.altCtrl.up)) {
                    this.up = true;
                }
                if (Keys.isPressed(Keyboard.DOWN) || Keys.isPressed(this.altCtrl.down)) {
                    this.down = true;
                }
                if (Keys.isPressed(Keyboard.SPACE) || Keys.isPressed(this.altCtrl.item)) {
                    this.space = true;
                }
            }
            if (reversedControls) {
                var tempRight:Boolean = this.right;
                this.right = this.left;
                this.left = tempRight;
            }
            if (this.curItem != null) {
                this.curItem.setSpace(this.curItem is JetPack && this.crouching ? false : this.space);
            }
        }

        private function position()
        {
            if (this.map != null) {
                if (this.course != null && parent != this.course.frontBackground) {
                    this.course.frontBackground.addChild(this);
                }
                velY += store.getNumber(GravityMultiplied);
                if (this.up && store.getBool(PROP) && velY > 0) {
                    velY *= 0.85;
                }
                this.targetVelX *= this.friction;
                if (this.crouching) {
                    this.targetVelX *= 0.7;
                }
                this.targetVelX = Data.numLimit(this.targetVelX, -this.maxVelX, this.maxVelX);
                var _local_1:Number = Math.abs(velX) / this.maxSpeed;
                _local_1 = 1 - _local_1;
                _local_1 *= 0.9;
                _local_1 += 0.1;
                this.accelFactor *= this.frozenSolid ? 0 : _local_1;
                velX += (this.targetVelX - velX) * this.accelFactor;
                velX = Data.numLimit(velX, -this.maxSpeed, this.maxSpeed);
                velY = Data.numLimit(velY, -this.maxSpeed, this.maxSpeed);
                x += velX;
                y += velY;
                var _local_2:Point = Data.rotatePoint(x, y, this.map.rotation);
                var _local_3:int = 500;
                if ((_local_2.y > this.map.maxY + _local_3 && this.map.rotation == 0) || (_local_2.y < this.map.minY - _local_3 && Math.abs(this.map.rotation) == 180) || (_local_2.x > this.map.maxX + _local_3 && this.map.rotation == 90) || (_local_2.x < this.map.minX - _local_3 && this.map.rotation == -90)) {
                    this.returnToLastSafeSpot();
                }
                if (this.course.gameMode === Modes.hat && this.course.looseHats.length > 0) {
                    this.checkLooseHats();
                }
                this.accelFactor = this.baseAccelFactor;
                this.velFactor = this.baseVelFactor;
            }
        }

        public function returnToLastSafeSpot()
        {
            x = this.lastSafeX;
            y = this.lastSafeY;
            velX = 0;
            velY = 0;
            this.bumpPlayer();
        }

        private function checkLooseHats()
        {
            for each (var hat:Hat in this.course.looseHats) {
                var hatPos:Point = hat.getPos();
                var hatRot:int = hat.getRot();
                hatPos = Data.rotatePoint(hatPos.x, hatPos.y, hatRot);
                if ((hatPos.y > this.map.maxY + 500 && hatRot == 0) || (hatPos.y < this.map.minY - 500 && Math.abs(hatRot) == 180) || (hatPos.x > this.map.maxX + 500 && hatRot == 90) || (hatPos.x < this.map.minX - 500 && hatRot == -90)) {
                    this.returnHatToStart(hat.getId());
                }
            }
        }

        private function returnHatToStart(id:int)
        {
            var hat:Hat = this.course.looseHats[id];
            if (hat != null) {
                hat.returningToStart();
                Main.socket.write('hat_to_start`' + id);
            }
        }

        // _loc1 = topBlock
        // _loc2 = botBlock
        // _loc4 = yPriorToBump
        private function processBlocks()
        {
            if (this.map != null) {
                this.refreshBlockRefs();
                this.updateGrounded();
                if (store.getBool(SANTA)) {
                    var _local_3:Block = this.map.getBlockFromPos(x, y, true);
                    if (_local_3 != null && ((_local_3 is WaterBlock && this.mode != "water") || _local_3 is SafetyBlock)) {
                        _local_3.onStand(this);
                    }
                }
                if (velX >= -1) {
                    if (this.wallRight != null && this.getBlock(this.wallRight.getPosX() - 30, this.wallRight.getPosY()) == null) {
                        this.wallRight.onLeftHit(this);
                        this.refreshBlockRefs();
                    }
                }
                if (velX <= 1) {
                    if (this.wallLeft != null && this.getBlock(this.wallLeft.getPosX() + 30, this.wallLeft.getPosY()) == null) {
                        this.wallLeft.onRightHit(this);
                        this.refreshBlockRefs();
                    }
                }
                if (velY < 0) {
                    if (this.grounded) {
                        this.crouching = true;
                    }
                    if (this.mode != "water" && this.ceiling != null && this.getBlock(this.ceiling.getPosX(), this.ceiling.getPosY() + 30) == null) {
                        this.ceiling.onBump(this);
                        this.refreshBlockRefs();
                    } else {
                        if (this.mode != "water" && this.headBlock != null && this.getBlock(this.headBlock.getPosX(), this.headBlock.getPosY() + 30) == null) {
                            this.headBlock.onBump(this);
                            this.refreshBlockRefs();
                        } else {
                            if (this.topBlock != null && this.getBlock(this.topBlock.getPosX(), this.topBlock.getPosY() + 30) == null) {
                                this.topBlock.onBump(this);
                                this.refreshBlockRefs();
                            }
                        }
                    }
                }
                if (!this.grounded) {
                    this.updateGrounded();
                }
                var topBlock:Block = null;
                var botBlock:Block = null;
                this.crouching = false;
                if (this.grounded == true) {
                    topBlock = this.getBlock(x, y - 40); // blockAbove? top half of character
                    botBlock = this.getBlock(x, y - 10); // blockAtBody? bottom half of character
                    if (topBlock != null && botBlock == null) {
                        this.crouching = true;
                        if (this.up) {
                            var yPriorToBump:Number = y;
                            topBlock.onBump(this);
                            y = !(topBlock is TeleportBlock) ? yPriorToBump : y;
                            velY = 0;
                        }
                        if (velY < 0) {
                            velY = 0;
                        }
                    }
                }
                topBlock = this.map.getBlockFromPos(x, y - 15, true);
                if (topBlock != null) {
                    topBlock.onTouch(this);
                }
                if (!this.crouching) {
                    topBlock = this.map.getBlockFromPos(x, y - 45, true);
                    if (topBlock != null) {
                        topBlock.onTouch(this);
                    }
                }
            }
        }

        private function updateGrounded()
        {
            if (this.floorCenter != null && this.ceiling == null) {
                this.floorCenter.onStand(this);
                this.refreshBlockRefs();
                this.grounded = true;
            } else {
                this.grounded = false;
            }
        }

        private function refreshBlockRefs()
        {
            //var _local_1:Number = y; // not needed?
            if (y < 0) {
                y += 0.001;
            }
            this.floorLeft = this.getBlock(x - this.halfWidth, y, true, true);
            this.floorCenter = this.getBlock(x, y, true, true);
            this.floorRight = this.getBlock(x + this.halfWidth, y, true, true);
            this.wallLeft = this.getBlock(x - this.halfWidth, y - 10);
            this.midBlock = this.getBlock(x, y - 10);
            this.wallRight = this.getBlock(x + this.halfWidth, y - 10);
            this.ceilLeft = this.getBlock(x - this.halfWidth, y - 30);
            this.ceiling = this.getBlock(x, y - 30);
            this.ceilRight = this.getBlock(x + this.halfWidth, y - 30);
            this.headBlock = this.getBlock(x, y - this.charHeight + 30);
            this.topBlock = this.getBlock(x, y - this.charHeight);
        }

        // _loc5 = block
        private function getBlock(_arg_1:Number, _arg_2:Number, _arg_3:Boolean=true, _arg_4:Boolean=false):Block
        {
            if (this.map != null) {
                var block:Block = this.map.getBlockFromPos(_arg_1, _arg_2, _arg_3);
                if (block == null || !block.isActive() || (store.getBool(TOP) && block is VanishBlock && !_arg_4)) {
                    return null;
                }
                return block;
            }
            return null;
        }

        // removed _loc2; not used
        public function setMode(str:String)
        {
            if (this.mode != str) {
                removeEventListener(Event.ENTER_FRAME, this[this.mode + "Go"]);
                addEventListener(Event.ENTER_FRAME, this[str + "Go"], false, 0, true);
                this.mode = str;
                this.targetVelX = 0;
                if (this.mode == "hurt") {
                    changeState("bumped");
                    this.bumpPlayer();
                }
                if (this.mode == "water" && this.state != "bumped") {
                    changeState("swim");
                }
                if (this.mode == "squashed") {
                    this.squashedTime = 60;
                    beginRecovery(70);
                }
            }
        }

        private function bumpPlayer()
        {
            if (this.hurtTime <= 0) {
                this.hurtTime = 60;
                beginRecovery(65);
                if (this.course.gameMode == "deathmatch") {
                    this.life--;
                    this.setLife(this.life);
                    if (this.life <= 0) {
                        this.course.finish();
                    }
                }
            }
        }

        override public function gainHeart()
        {
            super.gainHeart();
            this.life++;
            this.setLife(this.life);
            Main.socket.write("heart`");
        }

        public function setLife(l:int)
        {
            this.life = Data.numLimit(l, 0, 15);
            this.course.setLife(this.life);
        }

        override public function becomeInvincible(duration:int)
        {
            super.becomeInvincible(duration);
            this.hurtTime = duration;
            this.invincible = true;
        }

        override protected function endRecovery()
        {
            super.endRecovery();
            this.invincible = false;
        }

        // _loc3 = hat
        public function hit(_arg_1:Number=0, _arg_2:Number=0)
        {
            if ((!store.getBool(CROWN) || this.course.gameMode == Modes.dm || this.course.gameMode == Modes.hat) && !this.invincible) {
                velX += _arg_1;
                velY += _arg_2;
                if (!store.getBool(CROWN)) {
                    beginRecovery(50);
                    if (!this.frozenSolid) {
                        this.setMode("hurt");
                    }
                }
                if (this.map != null && !this.testMode) {
                    var hat:Object = getHighestHat();
                    if (hat.hatNum != 1 && hat.hatNum != 0 && hat.hatNum != null) {
                        Main.socket.write("loose_hat`" + x + "`" + (y - 50) + "`" + this.map.rotation);
                    }
                }
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            this.lastSafeX = _arg_1;
            this.lastSafeY = _arg_2;
            super.setPos(_arg_1, _arg_2);
            this.exactX = _arg_1;
            this.exactY = _arg_2;
            this.exactPosNextUpdate = true;
            Course.course.posX = -_arg_1;
            Course.course.posY = -_arg_2;
            Course.course.setPos(-_arg_1, -_arg_2);
        }

        override public function setItem(code:int)
        {
            super.setItem(code);
            if (this.itemDisplay != null) {
                this.itemDisplay.setItem(Items.getNameFromCode(code));
            }
            if (this.curItem != null) {
                if (code == Items.jetPack && this.curItem is JetPack) {
                    this.curItem.replenishFuel(this);
                    return;
                } else {
                    this.curItem.remove();
                    this.curItem = null;
                }
            }
            this.curItem = Items.getFromCode(code, this);
        }

        public function setAmmo(_arg_1:int)
        {
            if (_arg_1 > 3) {
                _arg_1 = 0;
                while (true) {
                    Math.random();
                }
            }
            if (this.itemDisplay != null) {
                this.itemDisplay.setAmmo(_arg_1);
            }
        }

        public function setRotation(r:Number)
        {
            rotation = Math.round(r);
            this.socket.write("set_var`rotMod`" + rotation);
        }

        // _loc2 = tmpLSX
        // _loc3 = tmpLSY
        override public function rotate(direction:String)
        {
            super.rotate(direction);
            var tmpLSX:Number, tmpLSY:Number;
            if (direction == 'right') {
                tmpLSX = -this.lastSafeY;
                tmpLSY = this.lastSafeX;
            } else {
                tmpLSX = this.lastSafeY;
                tmpLSY = -this.lastSafeX;
            }
            this.lastSafeX = tmpLSX;
            this.lastSafeY = tmpLSY;
            this.setMode("land");
            this.course.posX = -x;
            this.course.posY = -y + 50;
            this.course.setPos(-x, -y + 50);
            this.socket.write("set_var`rot`" + -this.map.rotation);
            this.exactPosNextUpdate = true;
        }

        // this function originally returned if the positions of players should be updated instantly (within 1000px of the player)
        // since that functionality is disabled, the function has been simplified to return if there are other players present
        private function playersInPosUpdateRange():Boolean
        {
            
            // for each (var c:Character in Course.course.playerArray) {
                // uncommenting below disables near-instant updates for other players when farther than 1000px in either direction
                // if (c != this /*&& Math.abs(c.x - x) < 1000 && Math.abs(c.y - y) < 1000*/) {
                    /*return true;
                }
            }*/
            return Course.course.playerArray.length > 1;
        }

        override public function beginSparkles(ms:int = 5000)
        {
            this.socket.write("set_var`sparkle`1");
            super.beginSparkles(ms);
        }

        override public function endSparkles(used:Boolean = false)
        {
            this.socket.write("set_var`sparkle`0");
            super.endSparkles(used);
        }

        override public function beginJet()
        {
            this.socket.write("set_var`jet`1");
            super.beginJet();
        }

        override public function endJet()
        {
            this.socket.write("set_var`jet`0");
            super.endJet();
        }

        override public function beginRemove()
        {
            if (this.socket != null) {
                this.setMode("freeze");
                this.socket.write("set_var`beginRemove`1");
                super.beginRemove();
            }
        }

        // _loc2 = hadJS
        // _loc3 = hadCB
        // _loc4 = hadSanta
        // _loc5 = hadArti
        // _loc6 = cTimer
        // _loc7 = zap
        override public function setHats(_arg_1:Array)
        {
            var hadJS:Boolean = store.getBool(JUMP_START);
            var hadCB:Boolean = store.getBool(COWBOY);
            var hadMoon:Boolean = store.getBool(MOON);
            var hadSanta:Boolean = store.getBool(SANTA);
            var hadArti:Boolean = store.getBool(ARTIFACT);
            var sbNotUsed:Boolean = Items.getCodeFromItem(this.curItem) != Items.speedBurst || (Items.getCodeFromItem(this.curItem) == Items.speedBurst && !this.curItem.isUsed());
            super.setHats(_arg_1);
            if (hadMoon && !store.getBool(MOON)) {
                this.resetGravity();
            }
            if (hadCB && !store.getBool(COWBOY) && sbNotUsed) {
                this.resetStats();
            }
            if (hadSanta && !store.getBool(SANTA) && sbNotUsed) {
                this.resetStats();
            }
            if (hadArti && !store.getBool(ARTIFACT)) {
                if (Items.getCodeFromItem(this.curItem) == Items.speedBurst) {
                    this.setItem(0);
                }
                if (Data.getDateStr(new Date().getTime()) !== "Apr 1") {
                    reversedControls = false; // preserve reversed controls on Apr 1
                }
            }
            this.ensureCowboyStats();
            if (store.getBool(SANTA)) {
                if (!hadSanta) {
                    this.ensureSantaStats();
                }
            }
            if (store.getBool(JUMP_START)) {
                if (!hadJS) {
                    this.setItem(Items.speedBurst);
                    SpeedBurst(this.curItem).duration = 2000;
                    this.curItem.useItem();
                }
            }
            if (store.getBool(MOON)) {
                if (!hadMoon) {
                    this.setGravity(GamePage.course.gravity * .85);
                }
            }
            if (store.getBool(ARTIFACT)) {
                if (!hadArti) {
                    this.setItem(Items.speedBurst);
                    SpeedBurst(this.curItem).duration = 30000;
                    this.curItem.useItem();
                    var cTimer:CourseTimer = Course.course.timer;
                    if (cTimer.getMS() > 30) {
                        cTimer.setTime(30);
                        cTimer.init();
                    }
                    var zap:Zap = new Zap(this, false, false);
                    zap.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0xFF, 0);
                    SoundEffects.playSound(new YeahSound(), 1 * (Settings.soundLevel / 100));
                    Course.course.musicSelection.dropdown.gotArtifact();
                    reversedControls = true;
                }
            }
        }

        private function ensureCowboyStats()
        {
            if (store.getBool(COWBOY)) {
                this.maxVelX = this.maxVelX < 12 ? 12 : this.maxVelX;
                this.accel = this.accel < 1.86 ? 1.86 : this.accel;
                store.setNumber(SuperJump, 4.5);
            }
        }

        private function ensureSantaStats()
        {
            if (store.getBool(SANTA)) {
                this.maxVelX += 1;
            }
        }

        public function isFrozen():Boolean
        {
            return this.frozenSolid;
        }

        public function freeze()
        { // typo fixed from: this.mode != "frozenSolod"
            if (this.mode != "frozenSolid" && state != "frozenSolid" && !this.frozenSolid) {
                this.frozenSolid = true;
                clearTimeout(this.unfreezeTimer);
                this.unfreezeTimer = setTimeout(this.unfreeze, 2000);
                this.setMode("frozenSolid");
            }
        }

        private function unfreeze()
        {
            clearTimeout(this.unfreezeTimer);
            this.frozenSolid = false;
        }

        public function inLE()
        {
            return this.course is TestCourse;
        }

        override protected function removeListeners()
        {
            super.removeListeners();
            removeEventListener(Event.ENTER_FRAME, this.landGo);
            removeEventListener(Event.ENTER_FRAME, this.waitGo);
            removeEventListener(Event.ENTER_FRAME, this.hurtGo);
            removeEventListener(Event.ENTER_FRAME, this.squashedGo);
            removeEventListener(Event.ENTER_FRAME, this.freezeGo);
            removeEventListener(Event.ENTER_FRAME, this.waterGo);
            removeEventListener(Event.ENTER_FRAME, this.go);
            clearInterval(this.epnuInterval);
            clearInterval(this.cowboyCheckInterval);
            clearTimeout(this.unfreezeTimer);
        }

        override public function remove()
        {
            this.setItem(0);
            this.socket = null;
            if (this.cm != null) {
                this.cm.defineCommand("setHats" + tempID.toString(), null);
                this.cm.defineCommand("zap", null);
                this.cm.defineCommand("squash" + tempID.toString(), null);
                this.cm.defineCommand("sting" + this.tempID.toString(), null);
                this.cm = null;
            }
            this.course = null;
            this.map = null;
            if (this.mapDot != null) {
                if (this.mapDot.parent != null) {
                    this.mapDot.parent.removeChild(this.mapDot);
                }
                this.mapDot = null;
            }
            this.itemDisplay = null;
            this.prevParent = null;
            this.curItem = null;
            super.remove();
        }


    }
}
