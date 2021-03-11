// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_8.RemotePlayer = package_8.class_91

package package_8
{
    import com.jiggmin.data.CommandHandler;
    import background.Map;
    import package_6.Course;
    import package_9.Sting;
    import package_9.Zap;
    import flash.events.Event;
    import flash.geom.Point;
    import com.jiggmin.data.Data;
    import flash.display.Sprite;
    import blocks.Block;
    import blocks.ArrowBlock;
    import blocks.VanishBlock;
    import blocks.WaterBlock;

    public class RemotePlayer extends Player
    {

        private var var_19:Array = new Array();
        private var commandHandler:CommandHandler = CommandHandler.commandHandler;
        private var mapDot:MiniMapDot; // var_174
        private var map:Map = Course.course.blockBackground;
        private var var_180:Number = 1;
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var lastX:Number = 0;
        private var lastY:Number = 0;
        private var rot:int = 0;
        private var rotMod:int = 0;
        private var var_189:Number = 10;
        private var var_325:Number = 55;

        public function RemotePlayer(tId:int, dot:MiniMapDot, _arg_3:String, hatId:int, headId:int, bodyId:int, feetId:int)
        {
            super(hatId, headId, bodyId, feetId);
            this.tempID = tId;
            this.mapDot = dot;
            this.var_180 = var_448 + 1;
            m.nameHolder.nameBox.text = m.nameHolder.nameBox2.text = _arg_3;
            this.commandHandler.defineCommand("p" + this.tempID.toString(), this.pos);
            this.commandHandler.defineCommand("var" + this.tempID.toString(), this.method_801);
            this.commandHandler.defineCommand("exactPos" + this.tempID.toString(), this.method_667);
            this.commandHandler.defineCommand("setHats" + this.tempID.toString(), setHats);
            this.commandHandler.defineCommand("heart" + this.tempID, this.method_662);
            this.commandHandler.defineCommand("sting" + this.tempID, this.sting);
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        private function go(_arg_1:Event)
        {
            var _local_2:Object;
            var _local_3:Object;
            var _local_4:int;
            var _local_5:Point;
            var _local_6:Point;
            var _local_7:Number;
            var _local_8:Number;
            if (this.var_19.length > 0) {
                this.var_180 = (this.var_180 - 0.01);
                _local_4 = 0;
                while (_local_4 < this.var_19.length) {
                    _local_3 = this.var_19[_local_4];
                    if (_local_3.pos != null) {
                        _local_6 = _local_3.pos;
                        _local_7 = (_local_6.x / (_local_4 + 1));
                        _local_8 = (_local_6.y / (_local_4 + 1));
                        this.posX = (this.posX + _local_7);
                        this.posY = (this.posY + _local_8);
                        _local_6.x = (_local_6.x - _local_7);
                        _local_6.y = (_local_6.y - _local_8);
                        break;
                    }
                    _local_4++;
                }
                _local_5 = Data.method_9(this.posX, this.posY, -(this.map.rotation + this.rot));
                velX = (this.lastX - x);
                velY = (this.lastY - y);
                this.lastX = x;
                this.lastY = y;
                x = _local_5.x;
                y = _local_5.y;
                _local_5 = Data.method_9(this.posX, this.posY, -(this.rot));
                this.mapDot.x = _local_5.x;
                this.mapDot.y = _local_5.y;
                method_58(this.map.rotation);
                rotation = this.map.rotation + this.rot + this.rotMod;
                _local_2 = this.var_19.shift();
                if (_local_2.state != null) {
                    changeState(_local_2.state);
                }
                if (_local_2.scaleX != null) {
                    this.setScaleX(int(_local_2.scaleX));
                }
                if (_local_2.parent != null) {
                    if (Course.course[_local_2.parent] != null) {
                        Sprite(Course.course[_local_2.parent]).addChild(this);
                    }
                }
                if (_local_2.x != null) {
                    this.posX = _local_2.x;
                    this.posY = _local_2.y;
                }
                if (_local_2.rotMod != null) {
                    this.rotMod = int(_local_2.rotMod);
                }
                if (_local_2.rot != null) {
                    this.rot = _local_2.rot;
                }
                if (_local_2.item != null) {
                    setItem(_local_2.item);
                }
                if (_local_2.sparkle != null) {
                    if (_local_2.sparkle == "1") {
                        beginSparkles();
                    } else {
                        endSparkles();
                    }
                }
                if (_local_2.jet != null) {
                    if (_local_2.jet == "1") {
                        beginJet();
                    } else {
                        endJet();
                    }
                }
                if (_local_2.beginRemove != null) {
                    beginRemove();
                }
                if (this.var_19.length > this.var_180) {
                    this.go(new Event(Event.ENTER_FRAME));
                }
            } else {
                this.var_180 = (this.var_180 + 0.08);
            }
            if (this.var_180 > 10) {
                this.var_180 = 10;
            }
            this.method_76();
        }

        public function setScaleX(_arg_1:Number)
        {
            scaleX = (m.nameHolder.scaleX = _arg_1);
        }

        public function setScaleY(_arg_1:Number)
        {
        }

        public function pos(_arg_1:Array)
        {
            var _local_2:Point;
            if (_arg_1[0] == "") {
                _local_2 = new Point(0, 0);
            } else {
                _local_2 = new Point(_arg_1[0], _arg_1[1]);
            }
            var _local_3:int = 1;
            while (_local_3 < var_448) {
                this.var_19.push(new Object());
                _local_3++;
            }
            var _local_4:Object = new Object();
            _local_4.pos = _local_2;
            this.var_19.push(_local_4);
        }

        public function method_801(_arg_1:Array)
        {
            var _local_4:Object;
            var _local_2:String = _arg_1[0];
            var _local_3:String = _arg_1[1];
            if (this.var_19.length > 0) {
                if (this.var_19[(this.var_19.length - 1)][_local_2] != null) {
                    if (this.var_19.length >= 2) {
                        this.var_19[(this.var_19.length - 2)][_local_2] = this.var_19[(this.var_19.length - 1)][_local_2];
                    }
                }
                this.var_19[(this.var_19.length - 1)][_local_2] = _local_3;
            } else {
                _local_4 = new Object();
                _local_4[_local_2] = _local_3;
                this.var_19.push(_local_4);
            }
        }

        public function method_667(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:int = int(_arg_1[1]);
            if (this.var_19.length > 0) {
                this.var_19[(this.var_19.length - 1)].x = _local_2;
                this.var_19[(this.var_19.length - 1)].y = _local_3;
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            this.posX = _arg_1;
            this.posY = _arg_2;
            method_58(this.map.rotation);
        }

        private function sting(a:Array)
        {
            var from:Player = Course.course.playerArray[a[0]];
            if (from == null || from.tempID == this.tempID) {
                return;
            }
            var fromX:int = from.getPos().x;
            var fromDirection:String = fromX < x ? 'left' : (fromX > x ? 'right' : '');
            new Sting(this, fromDirection);
        }

        private function method_76()
        {
            var _local_3:Block;
            var _local_1:Number = (this.posX - this.lastX);
            var _local_2:Number = (this.posY - this.lastY);
            if (_local_2 <= 0) {
                this.method_128(x, ((y - this.var_325) - 1));
            }
            if (_local_2 >= 0) {
                this.method_128(x, (y + 1));
            }
            if (_local_1 >= 0) {
                this.method_128(((x + this.var_189) + 1), (y - 10));
            }
            if (_local_1 <= 0) {
                this.method_128(((x - this.var_189) - 1), (y - 10));
            }
        }

        // _loc6 = block
        private function method_128(_arg_1:int, _arg_2:int)
        {
            var _local_3:int = int((_arg_1 / 30));
            var _local_4:int = int((_arg_2 / 30));
            var _local_5:Point = Data.method_9(_local_3, _local_4, this.map.rotation);
            if (this.map.method_32(_local_5.x, _local_5.y)) {
                var block:Block = Block(this.map.getBlockFromSeg(_local_5.x, _local_5.y));
                if (block is ArrowBlock) {
                    ArrowBlock(block).method_87();
                }
                if (block is VanishBlock) {
                    block.remoteActivate();
                }
                if (block is WaterBlock) {
                    WaterBlock(block).method_584();
                }
            }
        }

        // unused
        /*private function isArrowBlock(_arg_1:*):Boolean
        {
            return (_arg_1 is ArrowBlock);
        }*/

        public function method_662(_arg_1:Array)
        {
            gainHeart();
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            if (this.commandHandler != null) {
                this.commandHandler.defineCommand(("p" + tempID.toString()), null);
                this.commandHandler.defineCommand(("var" + tempID.toString()), null);
                this.commandHandler.defineCommand(("exactPos" + tempID.toString()), null);
                this.commandHandler.defineCommand(("setHats" + tempID.toString()), null);
                this.commandHandler.defineCommand(("heart" + tempID), null);
                this.commandHandler.defineCommand("sting" + this.tempID, null);
            }
            if (this.mapDot != null) {
                if (this.mapDot.parent != null) {
                    this.mapDot.parent.removeChild(this.mapDot);
                }
                this.mapDot = null;
            }
            this.var_19 = null;
            this.map = null;
            this.commandHandler = null;
            super.remove();
        }


    }
}//package package_8

