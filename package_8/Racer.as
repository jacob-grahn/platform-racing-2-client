// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_8.class_86 = package_8.Racer

package package_8
{
    import background.Map;
    import blocks.Block;
    import blocks.SafetyBlock;
    import blocks.VanishBlock;
    import blocks.WaterBlock;
    import data.class_28;
    import data.CommandHandler;
    import data.PR2Socket;
    import data.Settings;
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
	import items.SpeedBurst;
    import sounds.SoundEffects;
    import package_6.ItemDisplay;
    import package_6.CourseTimer;
    import package_6.Course;
    import package_6.RaceChat;
    import package_9.Zap;
    import page.GamePage;

    public class Racer extends Character 
    {

        public static const const_12:String = "njv";
        public static const SuperJump:String = "nj";
        public static const DefaultGravity:String = "gr"; // const_53
        public static const GravityMultiplied:String = "grm"; // const_59

        private var socket:PR2Socket = Main.socket;
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var course:Course;
        private var map:Map;
        private var var_174:MovieClip;
        private var itemDisplay:ItemDisplay;
        private var var_573:uint = setInterval(method_796, 5000);
        private var var_535:uint = setInterval(method_358, 1000);
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
        public var var_205:Number = 0;
        public var var_224:Number = 0;
        public var var_407:int;
        public var var_366:int;
        public var var_157:Number = 28;
        private var initialized:Boolean = false;
        public var testMode:Boolean = false;
        public var var_42:Boolean = false;
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
        private var var_368:Number = 0;
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
        private var var_435:Boolean = false;
        private var frozenSolid:Boolean = false;
        private var var_340:uint;
        private var var_530:Number;
        private var var_443:int;
        private var var_453:int;
        private var var_577:String;
        private var var_623:int;
        private var var_232:Boolean = false;
        private var altCtrl:Object = Settings.getValue(Settings.ALTERNATE_CONTROLS, Settings.DEFAULT_ALT_CONTROLS);

        public function Racer(tId:int, c:Course, ma:Map, _arg_4:MovieClip, itd:ItemDisplay, grav:Number, s:int=50, a:int=50, j:int=50, ha:int=1, h:int=1, b:int=1, f:int=1)
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
            this.var_174 = _arg_4;
            this.itemDisplay = itd;
            type = "local";
            _arg_4.gotoAndStop("local");
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
        }

        public function init()
        {
            if (!this.initialized && !var_214 && !var_304) {
                this.initialized = true;
                addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
                this.setMode("land");
                this.var_232 = true;
                this.socket.write("p`0`0");
            }
        }

        // method_46 = setStats
        public function setStats(s:int, a:int, j:int)
        {
            this.speedStat = class_74.numLimit(s, 0, 100);
            this.accelStat = class_74.numLimit(a, 0, 100);
            this.jumpnStat = class_74.numLimit(j, 0, 100);
            this.maxVelX = 2 + (this.speedStat / 10);
            this.accel = 0.2 + (this.accelStat / 60);
            var_4.setNumber(SuperJump, 2 + (this.jumpnStat / 40));
        }

        public function resetStats()
        {
            this.setStats(this.speedStat, this.accelStat, this.jumpnStat);
        }

        public function method_392(_arg_1:int)
        {
            this.speedStat = this.speedStat + _arg_1;
            this.accelStat = this.accelStat + _arg_1;
            this.jumpnStat = this.jumpnStat + _arg_1;
            this.setStats(this.speedStat, this.accelStat, this.jumpnStat);
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

        public function zap(a:Array)
        {
            new Zap(this, true);
            if (!var_4.getBool(PARTY)) {
                this.setMode("hurt");
            }
        }

        private function go(e:Event)
        {
            var _local_2:int = x = Math.round(x);
            var _local_3:int = y = Math.round(y);
            if (this.map != null) {
                var _local_4:Point = class_28.method_9(_local_2, _local_3, this.map.rotation);
                this.var_174.x = _local_4.x;
                this.var_174.y = _local_4.y;
            }
            method_58(this.map.rotation);
            this.hurtTime--;
            if (this.course.var_40.length > 1) {
                var_215++;
                if (var_215 >= var_448) {
                    if (this.method_779() || var_215 >= 23) {
                        var_215 = 0;
                        var _local_5:int = _local_2 - this.var_443;
                        var _local_6:int = _local_3 - this.var_453;
                        this.var_443 = _local_2;
                        this.var_453 = _local_3;
                        if (_local_5 != 0 || _local_6 != 0) {
                            this.socket.write("p`" + _local_5 + "`" + _local_6);
                        }
                        if (this.var_232) {
                            this.var_232 = false;
                            this.socket.write("exact_pos`" + _local_2 + "`" + _local_3);
                        }
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
                    if (this.curItem != this.var_623) {
                        this.var_623 = this.curItem;
                        this.socket.write("set_var`item`" + Items.getCodeFromItem(this.curItem));
                    }
                }
                this.method_704();
            }
        }

        private function method_796()
        {
            this.var_232 = true;
        }

        // doSquash?
        private function method_704()
        {
            if (velY > 0 && var_4.getBool(JIGG)) {
                for each (var _local_1:Character in this.course.var_40) {
                    if (_local_1 is class_91 && _local_1.state != "crouch" && _local_1.state != "crouchWalk" && _local_1.x > (x - 20) && _local_1.x < (x + 20) && _local_1.y > (y + 35) && _local_1.y < (y + 65) && _local_1.rotation == this.rotation) {
                        _local_1.changeState("crouch");
                        SoundEffects.playGameSound(new SquashSound(), x, y, 0.66);
                        this.socket.write("squash`" + _local_1.tempID + "`" + x + "`" + y);
                        velY = -3;
                        this.var_42 = true;
                    }
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
            this.method_193();
            if (!this.var_214) {
                if (this.up && this.var_42 && !this.crouching) {
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
            this.var_368--;
            if (this.var_368 <= 0) {
                velY = -5;
                this.setMode("land");
            }
        }

        private function freezeGo(e:Event)
        {
        }

        private function waterGo(_arg_1:Event)
        {
            this.method_193();
            if (this.right) {
                velX = velX + (this.accel * 0.5);
            }
            if (this.left) {
                velX = velX - (this.accel * 0.5);
            }
            if (this.down) {
                velY = velY + (this.accel * 0.65);
            }
            if (this.up) {
                velY = velY - (this.accel * 0.65);
            }
            velY = velY + (var_4.getNumber(DefaultGravity) * 0.25);
            velX = velX * 0.92;
            velY = velY * 0.92;
            velX = class_74.numLimit(velX, -this.var_157, this.var_157);
            velY = class_74.numLimit(velY, -this.var_157, this.var_157);
            x = x + velX;
            y = y + velY;
            this.method_76();
            this.var_240--;
            if (var_4.getBool(COWBOY) && !this.var_42) {
                this.var_240 = 1;
            }
            if (this.var_240 <= 0) {
                if (this.up) {
                    velY = velY - (var_4.getNumber(SuperJump) * 0.5);
                    var_4.setNumber(const_12, -(var_4.getNumber(SuperJump)) * 0.5);
                    this.var_281 = true;
                }
                this.setMode("land");
            }
        }

        private function landGo(e:Event)
        {
            this.method_193();
            if (this.right) {
                this.var_24 = this.var_24 + this.accel;
            }
            if (this.left) {
                this.var_24 = this.var_24 - this.accel;
            }
            if (!this.right && !this.left) {
                this.var_24 = 0;
            }
            if (this.up) {
                if (this.var_42 && !this.crouching) {
                    this.var_281 = true;
                    velY = velY - var_4.getNumber(SuperJump);
                    var_4.setNumber(const_12, -(var_4.getNumber(SuperJump)));
                } else {
                    if (this.var_281) {
                        velY = velY + var_4.getNumber(const_12);
                        var_4.setNumber(const_12, var_4.getNumber(const_12) * 0.75);
                    }
                }
            } else {
                this.var_281 = false;
            }
            if (this.down) {
                if (!this.crouching) {
                    if (!this.var_42) {
                        velY = velY + 0.5;
                        this.var_150 = 0;
                    } else {
                        if (this.var_150 < 100) {
                            this.var_150 = this.var_150 + 2;
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
            if (!this.var_42) {
                changeState("jump");
            } else {
                if (this.var_150 > 25) {
                    changeState("superJump");
                } else {
                    if (this.left || this.right) {
                        if (this.crouching) {
                            changeState("crouchWalk");
                        } else {
                            changeState("run");
                        }
                    } else {
                        if (this.crouching) {
                            changeState("crouch");
                        } else {
                            changeState("stand");
                        }
                    }
                }
            }
            this.method_76();
            if (var_4.getBool(COWBOY) && this.var_42 == false) {
                this.var_240 = 2;
                this.setMode("water");
                changeState("swim");
            }
        }

        private function method_193()
        {
            var _local_1:Boolean;
            this.up = false;
            this.down = false;
            this.right = false;
            this.left = false;
            this.space = false;
            if (Keys.isPressed(Keyboard.RIGHT)) {
                this.right = true;
            }
            if (Keys.isPressed(Keyboard.LEFT)) {
                this.left = true;
            }
            if (Keys.isPressed(Keyboard.UP)) {
                this.up = true;
            }
            if (Keys.isPressed(Keyboard.DOWN)) {
                this.down = true;
            }
            if (Keys.isPressed(Keyboard.SPACE)) {
                this.space = true;
            }
            if (Main.stage.focus == null || Main.stage.focus != RaceChat.textBox) {
                if (Keys.isPressed(this.altCtrl.right)) {
                    this.right = true;
                    scaleX = 1;
                }
                if (Keys.isPressed(this.altCtrl.left)) {
                    this.left = true;
                    scaleX = -1;
                }
                if (Keys.isPressed(this.altCtrl.up)) {
                    this.up = true;
                }
                if (Keys.isPressed(this.altCtrl.down)) {
                    this.down = true;
                }
                if (Keys.isPressed(this.altCtrl.item)) {
                    this.space = true;
                }
            }
            if (this.right) {
                scaleX = 1;
            }
            if (this.left) {
                scaleX = -1;
            }
            if (var_241) {
                _local_1 = this.right;
                this.right = this.left;
                this.left = _local_1;
            }
            if (this.curItem != null) {
                this.curItem.setSpace(this.space);
            }
        }

        private function position()
        {
            var _local_1:Number;
            var _local_2:Point;
            var _local_3:int;
            if (this.map != null) {
                if (this.course != null && parent != this.course.frontBackground) {
                    this.course.frontBackground.addChild(this);
                }
                velY = velY + var_4.getNumber(GravityMultiplied);
                if (this.up && var_4.getBool(PROP) && velY > 0) {
                    velY = velY * 0.85;
                }
                this.var_24 = this.var_24 * this.friction;
                if (this.crouching) {
                    this.var_24 = this.var_24 * 0.7;
                }
                this.var_24 = class_74.numLimit(this.var_24, -this.maxVelX, this.maxVelX);
                _local_1 = Math.abs(velX) * (1 / this.var_157);
                _local_1 = 1 - _local_1;
                _local_1 = _local_1 * 0.9;
                _local_1 = _local_1 + 0.1;
                this.var_147 = this.var_147 * _local_1;
                if (this.frozenSolid) {
                    this.var_147 = 0;
                }
                velX = velX + ((this.var_24 - velX) * this.var_147);
                velX = class_74.numLimit(velX, -this.var_157, this.var_157);
                velY = class_74.numLimit(velY, -this.var_157, this.var_157);
                x = x + velX;
                y = y + velY;
                _local_2 = class_28.method_9(x, y, this.map.rotation);
                _local_3 = 500;
                if ((_local_2.y > this.map.maxY + _local_3 && this.map.rotation == 0) || (_local_2.y < this.map.minY - _local_3 && Math.abs(this.map.rotation) == 180) || (_local_2.x > this.map.maxX + _local_3 && this.map.rotation == 90) || (_local_2.x < this.map.minX - _local_3 && this.map.rotation == -90)) {
                    this.method_216();
                }
                this.var_147 = this.var_523;
                this.var_524 = this.var_599;
            }
        }

        public function method_216()
        {
            x = this.var_205;
            y = this.var_224;
            velX = 0;
            velY = 0;
            this.method_448();
        }

        private function method_76()
        {
            var _local_3:Block;
            var _local_4:Number;
            if (this.map != null) {
                this.method_41();
                this.method_261();
                if (var_4.getBool(SANTA)) {
                    _local_3 = this.map.method_24(x, y, true);
                    if (_local_3 != null && ((_local_3 is WaterBlock && this.mode != "water") || _local_3 is SafetyBlock)) {
                        _local_3.onStand(this);
                    }
                }
                if (velX >= -1) {
                    if (this.var_296 != null && this.getBlock(this.var_296.method_50() - 30, this.var_296.method_44()) == null) {
                        this.var_296.onLeftHit(this);
                        this.method_41();
                    }
                }
                if (velX <= 1) {
                    if (this.var_329 != null && this.getBlock(this.var_329.method_50() + 30, this.var_329.method_44()) == null) {
                        this.var_329.onRightHit(this);
                        this.method_41();
                    }
                }
                if (velY < 0) {
                    if (this.var_42) {
                        this.crouching = true;
                    }
                    if (this.mode != "water" && this.var_262 != null && this.getBlock(this.var_262.method_50(), this.var_262.method_44() + 30) == null) {
                        this.var_262.onBump(this);
                        this.method_41();
                    } else {
                        if (this.mode != "water" && this.var_306 != null && this.getBlock(this.var_306.method_50(), this.var_306.method_44() + 30) == null) {
                            this.var_306.onBump(this);
                            this.method_41();
                        } else {
                            if (this.var_297 != null && this.getBlock(this.var_297.method_50(), this.var_297.method_44() + 30) == null) {
                                this.var_297.onBump(this);
                                this.method_41();
                            }
                        }
                    }
                }
                if (!this.var_42) {
                    this.method_261();
                }
                var _local_1:Block = null;
                var _local_2:Block = null;
                this.crouching = false;
                if (this.var_42 == true) {
                    _local_1 = this.getBlock(x, y - 40);
                    _local_2 = this.getBlock(x, y - 10);
                    if (_local_1 != null && _local_2 == null) {
                        this.crouching = true;
                        if (this.up) {
                            _local_4 = y;
                            _local_1.onBump(this);
                            y = _local_4;
                            velY = 0;
                        }
                        if (velY < 0) {
                            velY = 0;
                        }
                    }
                }
                _local_1 = this.map.method_24(x, y - 15, true);
                if (_local_1 != null) {
                    _local_1.onTouch(this);
                }
                if (!this.crouching) {
                    _local_1 = this.map.method_24(x, y - 45, true);
                    if (_local_1 != null) {
                        _local_1.onTouch(this);
                    }
                }
            }
        }

        private function method_261()
        {
            if (this.var_469 != null && this.var_262 == null) {
                this.var_469.onStand(this);
                this.method_41();
                this.var_42 = true;
            } else {
                this.var_42 = false;
            }
        }

        private function method_41()
        {
            //var _local_1:Number = y; // not needed?
            if (y < 0) {
                y = y + 0.001;
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
                var block:Block = this.map.method_24(_arg_1, _arg_2, _arg_3);
                if (block == null || !block.method_23() || (var_4.getBool(TOP) && block is VanishBlock && !_arg_4)) {
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
                this.var_24 = 0;
                if (this.mode == "hurt") {
                    changeState("bumped");
                    this.method_448();
                }
                if (this.mode == "water" && this.state != "bumped") {
                    changeState("swim");
                }
                if (this.mode == "squashed") {
                    this.var_368 = 60;
                    method_51(70);
                }
            }
        }

        private function method_448()
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
            this.life = class_74.numLimit(l, 0, 15);
            this.course.setLife(this.life);
        }

        override public function becomeInvincible(_arg_1:int)
        {
            super.becomeInvincible(_arg_1);
            this.hurtTime = _arg_1;
            this.var_435 = true;
        }

        override protected function endRecovery()
        {
            super.endRecovery();
            this.var_435 = false;
        }

        public function hit(_arg_1:Number=0, _arg_2:Number=0)
        {
            var _local_3:Object;
            if ((!var_4.getBool(CROWN) || this.course.gameMode == "deathmatch") && !this.var_435) {
                velX = velX + _arg_1;
                velY = velY + _arg_2;
                if (!var_4.getBool(CROWN)) {
                    method_51(50);
                    if (!this.frozenSolid) {
                        this.setMode("hurt");
                    }
                }
                if (this.map != null && !this.testMode) {
                    _local_3 = method_380();
                    if (_local_3.hatNum != 1 && _local_3.hatNum != 0 && _local_3.hatNum != null) {
                        Main.socket.write("loose_hat`" + x + "`" + (y - 50) + "`" + this.map.rotation);
                    }
                }
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            this.var_205 = _arg_1;
            this.var_224 = _arg_2;
            super.setPos(_arg_1, _arg_2);
            this.var_443 = _arg_1;
            this.var_453 = _arg_2;
            this.var_232 = true;
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
                this.curItem.remove();
                this.curItem = null;
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

        public function method_483(_arg_1:Number)
        {
            rotation = Math.round(_arg_1);
            this.socket.write("set_var`rotMod`" + rotation);
        }

        override public function rotate(_arg_1:String)
        {
            var _local_2:Number;
            var _local_3:Number;
            super.rotate(_arg_1);
            if (_arg_1 == "right") {
                _local_2 = -this.var_224;
                _local_3 = this.var_205;
            } else {
                _local_2 = this.var_224;
                _local_3 = -this.var_205;
            }
            this.var_205 = _local_2;
            this.var_224 = _local_3;
            this.setMode("land");
            this.course.posX = -x;
            this.course.posY = -y + 50;
            this.socket.write("set_var`rot`" + -this.map.rotation);
            this.var_232 = true;
        }

        private function method_779():Boolean
        {
            var _local_3:Character;
            var _local_1:Array = Course.course.var_40;
            var _local_2:Boolean;
            for each (_local_3 in _local_1) {
                if (_local_3 != this && Math.abs(_local_3.x - x) < 1000 && Math.abs(_local_3.y - y) < 1000) {
                    _local_2 = true;
                    break;
                }
            }
            return _local_2;
        }

        override public function beginSparkles(_arg_1:int=5000)
        {
            this.socket.write("set_var`sparkle`1");
            super.beginSparkles(_arg_1);
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
            super.setHats(_arg_1);
            if (hadMoon && !var_4.getBool(MOON)) {
                this.resetGravity();
            }
            if (hadCB && !var_4.getBool(COWBOY)) {
                this.resetStats();
            }
            if (hadSanta && !var_4.getBool(SANTA)) {
                this.resetStats();
            }
            if (hadArti && !var_4.getBool(ARTIFACT)) {
                if (Items.getCodeFromItem(this.curItem) == Items.speedBurst) {
                    this.setItem(0);
                }
                var_241 = false;
            }
            this.method_358();
            if (var_4.getBool(SANTA)) {
                if (!hadSanta) {
                    this.maxVelX = this.maxVelX + 1;
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
                    if (cTimer.getTime() > 30) {
                        cTimer.setTime(30);
                        cTimer.init();
                    }
                    var zap:Zap = new Zap(this, false, false);
                    zap.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0xFF, 0);
                    SoundEffects.playSound(new YeahSound(), 1 * (Settings.soundLevel / 100));
                    Course.course.musicSelection.dropdown.gotArtifact();
                    var_241 = true;
                }
            }
        }

        private function method_358()
        {
            if (var_4.getBool(COWBOY) && this.curItem != Items.speedBurst) {
                this.maxVelX = 12;
                this.accel = 1.86;
                var_4.setNumber(SuperJump, 4.5);
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
                clearTimeout(this.var_340);
                this.var_340 = setTimeout(this.method_591, 2000);
                this.setMode("frozenSolid");
            }
        }

        private function method_591()
        {
            clearTimeout(this.var_340);
            this.frozenSolid = false;
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
            clearTimeout(this.var_340);
        }

        override public function remove()
        {
            this.setItem(0);
            this.socket = null;
            if (this.cm != null) {
                this.cm.defineCommand("setHats" + tempID.toString(), null);
                this.cm.defineCommand("zap", null);
                this.cm.defineCommand("squash" + tempID.toString(), null);
                this.cm = null;
            }
            this.course = null;
            this.map = null;
            if (this.var_174 != null) {
                if (this.var_174.parent != null) {
                    this.var_174.parent.removeChild(this.var_174);
                }
                this.var_174 = null;
            }
            this.itemDisplay = null;
            this.var_390 = null;
            this.curItem = null;
            super.remove();
        }


    }
}
