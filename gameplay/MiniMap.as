// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// gameplay.MiniMap = gameplay.class_84

package gameplay
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;

    public class MiniMap extends Removable 
    {

        private var bitmapData:BitmapData;
        private var bitmap:Bitmap;
        private var holder:Sprite = new Sprite();
        private var blockSprite:Sprite = new Sprite(); // block currently being processed
        private var finishSprite:Sprite = new Sprite(); // finishes? all blocks? prob all blocks???
        private var playerDots:Sprite = new Sprite(); // var_134
        private var m:MiniMapGraphic = new MiniMapGraphic();
        //private var var_662:Array = new Array(); // unused?
        private var maxSpaceWidth:int = 400; // var_239
        private var maxSpaceHeight:int = 44; // var_362
        private var scale:Number;
        //private var var_660:ColorTransform = new ColorTransform(); // unused?

        public function MiniMap()
        {
            addChild(this.m);
            this.blockSprite.graphics.beginFill(0);
        }

        // _loc4 = finishBox
        public function addBlock(blockCode:int, blockX:Number, blockY:Number)
        {
            if (blockCode == Objects.BLOCK_FINISH) {
                var finishBox:MiniMapFinishGraphic = new MiniMapFinishGraphic();
                finishBox.x = blockX + 15;
                finishBox.y = blockY + 15;
                this.finishSprite.addChild(finishBox);
            }
            this.drawBlock(blockX, blockY);
        }

        // deleted _loc3 (this.finishSprite.numChildren)
        public function removeFinish(_arg_1:int, _arg_2:int)
        {
            var _local_4:int;
            while (_local_4 < this.finishSprite.numChildren) {
                var _local_5:DisplayObject = this.finishSprite.getChildAt(_local_4);
                if (_local_5.x == _arg_1 && _local_5.y == _arg_2) {
                    this.finishSprite.removeChild(_local_5);
                    return;
                }
                _local_4++;
            }
        }

        // method_490 = drawBlock
        private function drawBlock(blockX:int, blockY:int)
        {
            this.blockSprite.graphics.beginFill(0);
            this.blockSprite.graphics.moveTo(blockX, blockY);
            this.blockSprite.graphics.lineTo(blockX + 30, blockY);
            this.blockSprite.graphics.lineTo(blockX + 30, blockY + 30);
            this.blockSprite.graphics.lineTo(blockX, blockY + 30);
            this.blockSprite.graphics.lineTo(blockX, blockY);
            this.blockSprite.graphics.endFill();
        }

        // _loc1 = dot
        public function getDot():MiniMapDot
        {
            var dot:MiniMapDot = new MiniMapDot();
            this.playerDots.addChild(dot);
            this.scaleChildDots(this.playerDots, this.holder.scaleX, 4);
            return dot;
        }

        public function rasterize()
        {
            this.blockSprite.graphics.endFill();
            this.blockSprite.scaleX = this.blockSprite.scaleY = 1;
            var _local_1:Number = this.maxSpaceWidth / this.blockSprite.width;
            var _local_2:Number = this.maxSpaceWidth / this.blockSprite.height;
            var _local_3:Number = this.maxSpaceHeight / this.blockSprite.height;
            var _local_4:Number = this.maxSpaceHeight / this.blockSprite.width;
            var _local_5:Number = _local_1 < _local_3 ? _local_1 : _local_3;
            var _local_6:Number = _local_2 < _local_4 ? _local_2 : _local_4;
            var _local_7:Number = _local_5 > _local_6 ? _local_5 : _local_6;
            this.finishSprite.scaleX = this.finishSprite.scaleY = this.playerDots.scaleX = this.playerDots.scaleY = this.blockSprite.scaleX = this.blockSprite.scaleY = _local_7;
            var _local_8:Sprite = new Sprite();
            _local_8.addChild(this.blockSprite);
            var _local_9:Rectangle = this.blockSprite.getBounds(_local_8);
            this.finishSprite.x = this.playerDots.x = this.blockSprite.x = -_local_9.left;
            this.finishSprite.y = this.playerDots.y = this.blockSprite.y = -_local_9.top;
            var _local_10:Number = Data.numLimit(this.blockSprite.width, 1, this.maxSpaceWidth);
            var _local_11:Number = Data.numLimit(this.blockSprite.height, 1, this.maxSpaceWidth);
            this.bitmapData = new BitmapData(Math.ceil(_local_10), Math.ceil(_local_11), true, 0);
            this.bitmap = new Bitmap(this.bitmapData);
            this.bitmapData.draw(_local_8);
            this.blockSprite.graphics.clear();
            this.blockSprite = new Sprite();
            addChild(this.holder);
            this.holder.addChild(this.bitmap);
            this.holder.addChild(this.finishSprite);
            this.holder.addChild(this.playerDots);
            this.applyScale();
        }

        private function applyScale()
        {
            this.holder.scaleX = this.holder.scaleY = 1;
            var _local_1:Rectangle = this.bitmap.getBounds(this);
            var _local_2:Number = this.maxSpaceWidth / _local_1.width;
            var _local_3:Number = this.maxSpaceHeight / _local_1.height;
            this.scale = _local_2 < _local_3 ? _local_2 : _local_3;
            this.scale = Data.numLimit(this.scale, 0, 1);
            this.holder.scaleX = this.holder.scaleY = this.scale;
            _local_1 = this.bitmap.getBounds(this);
            var _local_4:int = int((this.maxSpaceWidth - _local_1.width) / 2);
            var _local_5:int = int((this.maxSpaceHeight - _local_1.height) / 2);
            this.holder.x = this.holder.x + (_local_4 - _local_1.left) + 3;
            this.holder.y = this.holder.y + (_local_5 - _local_1.top) + 3;
            this.scaleChildDots(this.playerDots, this.scale, 4);
            this.scaleChildDots(this.finishSprite, this.scale, 4);
        }

        // deleted _loc5 (_arg_1.numChildren)
        private function scaleChildDots(_arg_1:Sprite, _arg_2:Number, _arg_3:Number)
        {
            var _local_4:int = 0;
            while (_local_4 < _arg_1.numChildren) {
                var _local_6:DisplayObject = _arg_1.getChildAt(_local_4);
                _local_6.width = _local_6.height = 4 / (_arg_2 * _arg_1.scaleX);
                _local_4++;
            }
        }

        public function rotate(_arg_1:Number)
        {
            this.holder.rotation = _arg_1;
            this.applyScale();
        }

        public function clear()
        {
            if (this.bitmapData != null) {
                /*var _local_1:Rectangle = new Rectangle(0, 0, this.bitmapData.width, this.bitmapData.height);
                this.bitmapData.fillRect(_local_1, 0);*/
                this.bitmapData.dispose();
                this.bitmapData = null;
            }
            while (this.finishSprite.numChildren > 0) {
                this.finishSprite.removeChildAt(0);
            }
        }

        override public function remove()
        {
            /*if (this.bitmapData != null) {
                this.bitmapData.dispose();
                this.bitmapData = null;
            }*/
            this.clear();
            while (this.playerDots.numChildren > 0) {
                this.playerDots.getChildAt(0).remove();
                this.playerDots.removeChildAt(0);
            }
            removeChild(this.m);
            this.bitmap = null;
            this.holder = null;
            this.blockSprite = null;
            this.finishSprite = null;
            this.playerDots = null;
            this.m = null;
            super.remove();
        }


    }
}
