// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.class_78 = background.BlockBackground

package background
{
    import page.GamePage;
    import levelEditor.BlockObject;
    import flash.geom.Point;
    import data.class_28;
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
            var _local_1:Number;
            var _local_2:Number;
            var _local_3:Number = 0;
            var _local_4:Number = 30;
            _local_3 = 111;
            while (_local_3 <= 114) {
                _local_1 = ((_local_3 * _local_4) + 10000);
                _local_2 = ((_local_4 * 2) + 10000);
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
            if (_arg_1 < 100) {
                _arg_1 = (_arg_1 + 100);
            }
            var _local_4:BlockObject = new BlockObject(_arg_1, _arg_2, _arg_3);
            var_10.push(_local_4);
            this.var_323++;
            var _local_5:Point = new Point(Math.round((_arg_2 / 30)), Math.round((_arg_3 / 30)));
            this.method_53(_local_4, _local_5);
            if (method_32(_local_5.x, _local_5.y)) {
                addChild(_local_4);
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            var _local_3:Point = class_28.method_9(GamePage.course.posX, GamePage.course.posY, rotation);
            var _local_4:Point = this.getSegFromPos(_local_3.x, _local_3.y);
            method_118(-(_local_4.x), -(_local_4.y), 11, 9, 8, 6, this, this.blockArray);
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

        public function getBlockAt(_arg_1:Number, _arg_2:Number):BlockObject
        {
            var _local_3:BlockObject;
            var _local_4:int = int(Math.round((_arg_1 / 30)));
            var _local_5:int = int(Math.round((_arg_2 / 30)));
            var _local_6:Array = this.blockArray[_local_4];
            if (_local_6 != null) {
                _local_3 = BlockObject(_local_6[_local_5]);
            } else {
                _local_3 = null;
            }
            return (_local_3);
        }

        public function isOpen(_arg_1:Number, _arg_2:Number):Boolean
        {
            var _local_3:Boolean = true;
            var _local_4:int = int(Math.round((_arg_1 / 30)));
            var _local_5:int = int(Math.round((_arg_2 / 30)));
            var _local_6:BlockObject = this.getBlockFromSeg(_local_4, _local_5);
            if (_local_6 != null) {
                _local_3 = false;
            }
            return (_local_3);
        }

        // _loc4 = pos
        // _loc5 = seg
        // deleted _loc6 (merge w/ return statement)
        // method_24 = getBlockFromPos
        public function getBlockFromPos(x:Number, y:Number, rotMod:Boolean=false):*
        {
            var pos:Point;
            if (rotMod) {
                pos = class_28.method_9(x, y, rotation);
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
            return (_local_3);
        }

        override public function removeObjectsTouchingPoint(_arg_1:Number, _arg_2:Number)
        {
            var _local_3:Point = new Point(_arg_1, _arg_2);
            _local_3 = this.globalToLocal(_local_3);
            var _local_4:BlockObject = this.getBlockAt((_local_3.x - 15), (_local_3.y - 15));
            if (((!(_local_4 == null)) && (_local_4.deleteable))) {
                recordDelete(_local_4);
                _local_4.remove();
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

        public function getSegFromPos(_arg_1:Number, _arg_2:Number):Point
        {
            var _local_3:Number = Math.floor((_arg_1 / this.segSize));
            var _local_4:Number = Math.floor((_arg_2 / this.segSize));
            var _local_5:Point = new Point(_local_3, _local_4);
            return (_local_5);
        }

        public function method_497(_arg_1:Number, _arg_2:Number):Point
        {
            var _local_3:Number = (_arg_1 * this.segSize);
            var _local_4:Number = (_arg_2 * this.segSize);
            var _local_5:Point = new Point(_local_3, _local_4);
            return (_local_5);
        }

        public function method_753():Point
        {
            var _local_1:BlockObject = var_10[0];
            return (new Point(_local_1.x, _local_1.y));
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
                    } else {
                        if (_local_3.parent != null) {
                            _local_3.parent.removeChild(_local_3);
                        }
                    }
                    _arg_1.x = _arg_2.x;
                    _arg_1.y = _arg_2.y;
                }
            }
            return (_arg_1);
        }

        public function testMove(_arg_1:int, _arg_2:int):Boolean
        {
            return (true);
        }

        override public function clear()
        {
            super.clear();
            this.blockArray = new Array();
        }

        override public function remove()
        {
            this.clear();
            if (this.var_323 != 0) {
            }
            super.remove();
        }


    }
}//package background

