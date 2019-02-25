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
    import package_9.class_82;
    //import __AS3__.vec.*;
    //import __AS3__.vec.Vector;

    public class Map extends class_78 
    {

        private var var_400:int = 0;
        private var miniMap:MiniMap;
        private var var_496:uint;
        private var segSize:Number = 30;
        public var var_688:Boolean = false;
        public var maxY:Number = -9999999;
        public var minY:Number = 9999999;
        public var maxX:Number = -9999999;
        public var minX:Number = 9999999;
        private var var_196:Vector.<MoveBlock> = new Vector.<MoveBlock>();
        private var startTime:int;
        private var var_506:int = 0;
        private var var_534:int = 5000;
        private var rand:Random = new Random(1);
        private var var_446:int = 0;
        private var var_379:Array = new Array();

        public function Map(_arg_1:MiniMap, _arg_2:Course)
        {
            this.miniMap = _arg_1;
            super(_arg_2);
            CommandHandler.commandHandler.defineCommand("activate", this.activate);
        }

        public function activate(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:int = int(_arg_1[1]);
            var _local_4:String = _arg_1[2];
            var _local_5:Block = method_67(_local_2, _local_3);
            if (_local_5 != null) {
                _local_5.remoteActivate(_local_4);
            }
        }

        override protected function addStartPositions()
        {
        }

        public function method_488(_arg_1:int, _arg_2:Number, _arg_3:Number)
        {
            this.attachObject(_arg_1, _arg_2, _arg_3);
        }

        override protected function attachObject(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            var _local_5:Block;
            var _local_6:FinishBlock;
            if (_arg_1 < 100) {
                _arg_1 = _arg_1 + 100;
            }
            var _local_4:Point = method_52(_arg_2, _arg_3);
            if (_arg_1 == Objects.EggMinionBlockCode) {
                this.var_379.push(new Point(_arg_2, _arg_3));
            } else {
                _local_5 = Block(Objects.getFromCode(_arg_1));
                if ((_local_5 is StartBlock)) {
                    this.setStartPos(this.var_400, (_arg_2 + 15), (_arg_3 + 15));
                    this.var_400++;
                } else {
                    if (_local_5 is FinishBlock) {
                        _local_6 = FinishBlock(_local_5);
                        this.method_516(_local_6.getId(), (_arg_2 + 15), (_arg_3 + 15));
                    }
                    method_53(_local_5, _local_4);
                    _local_5.initialize(_local_4.x, _local_4.y, this);
                    if (method_32(_local_4.x, _local_4.y)) {
                        addChild(_local_5);
                    }
                    if ((_local_5 is MoveBlock)) {
                        this.var_196.push(_local_5);
                    }
                    this.miniMap.method_680(_arg_1, _arg_2, _arg_3);
                }
            }
            if (_arg_3 > this.maxY) {
                this.maxY = _arg_3;
            }
            if (_arg_3 < this.minY) {
                this.minY = _arg_3;
            }
            if (_arg_2 > this.maxX) {
                this.maxX = _arg_2;
            }
            if (_arg_2 < this.minX) {
                this.minX = _arg_2;
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

        private function method_552(_arg_1:int, _arg_2:int)
        {
            var _local_3:class_82;
            if (this.var_446 < 25) {
                _local_3 = new class_82();
                _local_3.posX = (_arg_1 + 15);
                _local_3.posY = (_arg_2 + 15);
                _local_3.rot = 0;
                _local_3.method_324();
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
            this.method_416();
            this.method_485();
        }

        private function method_416()
        {
            var _local_1:int;
            var _local_3:MoveBlock;
            var _local_4:int;
            var _local_5:int;
            var _local_6:String;
            var _local_2:int = this.var_196.length;
            _local_1 = 0;
            while (_local_1 < _local_2) {
                _local_3 = this.var_196[_local_1];
                _local_4 = this.rand.method_55(0, 4);
                _local_3.method_731(_local_4);
                _local_1++;
            }
            this.var_496 = setTimeout(this.method_784, 1000);
        }

        private function method_784()
        {
            var _local_1:int;
            var _local_3:MoveBlock;
            var _local_2:int = this.var_196.length;
            _local_1 = 0;
            while (_local_1 < _local_2) {
                _local_3 = this.var_196[_local_1];
                _local_3.shift();
                _local_1++;
            }
            var _local_4:int = ((this.startTime + (this.var_506 * this.var_534)) - new Date().time);
            if (_local_4 < 1) {
                _local_4 = 1;
            }
            this.var_496 = setTimeout(this.method_416, (_local_4 + this.var_534));
            this.var_506++;
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
            clearTimeout(this.var_496);
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
            this.var_196 = null;
            this.clearMoveInterval();
            this.miniMap = null;
            super.remove();
        }


    }
}//package background

