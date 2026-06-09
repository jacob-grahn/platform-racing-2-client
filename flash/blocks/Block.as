// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// blocks.Block = blocks.class_36

package blocks
{
    import background.Map;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.PixelSnapping;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Point;
    import character.Character;
    import character.LocalCharacter;
    import sounds.SoundEffects;

    public class Block extends Sprite 
    {

        private var size:Number = 30;
        private var posX:Number; // pos is the exact coordinates (pixels)
        private var posY:Number;
        private var segX:int; // seg is the block coodinates
        private var segY:int;
        private var removed:Boolean = false;
        private var bounceVel:Point;
        private var m:Bitmap;
        protected var blockCode:int = 0;
        protected var active:Boolean = true;
        protected var safeStand:Boolean = true;
        protected var bounceOnBump:Boolean = true;
        protected var map:Map;
        protected var frozen:Boolean = false;
        protected var optionsMenu:Class = null;
        private var _options:String = '';
        private var iceOverlay:Bitmap;
        private var iceFadeRate:Number = 0.1;
        private var frozenTime:int = 0;

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
            this.map.addToBlockArray(this, new Point(segPointX, segPointY));
        }

        public function isInitialized():Boolean
        {
            return this.map != null;
        }

        public function get hasOptions():Boolean
        {
            return this.optionsMenu != null;
        }

        public function openOptions()
        {
            new this.optionsMenu(this);
        }

        public function get options()
        {
            return this._options;
        }

        public function set options(optStr:String) // I'd set visibility to protected but not setting it to public seems to break things
        {
            if (this.hasOptions && optStr != this._options) {
                this._options = optStr;
            }
        }

        public function getSeg():Point
        {
            return new Point(this.segX, this.segY);
        }

        public function getPos():Point
        {
            return new Point(this.posX, this.posY);
        }

        public function getPosX():int
        {
            return this.posX;
        }

        public function getPosY():int
        {
            return this.posY;
        }

        public function getCode():int
        {
            return this.frozen ? Objects.BLOCK_ICE : this.blockCode;
        }

        public function isActive():Boolean
        {
            return this.frozen ? true : this.active;
        }

        public function isRemoved():Boolean
        {
            return this.removed;
        }

        public function getRotatedPos(rot:Number = NaN):Point
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
            return Data.rotatePoint(this.posX + _local_2, this.posY + _local_3, -rot);
        }

        public function timeSinceFrozen():int
        {
            return Data.getTimestamp() - this.frozenTime;
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
                this.frozenTime = Data.getTimestamp();
                this.iceOverlay = new Bitmap(Blocks.iceBitmap);
                addChild(this.iceOverlay);
                if (_arg_1) {
                    this.iceOverlay.alpha = 1.75;
                    this.iceFadeRate = 0.01;
                } else {
                    this.iceOverlay.alpha = 1;
                    this.iceFadeRate = 0.025;
                }
                addEventListener(Event.ENTER_FRAME, this.onUnfreezeFrame, false, 0, true);
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onStand(player:LocalCharacter)
        {
            if (!this.frozen && this.timeSinceFrozen() > 4 && player.store.getBool(Character.SANTA) && this.blockCode != Objects.BLOCK_FINISH && this.blockCode != Objects.BLOCK_ICE && this.blockCode != Objects.BLOCK_VANISH && this.blockCode != Objects.BLOCK_CRUMBLE && this.blockCode != Objects.BLOCK_ARROW_UP && this.blockCode != Objects.BLOCK_ARROW_LEFT && this.blockCode != Objects.BLOCK_ARROW_RIGHT && this.blockCode != Objects.BLOCK_ARROW_DOWN && this.blockCode != Objects.BLOCK_MOVE) {
                this.freeze(); // controls santa physics, affected by ice wave
            }
            if (this.frozen) {
                player.accelFactor = 0.05;
            }
            if (this.isActive()) {
                var point:Point = this.getRotatedPos();
                player.y = point.y + this.posY - y;
                player.velY = 0;
                player.grounded = true;
                if (this.safeStand) {
                    player.lastSafeX = point.x + 15;
                    player.lastSafeY = point.y;
                    player.standingSegX = this.segX;
                    player.standingSegY = this.segY;
                }
            } else {
                player.grounded = false;
            }
        }

        public function onBump(player:LocalCharacter)
        {
            if (this.isActive()) {
                var _local_2:Point = this.getRotatedPos();
                var _local_3:Point = Data.rotatePoint(x - this.posX, y - this.posY, this.map.rotation);
                if (player.crouching) {
                    player.y = _local_2.y + this.size + _local_3.y + (player.charHeight / 2);
                } else {
                    player.y = _local_2.y + this.size + _local_3.y + player.charHeight;
                }
                player.velY *= -0.25;
                player.store.setNumber(LocalCharacter.JUMP_VEL, 0);
                if (this.bounceOnBump) {
                    this.hitRotated(0, -15);
                }
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onLeftHit(player:LocalCharacter)
        {
            if (this.isActive()) {
                var point:Point = this.getRotatedPos();
                player.x = point.x - player.halfWidth;
                if (player.velX > 0) {
                    player.velX = player.velX * -0.05;
                }
                if (player.targetVelX > 0) {
                    player.targetVelX = 0;
                }
            }
        }

        // _arg1 = player
        // _loc2 = point
        public function onRightHit(player:LocalCharacter)
        {
            if (this.isActive()) {
                var point:Point = this.getRotatedPos();
                player.x = point.x + this.size + player.halfWidth;
                if (player.velX < 0) {
                    player.velX = player.velX * -0.05;
                }
                if (player.targetVelX < 0) {
                    player.targetVelX = 0;
                }
            }
        }

        // _arg1 = player
        public function onTouch(player:LocalCharacter)
        {
        }

        public function onDamage(_arg_1:Number)
        {
            _arg_1 = Data.numLimit(_arg_1, -20, 20);
            this.hitRotated(_arg_1, 0);
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
        public function remoteHit(arr:Array)
        {
            var hitX:Number = arr[0];
            var hitY:Number = arr[1];
            this.hit(hitX, hitY);
        }

        // _loc3 = point
        private function hitRotated(_arg_1:Number, _arg_2:Number)
        {
            var point:Point = Data.rotatePoint(_arg_1, _arg_2, this.map.rotation);
            this.hit(point.x, point.y);
        }

        // _loc4 = point
        private function hit(hitX:Number, hitY:Number)
        {
            this.bounceVel = new Point(hitX, hitY);
            addEventListener(Event.ENTER_FRAME, this.onBounceFrame);
            var _local_3:Number = Data.pythag(hitX, hitY) * 0.06;
            if (Math.abs(x - this.posX) < 1 && Math.abs(y - this.posY) < 1) {
                var point:Point = this.getRotatedPos();
                SoundEffects.playGameSound(new ThumpSound(), point.x, point.y, _local_3);
            }
        }

        private function onUnfreezeFrame(e:Event)
        {
            if (this.iceOverlay != null) {
                this.iceOverlay.alpha -= this.iceFadeRate;
                if (this.iceOverlay.alpha <= 0.05) {
                    removeEventListener(Event.ENTER_FRAME, this.onUnfreezeFrame);
                    this.removeIceOverlay();
                    this.frozen = false;
                }
            }
        }

        private function onBounceFrame(_arg_1:Event)
        {
            this.bounceVel.x = this.bounceVel.x * 0.5;
            this.bounceVel.y = this.bounceVel.y * 0.5;
            y += this.bounceVel.y;
            y += (this.posY - y) * 0.35;
            x += this.bounceVel.x;
            x += (this.posX - x) * 0.35;
            if (Math.abs(this.posY - y) < 0.25 && Math.abs(this.posY - x) < 0.25) {
                y = this.posY;
                x = this.posX;
                removeEventListener(Event.ENTER_FRAME, this.onBounceFrame);
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

        private function removeIceOverlay()
        {
            if (this.iceOverlay != null) {
                removeChild(this.iceOverlay);
                this.iceOverlay = null;
            }
        }

        public function remove()
        {
            this.removed = true;
            this.active = false;
            removeEventListener(Event.ENTER_FRAME, this.onUnfreezeFrame);
            removeEventListener(Event.ENTER_FRAME, this.onBounceFrame);
            this.map.removeBlock(this);
            this.map = null;
            this.removeIceOverlay();
            this.bounceVel = null;
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

