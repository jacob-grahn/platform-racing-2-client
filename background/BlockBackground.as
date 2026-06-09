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
        public var blocksAttached:int = 0;

        public function BlockBackground(gp:GamePage)
        {
            super(gp);
            this.addStartPositions();
            segMult = this.segSize;
            saveCodeOffset = -100;
        }

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

        override public function addObject(blockId:int, blockX:int, blockY:int, blockOpts:String = '')
        {
            if (this.isOpen(blockX, blockY)) {
                super.addObject(blockId, blockX, blockY, blockOpts);
            }
        }

        override protected function attachObject(blockId:int, blockX:int, blockY:int, blockOpts:String = '')
        {
            blockId += blockId < 100 ? 100 : 0;
            var block:BlockObject = new BlockObject(blockId, blockX, blockY, blockOpts);
            objArray.push(block);
            this.blocksAttached++;
            var seg:Point = new Point(Math.round(blockX / this.segSize), Math.round(blockY / this.segSize));
            this.addToBlockArray(block, seg);
            if (isInView(seg.x, seg.y)) {
                addChild(block);
            }
        }

        override public function setPos(posX:Number, posY:Number)
        {
            super.setPos(posX, posY);
            var rotatedCoursePos:Point = Data.rotatePoint(GamePage.course.posX, GamePage.course.posY, rotation);
            var courseSeg:Point = this.getSegFromPos(rotatedCoursePos.x, rotatedCoursePos.y);
            updateViewWindow(-courseSeg.x, -courseSeg.y, 11, 9, 8, 6, this, this.blockArray);
        }

        override public function undo()
        {
            if (saveArray.length > 4) {
                super.undo();
            }
        }

        public function addToBlockArray(block:DisplayObject, seg:Point)
        {
            if (this.blockArray[seg.x] == null) {
                this.blockArray[seg.x] = new Array();
            }
            this.blockArray[seg.x][seg.y] = block;
        }

        public function getAllBlocksOfType(type:Class)
        {
            var ret:Array = [];
            for (var segX:* in this.blockArray) {
                for (var segY:* in this.blockArray[segX]) {
                    if (this.blockArray[segX][segY] != null && this.blockArray[segX][segY].m is type) {
                        ret.push(this.blockArray[segX][segY]);
                    }
                }
            }
            return ret;
        }

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

        public function isOpen(posX:Number, posY:Number):Boolean
        {
            var segX:int = int(Math.round(posX / this.segSize));
            var segY:int = int(Math.round(posY / this.segSize));
            var block:BlockObject = this.getBlockFromSeg(segX, segY);
            return block == null;
        }

        public function getBlockFromPos(posX:Number, posY:Number, rotMod:Boolean=false):*
        {
            var pos:Point = rotMod ? Data.rotatePoint(posX, posY, rotation) : new Point(posX, posY);
            var seg:Point = this.getSegFromPos(pos.x, pos.y);
            return this.getBlockFromSeg(seg.x, seg.y);
        }

        public function getBlockFromSeg(segX:int, segY:int)
        {
            var blockColumn:Array = this.blockArray.length >= segX ? this.blockArray[segX] : null;
            return blockColumn != null ? blockColumn[segY] : null;
        }

        override public function removeObjectsTouchingPoint(ptX:Number, ptY:Number)
        {
            var point:Point = this.globalToLocal(new Point(ptX, ptY));
            var block:BlockObject = this.getBlockAt(point.x - 15, point.y - 15);
            if (block != null && block.deleteable) {
                recordDelete(block);
                block.remove();
            }
        }

        override protected function moveDrawObject(moveData:String)
        {
            var moveParts:Array = moveData.split(";");
            var blockIndex:Number = Number(moveParts[0]);
            var block:BlockObject = BlockObject(objArray[blockIndex]);
            if (block != null) {
                var blockX:Number = Number(moveParts[1]);
                var blockY:Number = Number(moveParts[2]);
                this.moveBlock(new Point(block.segX, block.segY), this.getSegFromPos(blockX, blockY));
            }
        }

        override protected function drawText(_arg_1:String)
        {
        }

        public function getSegFromPos(posX:Number, posY:Number):Point
        {
            var segX:Number = Math.floor(posX / this.segSize);
            var segY:Number = Math.floor(posY / this.segSize);
            return new Point(segX, segY);
        }

        public function getPosFromSeg(segX:Number, segY:Number):Point
        {
            var posX:Number = segX * this.segSize;
            var posY:Number = segY * this.segSize;
            return new Point(posX, posY);
        }

        public function getStartPos():Point
        {
            var block:BlockObject = objArray[0];
            return new Point(block.x, block.y);
        }

        public function removeBlock(block:*)
        {
            var seg:Point = block.getSeg();
            if (this.blockArray[seg.x] != null) {
                this.blockArray[seg.x][seg.y] = null;
            }
            var blockIndex:int = objArray.indexOf(block);
            if (blockIndex != -1) {
                objArray.splice(blockIndex, 1);
            }
        }

        public function moveBlock(originPt:Point, destPt:Point):Point
        {
            if (this.blockArray[originPt.x] != null) {
                var block:DisplayObject = this.blockArray[originPt.x][originPt.y];
                if (block != null && this.testMove(destPt.x, destPt.y)) {
                    this.addToBlockArray(null, originPt);
                    this.addToBlockArray(block, destPt);
                    block.setSeg(destPt.x, destPt.y);
                    if (isInView(destPt.x, destPt.y)) {
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
