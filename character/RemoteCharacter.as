// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// character.RemoteCharacter = character.class_91

package character
{
    import com.jiggmin.data.CommandHandler;
    import background.Map;
    import gameplay.Course;
    import effects.Sting;
    import effects.Zap;
    import flash.events.Event;
    import flash.geom.Point;
    import com.jiggmin.data.Data;
    import flash.display.Sprite;
    import blocks.Block;
    import blocks.ArrowBlock;
    import blocks.VanishBlock;
    import blocks.WaterBlock;

    public class RemoteCharacter extends Character
    {

        private var updateQueue:Array = new Array();
        private var commandHandler:CommandHandler = CommandHandler.commandHandler;
        private var mapDot:MiniMapDot; // var_174
        private var map:Map = Course.course.blockBackground;
        private var catchupRate:Number = 1;
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var lastX:Number = 0;
        private var lastY:Number = 0;
        private var rot:int = 0;
        private var rotMod:int = 0;
        private var halfWidth:Number = 10;
        private var charHeight:Number = 55;

        public function RemoteCharacter(tId:int, dot:MiniMapDot, userName:String, hatId:int, headId:int, bodyId:int, feetId:int, groupStr:String = '0')
        {
            super(hatId, headId, bodyId, feetId);
            this.tempID = tId;
            this.mapDot = dot;
            this.mapDot.setTempID(this.tempID);
            super.groupStr = groupStr;
            this.catchupRate = updateInterval + 1;
            super.userName = m.nameHolder.nameBox.text = m.nameHolder.nameBox2.text = userName;
            setNameColor(this.mapDot.getColor(this.tempID));
            this.commandHandler.defineCommand("p" + this.tempID.toString(), this.pos);
            this.commandHandler.defineCommand("var" + this.tempID.toString(), this.setVar);
            this.commandHandler.defineCommand("exactPos" + this.tempID.toString(), this.setExactPos);
            this.commandHandler.defineCommand("setHats" + this.tempID.toString(), setHats);
            this.commandHandler.defineCommand("heart" + this.tempID, this.onHeart);
            this.commandHandler.defineCommand("sting" + this.tempID, this.sting);
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        // _loc2 = varToSet
        private function go(_arg_1:Event)
        {
            if (this.updateQueue.length > 0) {
                this.catchupRate -= 0.01;
                var _local_4:int = 0;
                while (_local_4 < this.updateQueue.length) {
                    var _local_3:Object = this.updateQueue[_local_4];
                    if (_local_3.pos != null) {
                        var _local_6:Point = _local_3.pos;
                        var _local_7:Number = _local_6.x / (_local_4 + 1);
                        var _local_8:Number = _local_6.y / (_local_4 + 1);
                        this.posX += _local_7;
                        this.posY += _local_8;
                        _local_6.x -= _local_7;
                        _local_6.y -= _local_8;
                        break;
                    }
                    _local_4++;
                }
                var _local_5:Point = Data.rotatePoint(this.posX, this.posY, -(this.map.rotation + this.rot));
                velX = (this.lastX - x);
                velY = (this.lastY - y);
                this.lastX = x;
                this.lastY = y;
                x = _local_5.x;
                y = _local_5.y;
                _local_5 = Data.rotatePoint(this.posX, this.posY, -(this.rot));
                this.mapDot.x = _local_5.x;
                this.mapDot.y = _local_5.y;
                updateSegs(this.map.rotation);
                rotation = this.map.rotation + this.rot + this.rotMod;
                var varToSet:Object = this.updateQueue.shift();
                if (varToSet.state != null) {
                    changeState(varToSet.state);
                }
                if (varToSet.scaleX != null) {
                    this.setScaleX(int(varToSet.scaleX));
                }
                if (varToSet.parent != null) {
                    if (Course.course[varToSet.parent] != null) {
                        Sprite(Course.course[varToSet.parent]).addChild(this);
                    }
                }
                if (varToSet.x != null) {
                    this.posX = varToSet.x;
                    this.posY = varToSet.y;
                }
                if (varToSet.rotMod != null) {
                    this.rotMod = int(varToSet.rotMod);
                }
                if (varToSet.rot != null) {
                    this.rot = varToSet.rot;
                }
                if (varToSet.item != null) {
                    setItem(varToSet.item);
                }
                if (varToSet.sparkle != null) {
                    (varToSet.sparkle == '1' ? beginSparkles() : endSparkles());
                    /*if (varToSet.sparkle == "1") {
                        beginSparkles();
                    } else {
                        endSparkles();
                    }*/
                }
                if (varToSet.jet != null) {
                    (varToSet.jet == '1' ? beginJet() : endJet());
                    /*if (varToSet.jet == "1") {
                        beginJet();
                    } else {
                        endJet();
                    }*/
                }
                if (varToSet.beginRemove != null) {
                    beginRemove();
                }
                if (this.updateQueue.length > this.catchupRate) {
                    this.go(new Event(Event.ENTER_FRAME));
                }
            } else {
                this.catchupRate += 0.08;
            }
            if (this.catchupRate > 10) {
                this.catchupRate = 10;
            }
            this.processBlockTouches();
        }

        public function setScaleX(_arg_1:Number)
        {
            scaleX = m.nameHolder.scaleX = _arg_1;
        }

        public function setScaleY(_arg_1:Number)
        {
        }

        public function pos(_arg_1:Array)
        {
            var _local_2:Point = _arg_1[0] == "" ? new Point(0, 0) : new Point(_arg_1[0], _arg_1[1]);
            var _local_3:int = 1;
            while (_local_3 < updateInterval) {
                this.updateQueue.push(new Object());
                _local_3++;
            }
            var _local_4:Object = new Object();
            _local_4.pos = _local_2;
            this.updateQueue.push(_local_4);
        }

        public function setVar(_arg_1:Array)
        {
            var _local_4:Object;
            var _local_2:String = _arg_1[0];
            var _local_3:String = _arg_1[1];
            if (this.updateQueue.length > 0) {
                if (this.updateQueue[this.updateQueue.length - 1][_local_2] != null) {
                    if (this.updateQueue.length >= 2) {
                        this.updateQueue[this.updateQueue.length - 2][_local_2] = this.updateQueue[this.updateQueue.length - 1][_local_2];
                    }
                }
                this.updateQueue[this.updateQueue.length - 1][_local_2] = _local_3;
            } else {
                _local_4 = new Object();
                _local_4[_local_2] = _local_3;
                this.updateQueue.push(_local_4);
            }
        }

        public function setExactPos(_arg_1:Array)
        {
            var _local_2:int = int(_arg_1[0]);
            var _local_3:int = int(_arg_1[1]);
            if (this.updateQueue.length > 0) {
                this.updateQueue[this.updateQueue.length - 1].x = _local_2;
                this.updateQueue[this.updateQueue.length - 1].y = _local_3;
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            this.posX = _arg_1;
            this.posY = _arg_2;
            updateSegs(this.map.rotation);
        }

        private function sting(a:Array)
        {
            var from:Character = Course.course.playerArray[a[0]];
            if (from == null || from.tempID == this.tempID) {
                return;
            }
            var fromX:int = from.getPos().x;
            var fromDirection:String = fromX < x ? 'left' : (fromX > x ? 'right' : '');
            new Sting(this, fromDirection);
        }

        private function processBlockTouches()
        {
            //var _local_3:Block; // unused
            var _local_1:Number = this.posX - this.lastX;
            var _local_2:Number = this.posY - this.lastY;
            if (_local_2 <= 0) {
                this.touchBlockAt(x, y - this.charHeight - 1);
            }
            if (_local_2 >= 0) {
                this.touchBlockAt(x, y + 1);
            }
            if (_local_1 >= 0) {
                this.touchBlockAt(x + this.halfWidth + 1, y - 10);
            }
            if (_local_1 <= 0) {
                this.touchBlockAt(x - this.halfWidth - 1, y - 10);
            }
        }

        // removed _loc3, _loc4 (used as 1st and 2nd args in seg constructor)
        // _loc5 = seg
        // _loc6 = block
        private function touchBlockAt(posX:int, posY:int)
        {
            var seg:Point = Data.rotatePoint(posX / 30, posY / 30, this.map.rotation);
            if (this.map.isInView(seg.x, seg.y)) {
                var block:Block = Block(this.map.getBlockFromSeg(seg.x, seg.y));
                if (block is ArrowBlock) {
                    ArrowBlock(block).animateArrow();
                }
                if (block is VanishBlock) {
                    block.remoteActivate();
                }
                if (block is WaterBlock) {
                    WaterBlock(block).triggerRipple();
                }
            }
        }

        // unused
        /*private function isArrowBlock(_arg_1:*):Boolean
        {
            return (_arg_1 is ArrowBlock);
        }*/

        public function onHeart(_arg_1:Array)
        {
            gainHeart();
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            if (this.commandHandler != null) {
                this.commandHandler.defineCommand("p" + tempID.toString(), null);
                this.commandHandler.defineCommand("var" + tempID.toString(), null);
                this.commandHandler.defineCommand("exactPos" + tempID.toString(), null);
                this.commandHandler.defineCommand("setHats" + tempID.toString(), null);
                this.commandHandler.defineCommand("heart" + tempID, null);
                this.commandHandler.defineCommand("sting" + this.tempID, null);
            }
            if (this.mapDot != null) {
                if (this.mapDot.parent != null) {
                    this.mapDot.parent.removeChild(this.mapDot);
                }
                this.mapDot = null;
            }
            this.updateQueue = null;
            this.map = null;
            this.commandHandler = null;
            super.remove();
        }


    }
}//package character

