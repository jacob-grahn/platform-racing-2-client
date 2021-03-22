// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.class_78 = background.BlockBackground

package background
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.DisplayObject;
    import flash.geom.Point;
    import levelEditor.BlockObject;
    import page.GamePage;

    public class BlockBackground extends ObjectBackground 
    {

        private var segSize:Number = 30;
        protected var blockArray:Array = new Array();
        public var blocksAttached:int = 0; // var_323

        public function BlockBackground(gp:GamePage)
        {
            super(gp);
            this.addStartPositions();
            var_367 = 30;
            var_379 = -100;
        }

        // _loc1 = startX
        // _loc2 = startY
        // _loc3 = startBlockId
        // deleted _loc4 (this.segSize)
        protected function addStartPositions()
        {
            var startBlockId:Number = Objects.BLOCK_START1; // 111
            while (startBlockId <= Objects.BLOCK_START4) { // 114
                var startX:Number = (startBlockId * this.segSize) + 10000;
                var startY:Number = (this.segSize * 2) + 10000;
                this.addObject(startBlockId, startX, startY);
                startBlockId++;
            }
        }

        override public function addObject(blockId:int, blockX:int, blockY:int)
        {
            if (this.isOpen(blockX, blockY)) {
                super.addObject(blockId, blockX, blockY);
            }
        }

        // _loc4 = block
        // _loc5 = seg
        override protected function attachObject(blockId:int, blockX:int, blockY:int)
        {
            blockId += blockId < 100 ? 100 : 0;
            var block:BlockObject = new BlockObject(blockId, blockX, blockY);
            objArray.push(block);
            this.blocksAttached++;
            var seg:Point = new Point(Math.round(blockX / this.segSize), Math.round(blockY / this.segSize));
            this.addToBlockArray(block, seg);
            if (method_32(seg.x, seg.y)) {
                addChild(block);
            }
        }

        override public function setPos(posX:Number, posY:Number)
        {
            super.setPos(posX, posY);
            var _local_3:Point = Data.method_9(GamePage.course.posX, GamePage.course.posY, rotation);
            var _local_4:Point = this.getSegFromPos(_local_3.x, _local_3.y);
            method_118(-_local_4.x, -_local_4.y, 11, 9, 8, 6, this, this.blockArray);
        }

        override public function undo()
        {
            if (saveArray.length > 4) {
                super.undo();
            }
        }

        // method_53 = addToBlockArray
        public function addToBlockArray(block:DisplayObject, seg:Point)
        {
            if (this.blockArray[seg.x] == null) {
                this.blockArray[seg.x] = new Array();
            }
            this.blockArray[seg.x][seg.y] = block;
        }

        // deleted _loc3 (simplified return)
        // _loc4 = segX
        // _loc5 = segY
        // _loc6 = blockColumn (block column)
        public function getBlockAt(posX:Number, posY:Number):BlockObject
        {
            var segX:int = int(Math.round(posX / this.segSize));
            var segY:int = int(Math.round(posY / this.segSize));
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
            var segX:int = int(Math.round(posX / this.segSize));
            var segY:int = int(Math.round(posY / this.segSize));
            var block:BlockObject = this.getBlockFromSeg(segX, segY);
            return block == null;
        }

        // _loc4 = pos
        // _loc5 = seg
        // deleted _loc6 (merge w/ return statement)
        // method_24 = getBlockFromPos
        public function getBlockFromPos(posX:Number, posY:Number, rotMod:Boolean=false):*
        {
            var pos:Point = rotMod ? Data.method_9(posX, posY, rotation) : new Point(posX, posY);
            var seg:Point = this.getSegFromPos(pos.x, pos.y);
            return this.getBlockFromSeg(seg.x, seg.y);
        }

        // deleted _loc3 (simplified return)
        // _loc4 = blockColumn
        // method_67 = getBlockFromSeg
        public function getBlockFromSeg(segX:int, segY:int)
        {
            var blockColumn:Array = this.blockArray.length >= segX ? this.blockArray[segX] : null;
            return blockColumn != null ? blockColumn[segY] : null;
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

        // deleted _loc6 (this.getSegFromPos(_local_4, _local_5))
        // _loc7 = block
        override protected function moveDrawObject(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var block:BlockObject = BlockObject(objArray[_local_3]);
            if (block != null) {
                var _local_4:Number = Number(_local_2[1]);
                var _local_5:Number = Number(_local_2[2]);
                this.moveBlock(new Point(block.segX, block.segY), this.getSegFromPos(_local_4, _local_5));
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

        // _loc1 = block
        public function method_753():Point
        {
            var block:BlockObject = objArray[0];
            return new Point(block.x, block.y);
        }

        // _loc2 = seg
        // method_259 = removeBlock
        public function removeBlock(block:*)
        {
            var seg:Point = block.getSeg();
            if (this.blockArray[seg.x] != null) {
                this.blockArray[seg.x][seg.y] = null;
            }
            var _local_3:int = objArray.indexOf(block);
            if (_local_3 != -1) {
                objArray.splice(_local_3, 1);
            }
        }

        // _loc3 = block
        public function moveBlock(originPt:Point, destPt:Point):Point
        {
            if (this.blockArray[originPt.x] != null) {
                var block:DisplayObject = this.blockArray[originPt.x][originPt.y];
                if (block != null && this.testMove(destPt.x, destPt.y)) {
                    this.addToBlockArray(null, originPt);
                    this.addToBlockArray(block, destPt);
                    block.setSeg(destPt.x, destPt.y);
                    if (method_32(destPt.x, destPt.y)) {
                        addChild(block);
                    } else if (block.parent != null) {
                        block.parent.removeChild(block);
                    }
                    originPt.x = destPt.x;
                    originPt.y = destPt.y;
                }
            }
            return originPt;
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
            super.remove();
        }


    }
}//package background

