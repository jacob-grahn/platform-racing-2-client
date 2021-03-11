// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.Block = blocks.class_36

package blocks
{
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.display.Bitmap;
    import background.Map;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import package_8.Player;
    import package_8.LocalPlayer;
    import sounds.SoundEffects;

    public class Block extends Sprite 
    {

        private var size:Number = 30;
        private var posX:Number; // pos is the exact coordinates (pixels)
        private var posY:Number;
        private var segX:int; // seg is the block coodinates
        private var segY:int;
        private var removed:Boolean = false; // var_214
        private var var_177:Point;
        private var m:Bitmap;
        protected var blockCode:int = 0; // var_79
        protected var active:Boolean = true;
        protected var var_34:Boolean = true;
        protected var var_490:Boolean = true;
        protected var map:Map;
        protected var frozen:Boolean = false; // var_37
        private var var_110:Bitmap;
        private var var_455:Number = 0.1;
        private var var_600:int = 0;

        public function Block(blockCode:int)
        {
            var bmpData:BitmapData = Blocks.getBlock(blockCode);
            this.m = new Bitmap(bmpData, PixelSnapping.ALWAYS, false);
            addChild(this.m);
        }

        public function initialize(segPointX:int, segPointY:int, _arg_3:Map)
        {
            this.map = _arg_3;
            this.setSeg(segPointX, segPointY);
            this.map.method_53(this, new Point(segPointX, segPointY));
        }

        public function isInitialized():Boolean
        {
            return this.map != null;
        }

        public function getSeg():Point
        {
            return new Point(this.segX, this.segY);
        }

        // method_850 = getPos
        public function getPos():Point
        {
            return new Point(this.posX, this.posY);
        }

        // method_50 = getPosX
        public function getPosX():int
        {
            return this.posX;
        }

        // method_44 = getPosY
        public function getPosY():int
        {
            return this.posY;
        }

        public function getCode():int
        {
            return this.frozen ? Objects.IceBlockCode : this.blockCode;
        }

        // method_23 = isActive
        public function isActive():Boolean
        {
            return this.frozen ? true : this.active;
        }

        public function method_20():Boolean
        {
            return this.removed;
        }

        public function method_18(rot:Number = NaN):Point
        {
            if (isNaN(rot)) {
                rot = this.map.rotation;
            }
            var _local_2:int, _local_3:int;
            if (rot == 90) {
                _local_3 = 30;
            } else if (Math.abs(rot) == 180) {
                _local_2 = _local_3 = 30;
            } else if (rot == -90) {
                _local_2 = 30;
            }
            return Data.method_9(this.posX + _local_2, this.posY + _local_3, -rot);
        }

        public function method_777():int
        {
            return Data.getTimestamp() - this.var_600;
        }

        public function setSeg(_arg_1:int, _arg_2:int)
        {
            this.segX = _arg_1;
            this.segY = _arg_2;
            this.setPos(_arg_1 * this.size, _arg_2 * this.size);
        }

        public function setPos(newX:Number, newY:Number)
        {
            this.posX = newX;
            this.posY = newY;
            x = newX;
            y = newY;
        }

        public function freeze(_arg_1:Boolean=false)
        {
            if (!this.frozen) {
                this.frozen = true;
                this.var_600 = Data.getTimestamp();
                this.var_110 = new Bitmap(Blocks.iceBitmap);
                addChild(this.var_110);
                if (_arg_1) {
                    this.var_110.alpha = 1.75;
                    this.var_455 = 0.01;
                } else {
                    this.var_110.alpha = 1;
                    this.var_455 = 0.025;
                }
                addEventListener(Event.ENTER_FRAME, this.method_153, false, 0, true);
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onStand(player:LocalPlayer)
        {
            if (!this.frozen && this.method_777() > 4 && player.var_4.getBool(Player.SANTA) && this.blockCode != Objects.FinishBlockCode && this.blockCode != Objects.IceBlockCode && this.blockCode != Objects.VanishBlockCode && this.blockCode != Objects.CrumbleBlockCode && this.blockCode != Objects.UpBlockCode && this.blockCode != Objects.LeftBlockCode && this.blockCode != Objects.RightBlockCode && this.blockCode != Objects.DownBlockCode && this.blockCode != Objects.MoveBlockCode) {
                this.freeze(); // controls santa physics, affected by ice wave
            }
            if (this.frozen) {
                player.var_147 = 0.05;
            }
            if (this.isActive()) {
                var point:Point = this.method_18();
                player.y = point.y + this.posY - y;
                player.velY = 0;
                player.grounded = true;
                if (this.var_34) {
                    player.var_205 = point.x + 15;
                    player.var_224 = point.y;
                    player.var_407 = this.segX;
                    player.var_366 = this.segY;
                }
            } else {
                player.grounded = false;
            }
        }

        public function onBump(player:LocalPlayer)
        {
            if (this.isActive()) {
                var _local_2:Point = this.method_18();
                var _local_3:Point = Data.method_9(x - this.posX, y - this.posY, this.map.rotation);
                if (player.crouching) {
                    player.y = _local_2.y + this.size + _local_3.y + (player.var_325 / 2);
                } else {
                    player.y = _local_2.y + this.size + _local_3.y + player.var_325;
                }
                player.velY = player.velY * -0.25;
                player.var_4.setNumber(LocalPlayer.const_12, 0);
                if (this.var_490) {
                    this.method_315(0, -15);
                }
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onLeftHit(player:LocalPlayer)
        {
            if (this.isActive()) {
                var point:Point = this.method_18();
                player.x = point.x - player.var_189;
                if (player.velX > 0) {
                    player.velX = player.velX * -0.05;
                }
                if (player.var_24 > 0) {
                    player.var_24 = 0;
                }
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onRightHit(player:LocalPlayer)
        {
            if (this.isActive()) {
                var point:Point = this.method_18();
                player.x = point.x + this.size + player.var_189;
                if (player.velX < 0) {
                    player.velX = player.velX * -0.05;
                }
                if (player.var_24 < 0) {
                    player.var_24 = 0;
                }
            }
        }

        // _arg1 = player
        public function onTouch(player:LocalPlayer)
        {
        }

        public function onDamage(_arg_1:Number)
        {
            _arg_1 = class_74.numLimit(_arg_1, -20, 20);
            this.method_315(_arg_1, 0);
        }

        public function remoteActivate(_arg_1:String = "")
        {
            this.activate(_arg_1);
        }

        protected function localActivate(_arg_1:String = "")
        {
            Main.socket.write("activate`" + this.segX + "`" + this.segY + "`" + _arg_1);
            this.activate(_arg_1);
        }

        protected function activate(_arg_1:String = "")
        {
        }

        // _loc2 = hitX
        // _loc3 = hitY
        public function method_839(arr:Array)
        {
            var hitX:Number = arr[0];
            var hitY:Number = arr[1];
            this.hit(hitX, hitY);
        }

        // _loc3 = point
        private function method_315(_arg_1:Number, _arg_2:Number)
        {
            var point:Point = Data.method_9(_arg_1, _arg_2, this.map.rotation);
            this.hit(point.x, point.y);
        }

        // _loc4 = point
        private function hit(hitX:Number, hitY:Number)
        {
            this.var_177 = new Point(hitX, hitY);
            addEventListener(Event.ENTER_FRAME, this.method_161);
            var _local_3:Number = class_74.method_232(hitX, hitY) * 0.06;
            if (Math.abs(x - this.posX) < 1 && Math.abs(y - this.posY) < 1) {
                var point:Point = this.method_18();
                SoundEffects.playGameSound(new ThumpSound(), point.x, point.y, _local_3);
            }
        }

        private function method_153(e:Event)
        {
            if (this.var_110 != null) {
                this.var_110.alpha = this.var_110.alpha - this.var_455;
                if (this.var_110.alpha <= 0.05) {
                    removeEventListener(Event.ENTER_FRAME, this.method_153);
                    this.method_406();
                    this.frozen = false;
                }
            }
        }

        private function method_161(_arg_1:Event)
        {
            this.var_177.x = this.var_177.x * 0.5;
            this.var_177.y = this.var_177.y * 0.5;
            y += this.var_177.y;
            y += (this.posY - y) * 0.35;
            x += this.var_177.x;
            x += (this.posX - x) * 0.35;
            if (Math.abs(this.posY - y) < 0.25 && Math.abs(this.posY - x) < 0.25) {
                y = this.posY;
                x = this.posX;
                removeEventListener(Event.ENTER_FRAME, this.method_161);
            }
        }

        // _loc3 = curPoint
        // _loc4 = newPoint
        // _loc5 = block
        protected function move(xAmt:int, yAmt:int, ensureMap:Map)
        {
            if (this.map == null) {
                this.map = ensureMap;
            }
            var curPoint:Point = new Point(this.segX, this.segY);
            var newPoint:Point = new Point(this.segX + xAmt, this.segY + yAmt);
            var block:Block = this.map.getBlockFromSeg(newPoint.x, newPoint.y);
            if (block is PushBlock) {
                block.move(xAmt, yAmt, ensureMap);
            }
            this.map.moveBlock(curPoint, newPoint);
        }

        private function method_406()
        {
            if (this.var_110 != null) {
                removeChild(this.var_110);
                this.var_110 = null;
            }
        }

        public function remove()
        {
            this.removed = true;
            this.active = false;
            removeEventListener(Event.ENTER_FRAME, this.method_153);
            removeEventListener(Event.ENTER_FRAME, this.method_161);
            this.map.method_259(this);
            this.map = null;
            this.method_406();
            this.var_177 = null;
            if (this.m != null) {
                removeChild(this.m);
                this.m.bitmapData = null;
                this.m = null;
            }
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package blocks

