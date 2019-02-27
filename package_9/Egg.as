// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.Egg = package_9.class_82

package package_9
{
    import data.Random;
    import data.CommandHandler;
    import package_6.Course;
    import background.Map;
    import data.class_28;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import background.class_87;
    import flash.events.Event;
    import sounds.SoundEffects;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    public class Egg extends class_81 
    {

        private static var var_406:int = 0;
        private static var var_466:int = 1;
        private static var var_474:int = 2;
        private static var var_491:int = 3;
        private static var rand:Random = new Random(1);
        private static var var_223:int = 1;
        private static var mode:int = 3;

        private var var_486:int;
        private var m:EggGraphic = new EggGraphic();
        private var scale:Number = 0.12;
        private var maxX:int;
        private var minX:int;
        private var maxY:int;
        private var minY:int;
        private var var_286:int = 0;
        private var id:int;
        private var var_382:int = 0;

        public function Egg()
        {
            addChild(this.m);
            alpha = 0;
            this.id = var_223++;
            CommandHandler.commandHandler.defineCommand(("removeEgg" + this.id), this.method_744);
            var _local_1:Map = Course.course.blockBackground;
            var _local_2:int = rand.nextMinMax(_local_1.minX, _local_1.maxX);
            var _local_3:int = rand.nextMinMax(_local_1.minY, _local_1.maxY);
            var _local_4:int = (rand.nextMinMax(-1, 3) * 90);
            var _local_5:Point = class_28.method_9(_local_2, _local_3, -(_local_4));
            super(_local_5.x, _local_5.y, _local_4);
            this.setLimits();
            if (rand.nextMinMax(0, 2) == 1) {
                velX = 1;
            } else {
                velX = -1;
            }
            var _local_6:ColorTransform = new ColorTransform();
            _local_6.color = Math.floor((Math.random() * 0xFFFFFF));
            var _local_7:ColorTransform = new ColorTransform();
            _local_7.color = Math.floor((Math.random() * 0xFFFFFF));
            var _local_8:ColorTransform = new ColorTransform();
            _local_8.color = Math.floor((Math.random() * 0xFFFFFF));
            scaleX = (scaleY = this.scale);
            this.m.var_165.gotoAndStop(1);
            this.m.var_152.gotoAndStop(1);
            this.m.var_165.colorMC.gotoAndStop(1);
            this.m.var_152.colorMC.gotoAndStop(1);
            this.m.var_165.colorMC2.gotoAndStop(1);
            this.m.var_152.colorMC2.gotoAndStop(1);
            this.m.var_165.colorMC2.visible = false;
            this.m.var_152.colorMC2.visible = false;
            this.m.var_165.colorMC.transform.colorTransform = _local_6;
            this.m.var_152.colorMC.transform.colorTransform = _local_6;
            this.m.egg.base.transform.colorTransform = _local_7;
            this.m.egg.dots.transform.colorTransform = _local_8;
        }

        public static function method_333(_arg_1:int)
        {
            rand = new Random(_arg_1);
            var_223 = 1;
            mode = rand.nextMinMax(0, 5);
            if (mode > 3) {
                mode = 3;
            }
        }


        // _loc1 = map
        // _loc2 = minPoint
        // _loc3 = maxPoint
        // method_324 = setLimits
        public function setLimits()
        {
            var _local_4:int;
            var map:Map = Course.course.blockBackground;
            this.maxX = map.maxX + 300;
            this.minX = map.minX - 300;
            this.maxY = map.maxY + 300;
            this.minY = map.minY - 300;
            var minPoint:Point = class_28.method_9(this.minX, this.minY, -rot);
            var maxPoint:Point = class_28.method_9(this.maxX, this.maxY, -rot);
            this.maxX = maxPoint.x;
            this.maxY = maxPoint.y;
            this.minX = minPoint.x;
            this.minY = minPoint.y;
            if (this.maxX < this.minX) {
                _local_4 = this.maxX;
                this.maxX = this.minX;
                this.minX = _local_4;
            }
            if (this.maxY < this.minY) {
                _local_4 = this.maxY;
                this.maxY = this.minY;
                this.minY = _local_4;
            }
        }

        private function method_723()
        {
            if (posX > this.maxX) {
                posX = this.minX;
            }
            if (posX < this.minX) {
                posX = this.maxX;
            }
            if (posY > this.maxY) {
                posY = this.minY;
            }
            if (posY < this.minY) {
                posY = this.maxY;
            }
        }

        override protected function go(_arg_1:Event)
        {
            var _local_5:int;
            var _local_6:String;
            var _local_7:int;
            var _local_8:String;
            var _local_9:int;
            var _local_10:int;
            var _local_11:Number;
            var _local_12:Slash;
            var _local_13:LaserShot;
            super.go(_arg_1);
            if (velX > 0) {
                scaleX = this.scale;
            } else {
                scaleX = -(this.scale);
            }
            if (Course.course.gameMode == "egg") {
                this.method_723();
            }
            if (this.var_286 > 0) {
                this.var_286--;
            }
            if (alpha < 1) {
                alpha = alpha + 0.02;
            }
            var _local_2:int = posX + (velX * (Math.random() * 100) + 50);
            var _local_3:int = posY;
            var _local_4:Point = class_28.method_9(_local_2, _local_3, -rotation);
            if (this.var_382 <= 0 && method_181(_local_4.x, _local_4.y)) {
                this.var_382 = 120;
                _local_5 = 0;
                _local_6 = "right";
                _local_7 = -1;
                _local_9 = posX;
                _local_10 = (posY - 10);
                if (scaleX < 0) {
                    _local_5 = 180;
                    _local_6 = "left";
                }
                _local_11 = -1;
                if (mode == var_491) {
                    _local_11 = Math.random();
                }
                if (mode == var_406 || _local_11 > 0.66) {
                    _local_8 = "IceWave`" + _local_9 + "`" + _local_10 + "`" + _local_5 + "`" + rot + "`" + _local_7;
                    class_87.var_276.addEffect(_local_8.split("`"));
                } else {
                    if (mode == var_466 || _local_11 > 0.33) {
                        _local_12 = new Slash(_local_9, _local_10, _local_6, _local_7);
                        _local_8 = "Slash`" + _local_9 + "`" + _local_10 + "`" + _local_6 + "`" + _local_7;
                    } else {
                        if (mode == var_474 || _local_11 > 0) {
                            _local_13 = new LaserShot(_local_9, _local_10, _local_6, rot, _local_7);
                            _local_8 = "Laser`" + _local_9 + "`" + _local_10 + "`" + _local_6 + "`" + rot + "`" + _local_7;
                        }
                    }
                }
                Main.socket.write(("add_effect`" + _local_8));
            } else {
                this.var_382--;
            }
        }

        override protected function onTouchLocalPlayer()
        {
            this.beginRemove();
            SoundEffects.playGameSound(new CollectEggSound(), x, y, 1.5);
            Course.course.collectEgg(this.id);
        }

        public function method_744(_arg_1:Array)
        {
            this.remove();
        }

        override protected function onTouchWall()
        {
            if (method_311()) {
                if (this.var_286 > 0) {
                    posY = (posY - 30);
                }
                this.var_286 = 2;
                velX = (velX * -1);
            }
        }

        public function beginRemove()
        {
            method_205();
            this.m.gotoAndPlay("squash");
            clearTimeout(this.var_486);
            this.var_486 = setTimeout(this.remove, 1000);
        }

        override public function remove()
        {
            super.remove();
            clearTimeout(this.var_486);
            CommandHandler.commandHandler.defineCommand(("removeEgg" + this.id), null);
        }


    }
}//package package_9

