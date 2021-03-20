// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.Map = background.class_79

package background
{
    import blocks.*;
    import blocks.Block;
    import blocks.FinishBlock;
    import blocks.MoveBlock;
    import blocks.StartBlock;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Random;
    import flash.geom.Point;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import package_6.Course;
    import package_6.MiniMap;
    import package_8.Character;
    import package_9.Egg;

    public class Map extends BlockBackground 
    {

        // removed var_688 (unused)
        private var startBlockNum:int = 0; // var_400
        private var miniMap:MiniMap;
        private var moveInterval:uint; // var_296
        private var segSize:Number = 30;
        public var maxY:Number = -9999999;
        public var minY:Number = 9999999;
        public var maxX:Number = -9999999;
        public var minX:Number = 9999999;
        private var moveBlocksArray:Vector.<MoveBlock> = new Vector.<MoveBlock>(); // var_196
        private var startTime:int;
        private var moves:int = 0; // var_506
        private var moveTime:int = 5000; // var_534
        private var rand:Random = new Random(1);
        private var placedEggs:int = 0; // var_446
        private var eggPtsArray:Array = new Array(); // var_379

        public function Map(m:MiniMap, c:Course)
        {
            this.miniMap = m;
            super(c);
            CommandHandler.commandHandler.defineCommand("activate", this.activate);
        }


        // _loc2 = blockX
        // _loc3 = blockY
        // _loc5 = activated
        public function activate(arr:Array)
        {
            var blockX:int = int(arr[0]);
            var blockY:int = int(arr[1]);
            var _local_4:String = arr[2];
            var activated:Block = getBlockFromSeg(blockX, blockY);
            if (activated != null) {
                activated.remoteActivate(_local_4);
            }
        }

        override protected function addStartPositions()
        {
        }

        // method_488 = placeBlock
        public function placeBlock(_arg_1:int, _arg_2:Number, _arg_3:Number)
        {
            this.attachObject(_arg_1, _arg_2, _arg_3);
        }

        // _loc5 = block
        // _loc6 = finishBlock
        override protected function attachObject(blockCode:int, x:int, y:int)
        {
            if (blockCode < 100) {
                blockCode += 100;
            }
            var _local_4:Point = getSegFromPos(x, y);
            if (blockCode == Objects.BLOCK_MINION_EGG) {
                this.eggPtsArray.push(new Point(x, y));
            } else {
                var block:Block = Block(Objects.getFromCode(blockCode));
                if (block is StartBlock) {
                    this.setStartPos(this.startBlockNum, x + 15, y + 15);
                    this.startBlockNum++;
                } else {
                    if (block is FinishBlock) {
                        var finishBlock:FinishBlock = FinishBlock(block);
                        this.addFinish(finishBlock.getId(), x + 15, y + 15);
                    }
                    method_53(block, _local_4);
                    if (!block.isInitialized()) {
                        block.initialize(_local_4.x, _local_4.y, this);
                    }
                    if (method_32(_local_4.x, _local_4.y)) {
                        addChild(block);
                    }
                    if (block is MoveBlock) {
                        this.moveBlocksArray.push(block);
                    }
                    this.miniMap.method_680(blockCode, x, y);
                }
            }
            if (y > this.maxY) {
                this.maxY = y;
            } else if (y < this.minY) {
                this.minY = y;
            }
            if (x > this.maxX) {
                this.maxX = x;
            } else if (x < this.minX) {
                this.minX = x;
            }
        }

        // method_485 = placeEggs
        private function placeEggs()
        {
            for each (var eggPt:Point in this.eggPtsArray) {
                this.attachEgg(eggPt.x + 15, eggPt.y + 15);
            }
            this.eggPtsArray = new Array();
        }

        // _loc3 = egg
        // method_552 = attachEgg
        private function attachEgg(eggX:int, eggY:int)
        {
            if (this.placedEggs < 25) {
                var egg:Egg = new Egg();
                egg.posX = eggX + 15;
                egg.posY = eggY + 15;
                egg.rot = 0;
                egg.setLimits();
                this.placedEggs++;
            }
        }

        // deleted _loc4 (Course.course)
        private function setStartPos(startNum:int, startX:int, startY:int)
        {
            Course.course.addStartPos(startNum, new Point(startX, startY));
        }

        // deleted _loc4 (Course.course)
        // method_516 = addFinish
        private function addFinish(finishId:int, finishX:int, finishY:int)
        {
            Course.course.finishBlocks.push({
                "id": finishId,
                "x": finishX,
                "y": finishY
            });
        }

        override public function draw(_arg_1:Number=50)
        {
            super.draw(_arg_1);
            if (var_39 >= var_15.length) {
                this.miniMap.rasterize();
            }
        }

        public function method_578()
        {
            this.startTime = new Date().time;
            this.determineMoveBlockDirection();
            this.placeEggs();
        }

        // _loc1 = i
        // _loc2 = totalMoveBlocks
        // _loc3 = block
        // _loc4 = dir
        // deleted _loc5&6 (unused)
        // method_416 = determineMoveBlockDirection
        private function determineMoveBlockDirection()
        {
            var totalMoveBlocks:int = this.moveBlocksArray.length;
            var i:int = 0;
            while (i < totalMoveBlocks) {
                var block:MoveBlock = this.moveBlocksArray[i];
                var dir:int = this.rand.nextMinMax(0, 4);
                block.setDirection(dir);
                i++;
            }
            this.setMoveInterval(this.doMoveBlocks, 1000);
        }

        // _loc1 = i
        // removed _loc2 (unneeded)
        // _loc3 = block
        // method_784 = doMoveBlocks
        private function doMoveBlocks()
        {
            for (var i:int = 0; i < this.moveBlocksArray.length; i++) {
                var block:MoveBlock = this.moveBlocksArray[i];
                block.shift(this);
            }
            var _local_4:int = this.startTime + (this.moves * this.moveTime) - new Date().time;
            if (_local_4 < 1) {
                _local_4 = 1;
            }
            this.setMoveInterval(this.determineMoveBlockDirection, _local_4 + this.moveTime);
            this.moves++;
        }

        // deleted _loc3 (simplified return)
        override public function testMove(_arg_1:int, _arg_2:int):Boolean
        {
            if ((blockArray[_arg_1] == null || blockArray[_arg_1][_arg_2] == null) && !this.characterOccupiesSpace(_arg_1, _arg_2)) {
                return true;
            }
            return false;
        }

        // deleted _loc5 (simplified return)
        // _loc6 = p
        public function characterOccupiesSpace(xVal:int, yVal:int):Boolean
        {
            if (Course.course != null) {
                for each (var p:Character in Course.course.playerArray) {
                    if (p != null) {
                        var _local_3:Point = p.seg1;
                        var _local_4:Point = p.seg2;
                        if ((_local_3.x == xVal && _local_3.y == yVal) || (_local_4.x == xVal && _local_4.y == yVal)) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }

        private function setMoveInterval(fn:Function, secs:int)
        {
            this.clearMoveInterval();
            this.moveInterval = setTimeout(fn, secs);
        }

        public function clearMoveInterval()
        {
            clearTimeout(this.moveInterval);
        }

        override public function clear()
        {
            while (numChildren > 0) {
                var _local_1:Block = Block(getChildAt(0));
                _local_1.remove();
            }
            var_39 = 0;
            blockArray = new Array();
            var_10 = new Array();
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("activate", null);
            this.moveBlocksArray = null;
            this.clearMoveInterval();
            this.miniMap = null;
            super.remove();
        }


    }
}//package background

