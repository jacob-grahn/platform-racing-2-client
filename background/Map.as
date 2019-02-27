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
    import data.Objects;
    import data.CommandHandler;
    import data.Random;
    import flash.geom.Point;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import package_6.Course;
    import package_6.MiniMap;
    import package_8.Character;
    import package_9.Egg;
    //import __AS3__.vec.*;
    //import __AS3__.vec.Vector;

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
        private var var_446:int = 0;
        private var var_379:Array = new Array();

        public function Map(m:MiniMap, c:Course)
        {
            this.miniMap = m;
            super(c);
            CommandHandler.commandHandler.defineCommand("activate", this.activate);
        }

        public function activate(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:int = int(_arg_1[1]);
            var _local_4:String = _arg_1[2];
            var _local_5:Block = getBlockFromPoint(_local_2, _local_3);
            if (_local_5 != null) {
                _local_5.remoteActivate(_local_4);
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
            var _local_4:Point = method_52(x, y);
            if (blockCode == Objects.EggMinionBlockCode) {
                this.var_379.push(new Point(x, y));
            } else {
                var block:Block = Block(Objects.getFromCode(blockCode));
                if (block is StartBlock) {
                    this.setStartPos(this.startBlockNum, x + 15, y + 15);
                    this.startBlockNum++;
                } else {
                    if (block is FinishBlock) {
                        var finishBlock:FinishBlock = FinishBlock(block);
                        this.method_516(finishBlock.getId(), x + 15, y + 15);
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
            }
            if (y < this.minY) {
                this.minY = y;
            }
            if (x > this.maxX) {
                this.maxX = x;
            }
            if (x < this.minX) {
                this.minX = x;
            }
        }

        private function method_485()
        {
            var _local_1:Point;
            for each (_local_1 in this.var_379) {
                this.method_552((_local_1.x + 15), (_local_1.y + 15));
            }
            this.var_379 = new Array();
        }

        // _loc3 = egg
        private function method_552(eggX:int, eggY:int)
        {
            if (this.var_446 < 25) {
                var egg:Egg = new Egg();
                egg.posX = eggX + 15;
                egg.posY = eggY + 15;
                egg.rot = 0;
                egg.setLimits();
                this.var_446++;
            }
        }

        private function setStartPos(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            var _local_4:Course = Course.course;
            _local_4.method_514(_arg_1, new Point(_arg_2, _arg_3));
        }

        private function method_516(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            var _local_4:Course = Course.course;
            _local_4.var_313.push({
                "id":_arg_1,
                "x":_arg_2,
                "y":_arg_3
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
            this.method_485();
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
            this.moveInterval = setTimeout(this.doMoveBlocks, 1000);
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
            this.moveInterval = setTimeout(this.determineMoveBlockDirection, _local_4 + this.moveTime);
            this.moves++;
        }

        override public function testMove(_arg_1:int, _arg_2:int):Boolean
        {
            var _local_3:Boolean;
            if ((blockArray[_arg_1] == null || blockArray[_arg_1][_arg_2] == null) && !this.characterOccupiesSpace(_arg_1, _arg_2)) {
                _local_3 = true;
            }
            return (_local_3);
        }

        // _loc5 = occupies
        public function characterOccupiesSpace(xVal:int, yVal:int):Boolean
        {
            var _local_3:Point;
            var _local_4:Point;
            var occupies:Boolean = false;
            if (Course.course != null) {
                for each (var _local_6:Character in Course.course.var_40) {
                    if (_local_6 != null) {
                        _local_3 = _local_6.seg1;
                        _local_4 = _local_6.seg2;
                        if ((_local_3.x == xVal && _local_3.y == yVal) || (_local_4.x == xVal && _local_4.y == yVal)) {
                            occupies = true;
                            break;
                        }
                    }
                }
            }
            return occupies;
        }

        public function clearMoveInterval()
        {
            clearTimeout(this.moveInterval);
        }

        override public function clear()
        {
            var _local_1:Block;
            while (numChildren > 0) {
                _local_1 = Block(getChildAt(0));
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

