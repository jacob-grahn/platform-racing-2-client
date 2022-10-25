// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_8.class_86 = package_8.LocalCharacter

package package_8
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
    import package_6.ItemDisplay;
    import package_6.CourseTimer;
    import package_6.Course;
    import package_6.Modes;
    import package_6.RaceChat;
    import package_6.TestCourse;
    import package_9.Hat;
    import package_9.Sting;
    import package_9.Zap;
    import page.GamePage;

    public class LocalCharacter extends Character 
    {

        public static const const_12:String = "njv";
        public static const SuperJump:String = "nj";
        public static const DefaultGravity:String = "gr"; // const_53
        public static const GravityMultiplied:String = "grm"; // const_59

        private var socket:PR2Socket = Main.socket;
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var course:Course;
        private var map:Map;
        private var mapDot:MiniMapDot; // var_174
        private var itemDisplay:ItemDisplay;
        private var var_573:uint = setInterval(setEPNU, 5000);
        private var var_535:uint = setInterval(ensureCowboyStats, 250);
        private var var_390:DisplayObject = parent;
        private var speedStat:int; // var_245
        private var accelStat:int; // var_261
        private var jumpnStat:int; // var_247
        public var accel:Number;
        public var maxVelX:Number;
        public var var_24:Number = 0;
        public var var_669:Number = 0;
        private var var_523:Number = 0.35;
        private var var_599:Number = 1;
        public var var_147:Number = var_523;
        public var var_524:Number = var_599;
        public var var_189:Number = 10;
        public var var_325:Number = 55;
        public var lastSafeX:Number = 0; // var_205
        public var lastSafeY:Number = 0; // var_224
        public var var_407:int;
        public var var_366:int;
        public var var_157:Number = 28;
        private var initialized:Boolean = false;
        public var testMode:Boolean = false;
        public var grounded:Boolean = false; // var_42
        public var crouching:Boolean = false;
        public var up:Boolean = false;
        public var down:Boolean = false;
        public var right:Boolean = false;
        public var left:Boolean = false;
        public var space:Boolean = false;
        private var friction:Number = 0.985;
        private var var_281:Boolean = false;
        private var var_150:Number = 0;
        private var segSize:Number = 30;
        private var hurtTime:Number = 0; // var_249
        private var squashedTime:Number = 0; // var_368
        private var stingCooldown:int = 135;
        public var var_240:Number = 0;
        private var var_630:Block = null;
        private var var_469:Block = null;
        private var var_657:Block = null;
        private var var_329:Block = null;
        private var var_658:Block = null;
        private var var_296:Block = null;
        private var var_654:Block = null;
        private var var_262:Block = null;
        private var var_631:Block = null;
        private var var_306:Block = null;
        private var var_297:Block = null;
        public var mode:String = "wait";
        private var curItem:Item; // var_99 | removed (unused): var_680:LaserGun, var_674:Mine, superJump:SuperJump, lightning:Lightning, var_682:Teleport, jetPack:JetPack, sword:Sword
        private var speedBurst:SpeedBurst; // var_668
        private var life:int = 3;
        private var invincible:Boolean = false; // var_435
        private var frozenSolid:Boolean = false;
        private var unfreezeTimer:uint; // var_340
        private var var_530:Number;
        private var exactX:int; // var_443
        private var exactY:int; // var_453
        private var var_577:String;
        private var var_623:int;
        private var exactPosNextUpdate:Boolean = false; // var_232
        private var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);
        private var startingStats:Array = null;

        public function LocalCharacter(tId:int, c:Course, ma:Map, dot:MovieClip, itd:ItemDisplay, grav:Number, s:int=50, a:int=50, j:int=50, ha:int=1, h:int=1, b:int=1, f:int=1, groupStr:String = '0')
        {
            super(ha, h, b, f);
            var_4.setNumber(const_12, 0);
            var_4.setNumber(SuperJump, 0);
            var_4.setNumber(DefaultGravity, 0.7);
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

        // method_46 = setStats
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
            var_4.setNumber(SuperJump, 2 + (this.jumpnStat / 40));
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

        // method_392 = statsChange
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
            var_4.setNumber(GravityMultiplied, var_4.getNumber(DefaultGravity) * _arg_1);
        }

        private function resetGravity()
        {
            var_4.setNumber(GravityMultiplied, var_4.getNumber(DefaultGravity) * GamePage.course.gravity);
        }

        // method_799 = squash
        public function squash(a:Array)
        {
            if (this.mode != "squashed" && var_269 <= 0) {
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
            if (!var_4.getBool(PARTY) && !var_4.getBool(JELLYFISH)) {
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
                if (!var_4.getBool(PARTY)) {
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
                var curPos:Point = Data.method_9(curX, curY, this.map.rotation);
                this.mapDot.x = curPos.x;
                this.mapDot.y = curPos.y;
            }
            method_58(this.map.rotation);
            this.hurtTime--;
            if (this.course.playerArray.length > 1) {
                var_215++; // setting this to a static value greater than 16 (formerly 23) will send wholly instant position updates to players
                if (var_215 >= var_448) {
                    if (this.playersInPosUpdateRange() || var_215 >= 16) {//23) {
                        var_215 = 0;
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
                    if (this.var_530 != scaleX) {
                        this.var_530 = scaleX;
                        this.socket.write("set_var`scaleX`" + scaleX);
                    }
                    if (this.var_577 != state) {
                        this.var_577 = state;
                        this.socket.write("set_var`state`" + state);
                    }
                    if (this.var_390 != parent) {
                        this.var_390 = parent;
                        if (parent == Course.course.frontBackground) {
                            this.socket.write("set_var`parent`frontBackground");
                        } else {
                            this.socket.write("set_var`parent`backBackground");
                        }
                    }
                    if (Items.getCodeFromItem(this.curItem) != this.var_623) {
                        this.var_623 = Items.getCodeFromItem(this.curItem);
                        this.socket.write("set_var`item`" + Items.getCodeFromItem(this.curItem));
                    }
                }
                if (velY > 0 && var_4.getBool(JIGG)) {
                    this.maybeSquash();
                }
                if (this.stingCooldown > 0) {
                    this.stingCooldown--;
                } else if (var_4.getBool(JELLYFISH) && Data.rand(1, 35) === 1) { // should happen within a second or so
                    this.maybeSting();
                }
            }
        }

        // tells the game to send the exact player coordinates next update (in this.go)
        // method_796 = setEPNU
        private function setEPNU()
        {
            this.exactPosNextUpdate = true;
        }

        // _loc1 = p
        // method_704 = maybeSquash
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
            this.method_76();
        }

        private function hurtGo(e:Event)
        {
            this.var_24 = 0;
            this.position();
            this.method_76();
            if (this.hurtTime <= 0) {
                this.setMode("land");
            }
        }

        private function frozenSolidGo(_arg_1:Event)
        {
            this.var_24 = 0;
            this.position();
            this.method_76();
            this.updateKeys();
            if (!this.removed) {
                if (this.up && this.grounded && !this.crouching) {
                    velY = velY - var_4.getNumber(SuperJump);
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
            velY += var_4.getNumber(DefaultGravity) * 0.25;
            velX *= 0.92;
            velY *= 0.92;
            velX = Data.numLimit(velX, -this.var_157, this.var_157);
            velY = Data.numLimit(velY, -this.var_157, this.var_157);
            x += velX;
            y += velY;
            this.method_76();
            this.var_240--;
            if (var_4.getBool(COWBOY) && !this.grounded) {
                this.var_240 = 1;
            }
            if (this.var_240 <= 0) {
                if (this.up) {
                    velY -= var_4.getNumber(SuperJump) * 0.5;
                    var_4.setNumber(const_12, -(var_4.getNumber(SuperJump)) * 0.5);
                    this.var_281 = true;
                }
                this.setMode("land");
            }
        }

        private function landGo(e:Event)
        {
            this.updateKeys();
            if (this.right) {
                this.var_24 += this.accel;
            }
            if (this.left) {
                this.var_24 -= this.accel;
            }
            if (!this.right && !this.left) {
                this.var_24 = 0;
            }
            if (this.up) {
                if (this.grounded && !this.crouching) {
                    this.var_281 = true;
                    velY = velY - var_4.getNumber(SuperJump);
                    var_4.setNumber(const_12, -(var_4.getNumber(SuperJump)));
                } else {
                    if (this.var_281) {
                        velY += var_4.getNumber(const_12);
                        var_4.setNumber(const_12, var_4.getNumber(const_12) * 0.75);
                    }
                }
            } else {
                this.var_281 = false;
            }
            if (this.down) {
                if (!this.crouching) {
                    if (!this.grounded) {
                        velY += 0.5;
                        this.var_150 = 0;
                    } else {
                        if (this.var_150 < 100) {
                            this.var_150 += 2;
                        }
                        if (this.var_150 > 25) {
                            this.var_24 = 0;
                        }
                    }
                }
            } else {
                if (this.var_150 > 25) {
                    velY = -this.var_150 * 0.24;
                    this.var_281 = false;
                    SoundEffects.playSound(new SuperJumpSound(), 1 * (Settings.soundLevel / 100));
                }
                this.var_150 = 0;
            }
            this.position();
            scaleY = 1;
            if (!this.grounded) {
                changeState("jump");
            } else {
                if (this.var_150 > 25) {
                    changeState("superJump");
                } else {
                    if (this.left || this.right) {
                        changeState(this.crouching ? 'crouchWalk' : 'run');
                    } else {
                        changeState(this.crouching ? 'crouch' : 'stand');
                    }
                }
            }
            this.method_76();
            if (var_4.getBool(COWBOY) && !this.grounded) {
                this.var_240 = 2;
                this.setMode("water");
                changeState("swim");
            }
        }

        // _loc1 = tempRight
        // method_193 = updateKeys
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
                velY += var_4.getNumber(GravityMultiplied);
                if (this.up && var_4.getBool(PROP) && velY > 0) {
                    velY *= 0.85;
                }
                this.var_24 *= this.friction;
                if (this.crouching) {
                    this.var_24 *= 0.7;
                }
                this.var_24 = Data.numLimit(this.var_24, -this.maxVelX, this.maxVelX);
                var _local_1:Number = Math.abs(velX) / this.var_157;
                _local_1 = 1 - _local_1;
                _local_1 *= 0.9;
                _local_1 += 0.1;
                this.var_147 *= this.frozenSolid ? 0 : _local_1;
                velX += (this.var_24 - velX) * this.var_147;
                velX = Data.numLimit(velX, -this.var_157, this.var_157);
                velY = Data.numLimit(velY, -this.var_157, this.var_157);
                x += velX;
                y += velY;
                var _local_2:Point = Data.method_9(x, y, this.map.rotation);
                var _local_3:int = 500;
                if ((_local_2.y > this.map.maxY + _local_3 && this.map.rotation == 0) || (_local_2.y < this.map.minY - _local_3 && Math.abs(this.map.rotation) == 180) || (_local_2.x > this.map.maxX + _local_3 && this.map.rotation == 90) || (_local_2.x < this.map.minX - _local_3 && this.map.rotation == -90)) {
                    this.returnToLastSafeSpot();
                }
                if (this.course.gameMode === Modes.hat && this.course.looseHats.length > 0) {
                    this.checkLooseHats();
                }
                this.var_147 = this.var_523;
                this.var_524 = this.var_599;
            }
        }

        // method_216 = returnToLastSafeSpot
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
                hatPos = Data.method_9(hatPos.x, hatPos.y, hatRot);
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
        private function method_76()
        {
            if (this.map != null) {
                this.method_41();
                this.method_261();
                if (var_4.getBool(SANTA)) {
                    var _local_3:Block = this.map.getBlockFromPos(x, y, true);
                    if (_local_3 != null && ((_local_3 is WaterBlock && this.mode != "water") || _local_3 is SafetyBlock)) {
                        _local_3.onStand(this);
                    }
                }
                if (velX >= -1) {
                    if (this.var_296 != null && this.getBlock(this.var_296.getPosX() - 30, this.var_296.getPosY()) == null) {
                        this.var_296.onLeftHit(this);
                        this.method_41();
                    }
                }
                if (velX <= 1) {
                    if (this.var_329 != null && this.getBlock(this.var_329.getPosX() + 30, this.var_329.getPosY()) == null) {
                        this.var_329.onRightHit(this);
                        this.method_41();
                    }
                }
                if (velY < 0) {
                    if (this.grounded) {
                        this.crouching = true;
                    }
                    if (this.mode != "water" && this.var_262 != null && this.getBlock(this.var_262.getPosX(), this.var_262.getPosY() + 30) == null) {
                        this.var_262.onBump(this);
                        this.method_41();
                    } else {
                        if (this.mode != "water" && this.var_306 != null && this.getBlock(this.var_306.getPosX(), this.var_306.getPosY() + 30) == null) {
                            this.var_306.onBump(this);
                            this.method_41();
                        } else {
                            if (this.var_297 != null && this.getBlock(this.var_297.getPosX(), this.var_297.getPosY() + 30) == null) {
                                this.var_297.onBump(this);
                                this.method_41();
                            }
                        }
                    }
                }
                if (!this.grounded) {
                    this.method_261();
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

        private function method_261()
        {
            if (this.var_469 != null && this.var_262 == null) {
                this.var_469.onStand(this);
                this.method_41();
                this.grounded = true;
            } else {
                this.grounded = false;
            }
        }

        private function method_41()
        {
            //var _local_1:Number = y; // not needed?
            if (y < 0) {
                y += 0.001;
            }
            this.var_630 = this.getBlock(x - this.var_189, y, true, true);
            this.var_469 = this.getBlock(x, y, true, true);
            this.var_657 = this.getBlock(x + this.var_189, y, true, true);
            this.var_329 = this.getBlock(x - this.var_189, y - 10);
            this.var_658 = this.getBlock(x, y - 10);
            this.var_296 = this.getBlock(x + this.var_189, y - 10);
            this.var_654 = this.getBlock(x - this.var_189, y - 30);
            this.var_262 = this.getBlock(x, y - 30);
            this.var_631 = this.getBlock(x + this.var_189, y - 30);
            this.var_306 = this.getBlock(x, y - this.var_325 + 30);
            this.var_297 = this.getBlock(x, y - this.var_325);
        }

        // _loc5 = block
        private function getBlock(_arg_1:Number, _arg_2:Number, _arg_3:Boolean=true, _arg_4:Boolean=false):Block
        {
            if (this.map != null) {
                var block:Block = this.map.getBlockFromPos(_arg_1, _arg_2, _arg_3);
                if (block == null || !block.isActive() || (var_4.getBool(TOP) && block is VanishBlock && !_arg_4)) {
                    return null;
                }
                return block;
            }
            return null;
        }

        // removed _loc2; not used
        public function setMode(str:String)
        {
            if (this.mode != str && this.mode != "freeze") {
                removeEventListener(Event.ENTER_FRAME, this[this.mode + "Go"]);
                addEventListener(Event.ENTER_FRAME, this[str + "Go"], false, 0, true);
                this.mode = str;
                this.var_24 = 0;
                if (this.mode == "hurt") {
                    changeState("bumped");
                    this.bumpPlayer();
                }
                if (this.mode == "water" && this.state != "bumped") {
                    changeState("swim");
                }
                if (this.mode == "squashed") {
                    this.squashedTime = 60;
                    method_51(70);
                }
            }
        }

        // method_448 = bumpPlayer
        private function bumpPlayer()
        {
            if (this.hurtTime <= 0) {
                this.hurtTime = 60;
                method_51(65);
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
            if ((!var_4.getBool(CROWN) || this.course.gameMode == Modes.dm || this.course.gameMode == Modes.hat) && !this.invincible) {
                velX += _arg_1;
                velY += _arg_2;
                if (!var_4.getBool(CROWN)) {
                    method_51(50);
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

        // method_483 = setRotation
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
        //
        // deleted _loc1 (Course.course.playerArray)
        // deleted _loc2 (return values)
        // _loc3 = c
        // method_779 = playersInPosUpdateRange
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
            var hadJS:Boolean = var_4.getBool(JUMP_START);
            var hadCB:Boolean = var_4.getBool(COWBOY);
            var hadMoon:Boolean = var_4.getBool(MOON);
            var hadSanta:Boolean = var_4.getBool(SANTA);
            var hadArti:Boolean = var_4.getBool(ARTIFACT);
            var sbNotUsed:Boolean = Items.getCodeFromItem(this.curItem) != Items.speedBurst || (Items.getCodeFromItem(this.curItem) == Items.speedBurst && !this.curItem.isUsed());
            super.setHats(_arg_1);
            if (hadMoon && !var_4.getBool(MOON)) {
                this.resetGravity();
            }
            if (hadCB && !var_4.getBool(COWBOY) && sbNotUsed) {
                this.resetStats();
            }
            if (hadSanta && !var_4.getBool(SANTA) && sbNotUsed) {
                this.resetStats();
            }
            if (hadArti && !var_4.getBool(ARTIFACT)) {
                if (Items.getCodeFromItem(this.curItem) == Items.speedBurst) {
                    this.setItem(0);
                }
                if (Data.getDateStr(new Date().getTime()) !== "Apr 1") {
                    reversedControls = false; // preserve reversed controls on Apr 1
                }
            }
            this.ensureCowboyStats();
            if (var_4.getBool(SANTA)) {
                if (!hadSanta) {
                    this.ensureSantaStats();
                }
            }
            if (var_4.getBool(JUMP_START)) {
                if (!hadJS) {
                    this.setItem(Items.speedBurst);
                    SpeedBurst(this.curItem).duration = 2000;
                    this.curItem.useItem();
                }
            }
            if (var_4.getBool(MOON)) {
                if (!hadMoon) {
                    this.setGravity(GamePage.course.gravity * .85);
                }
            }
            if (var_4.getBool(ARTIFACT)) {
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

        // method_358 = ensureCowboyStats
        private function ensureCowboyStats()
        {
            if (var_4.getBool(COWBOY)) {
                this.maxVelX = this.maxVelX < 12 ? 12 : this.maxVelX;
                this.accel = this.accel < 1.86 ? 1.86 : this.accel;
                var_4.setNumber(SuperJump, 4.5);
            }
        }

        private function ensureSantaStats()
        {
            if (var_4.getBool(SANTA)) {
                this.maxVelX += 1;
            }
        }

        // method_608 = isFrozen
        public function isFrozen():Boolean
        {
            return this.frozenSolid;
        }

        // method_664 = freeze
        public function freeze()
        { // typo fixed from: this.mode != "frozenSolod"
            if (this.mode != "frozenSolid" && state != "frozenSolid" && !this.frozenSolid) {
                this.frozenSolid = true;
                clearTimeout(this.unfreezeTimer);
                this.unfreezeTimer = setTimeout(this.unfreeze, 2000);
                this.setMode("frozenSolid");
            }
        }

        // method_591 = unfreeze
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
            clearInterval(this.var_573);
            clearInterval(this.var_535);
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
            this.var_390 = null;
            this.curItem = null;
            super.remove();
        }


    }
}
