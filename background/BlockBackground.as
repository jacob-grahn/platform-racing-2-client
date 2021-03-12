// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.class_78 = background.BlockBackground

package background
{
    import page.GamePage;
    import levelEditor.BlockObject;
    import flash.geom.Point;
    import com.jiggmin.data.Data;
    import flash.display.DisplayObject;

    public class BlockBackground extends class_77 
    {

        private var segSize:Number = 30;
        protected var blockArray:Array = new Array();
        public var var_323:int = 0;

        public function BlockBackground(gp:GamePage)
        {
            super(gp);
            this.addStartPositions();
            var_367 = 30;
            var_379 = -100;
        }

        protected function addStartPositions()
        {
            var _local_3:Number = 111;
            var _local_4:Number = 30;
            while (_local_3 <= 114) {
                var _local_1:Number = (_local_3 * _local_4) + 10000;
                var _local_2:Number = (_local_4 * 2) + 10000;
                this.addObject(_local_3, _local_1, _local_2);
                _local_3++;
            }
        }

        override public function addObject(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            if (this.isOpen(_arg_2, _arg_3)) {
                super.addObject(_arg_1, _arg_2, _arg_3);
            }
        }

        override protected function attachObject(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            _arg_1 += _arg_1 < 100 ? 100 : 0;
            var _local_4:BlockObject = new BlockObject(_arg_1, _arg_2, _arg_3);
            var_10.push(_local_4);
            this.var_323++;
            var _local_5:Point = new Point(Math.round(_arg_2 / 30), Math.round(_arg_3 / 30));
            this.method_53(_local_4, _local_5);
            if (method_32(_local_5.x, _local_5.y)) {
                addChild(_local_4);
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            var _local_3:Point = Data.method_9(GamePage.course.posX, GamePage.course.posY, rotation);
            var _local_4:Point = this.getSegFromPos(_local_3.x, _local_3.y);
            method_118(-_local_4.x, -_local_4.y, 11, 9, 8, 6, this, this.blockArray);
        }

        override public function undo()
        {
            if (var_15.length > 4) {
                super.undo();
            }
        }

        public function method_53(_arg_1:DisplayObject, _arg_2:Point)
        {
            if (this.blockArray[_arg_2.x] == null) {
                this.blockArray[_arg_2.x] = new Array();
            }
            this.blockArray[_arg_2.x][_arg_2.y] = _arg_1;
        }

        // deleted _loc3 (simplified return)
        // _loc4 = segX
        // _loc5 = segY
        // _loc6 = blockColumn (block column)
        public function getBlockAt(posX:Number, posY:Number):BlockObject
        {
            var segX:int = int(Math.round(posX / 30));
            var segY:int = int(Math.round(posY / 30));
            var blockColumn:Array = this.blockArray[segX];
            if (blockColumn != null) {
                return BlockObject(blockColumn[segY]);
            }
            return null;
        }

        // deleted _loc3 (simplified return)
        // _loc4 = segX
        // _loc5 = segY
        // _loc6 = block
        public function isOpen(posX:Number, posY:Number):Boolean
        {
            var segX:int = int(Math.round(posX / 30));
            var segY:int = int(Math.round(posY / 30));
            var block:BlockObject = this.getBlockFromSeg(segX, segY);
            if (block != null) {
                return false;
            }
            return true;
        }

        // _loc4 = pos
        // _loc5 = seg
        // deleted _loc6 (merge w/ return statement)
        // method_24 = getBlockFromPos
        public function getBlockFromPos(x:Number, y:Number, rotMod:Boolean=false):*
        {
            var pos:Point;
            if (rotMod) {
                pos = Data.method_9(x, y, rotation);
            } else {
                pos = new Point(x, y);
            }
            var seg:Point = this.getSegFromPos(pos.x, pos.y);
            return this.getBlockFromSeg(seg.x, seg.y);
        }

        // method_67 = getBlockFromSeg
        public function getBlockFromSeg(x:int, y:int):*
        {
            var _local_3:*;
            var _local_4:Array;
            if (this.blockArray.length >= x) {
                _local_4 = this.blockArray[x];
            }
            if (_local_4 != null) {
                _local_3 = _local_4[y];
            } else {
                _local_3 = null;
            }
            return _local_3;
        }

        // _loc3 = point
        // _loc4 = block
        override public function removeObjectsTouchingPoint(x:Number, y:Number)
        {
            var point:Point = this.globalToLocal(new Point(x, y));
            var block:BlockObject = this.getBlockAt(point.x - 15, point.y - 15);
            if (block != null && block.deleteable) {
                recordDelete(block);
                block.remove();
            }
        }

        override protected function moveDrawObject(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var _local_6:Point = this.getSegFromPos(_local_4, _local_5);
            var _local_7:BlockObject = BlockObject(var_10[_local_3]);
            if (_local_7 != null) {
                this.moveBlock(new Point(_local_7.segX, _local_7.segY), _local_6);
            }
        }

        override protected function drawText(_arg_1:String)
        {
        }

        // _loc3 = segX
        // _loc4 = segY
        // deleted _loc5 (combined w/ return)
        public function getSegFromPos(posX:Number, posY:Number):Point
        {
            var segX:Number = Math.floor(posX / this.segSize);
            var segY:Number = Math.floor(posY / this.segSize);
            return new Point(segX, segY);
        }

        // _loc3 = posX
        // _loc4 = posY
        // deleted _loc5 (combined w/ return)
        // method_497 = getPosFromSeg
        public function getPosFromSeg(segX:Number, segY:Number):Point
        {
            var posX:Number = segX * this.segSize;
            var posY:Number = segY * this.segSize;
            return new Point(posX, posY);
        }

        public function method_753():Point
        {
            var _local_1:BlockObject = var_10[0];
            return new Point(_local_1.x, _local_1.y);
        }

        public function method_259(_arg_1:*)
        {
            var _local_2:Point = _arg_1.getSeg();
            if (this.blockArray[_local_2.x] != null) {
                this.blockArray[_local_2.x][_local_2.y] = null;
            }
            var _local_3:int = var_10.indexOf(_arg_1);
            if (_local_3 != -1) {
                var_10.splice(_local_3, 1);
            }
        }

        public function moveBlock(_arg_1:Point, _arg_2:Point):Point
        {
            var _local_3:*;
            if (this.blockArray[_arg_1.x] != null) {
                _local_3 = this.blockArray[_arg_1.x][_arg_1.y];
                if (_local_3 != null && this.testMove(_arg_2.x, _arg_2.y)) {
                    this.method_53(null, _arg_1);
                    this.method_53(_local_3, _arg_2);
                    _local_3.setSeg(_arg_2.x, _arg_2.y);
                    if (method_32(_arg_2.x, _arg_2.y)) {
                        addChild(_local_3);
                    } else if (_local_3.parent != null) {
                        _local_3.parent.removeChild(_local_3);
                    }
                    _arg_1.x = _arg_2.x;
                    _arg_1.y = _arg_2.y;
                }
            }
            return _arg_1;
        }

        public function testMove(_arg_1:int, _arg_2:int):Boolean
        {
            return true;
        }

        override public function clear()
        {
            super.clear();
            this.blockArray = new Array();
        }

        override public function remove()
        {
            this.clear();
            /*if (this.var_323 != 0) {
            }*/
            super.remove();
        }


    }
}//package background

