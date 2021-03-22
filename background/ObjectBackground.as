// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.ObjectBackground = background.class_77

package background
{
    import package_4.MessagePopup;
    import flash.display.Sprite;
    import page.GamePage;
    import levelEditor.LevelEditor;
    import levelEditor.DrawObject;
    import levelEditor.TextObject;

    public class ObjectBackground extends Background 
    {

        public var var_84:Sprite;
        public var objArray:Array = new Array(); // var_10
        private var objLimit:int = 50000; // var_356
        protected var var_0379:int = 0; // class_10
        protected var var_367:int = 1;

        public function ObjectBackground(gp:GamePage)
        {
            this.var_84 = this;
            super(gp);
        }

        public function addObject(objId:int, objX:int, objY:int)
        {
            if (this.objArray.length < this.objLimit) {
                this.attachObject(objId, objX, objY);
                this.recordAddObject(objId, objX, objY);
            } else {
                LevelEditor.editor.menu.reset();
                new MessagePopup("Error: Object limit reached.");
            }
        }

        protected function attachObject(objId:int, objX:int, objY:int)
        {
            var _local_4:DrawObject = new DrawObject(objId, objX, objY);
            this.var_84.addChild(_local_4);
            this.objArray.push(_local_4);
        }

        // method_129 = addText
        public function addText(str:String, textX:int, textY:int, textId:int, record:Boolean=false):TextObject
        {
            if (this.objArray.length < this.objLimit) {
                var _local_6:TextObject = new TextObject(str, textX, textY, textId);
                this.var_84.addChild(_local_6);
                this.objArray.push(_local_6);
                if (record) {
                    this.recordAddText(_local_6.getEscapedText(), textX, textY, textId);
                }
                return _local_6;
            }
            return null;
        }

        // method_821 = recordAddObject
        public function recordAddObject(objId:int, objX:int, objY:int)
        {
            recordAction("o" + objId + ";" + objX + ";" + objY);
        }

        // method_606 = recordAddText
        public function recordAddText(str:String, textX:int, textY:int, textId:int)
        {
            recordAction("u" + str + ";" + textX + ";" + textY + ";" + textId + ";100;100");
        }

        // _loc2 = textId
        public function recordChangeText(textObj:TextObject)
        {
            var textId:int = this.objArray.indexOf(textObj);
            recordAction("y" + textId + ";" + textObj.getEscapedText() + ";" + textObj.getColor());
        }

        // _loc2 = objId
        // method_761 = recordMove
        public function recordMove(obj:DrawObject)
        {
            var objId:int = this.objArray.indexOf(obj);
            recordAction("m" + objId + ";" + obj.x + ";" + obj.y);
        }

        // _loc2 = objId
        public function recordDelete(obj:DrawObject)
        {
            var objId:int = this.objArray.indexOf(obj);
            recordAction("d" + objId);
        }

        // _loc2 = objId
        // method_686 = recordResize
        public function recordResize(obj:DrawObject)
        {
            var objId:int = this.objArray.indexOf(obj);
            recordAction("r" + objId + ";" + obj.scaleX + ";" + obj.scaleY);
        }

        // _loc6 = drawStart
        // deleted _loc7 (saveArray.length)
        override public function draw(_arg_1:Number = 50)
        {
            course.startDrawing(this);
            if (course.goodToDraw(this)) {
                var _local_2:int = 0;
                var drawDateStart:Date = new Date();
                var drawStart:Number = drawDateStart.getTime();
                while (var_39 < saveArray.length) {
                    var _local_3:String = saveArray[var_39];
                    var _local_4:String = _local_3.substr(0, 1);
                    var _local_5:String = _local_3.substr(1);
                    if (_local_4 == "o") {
                        this.method_489(_local_5);
                    } else if (_local_4 == "m") {
                        this.moveDrawObject(_local_5);
                    } else if (_local_4 == "d") {
                        this.method_476(_local_5);
                    } else if (_local_4 == "r") {
                        this.method_393(_local_5);
                    } else if (_local_4 == "u") {
                        this.drawText(_local_5);
                    } else if (_local_4 == "y") {
                        this.method_763(_local_5);
                    }
                    var_39++;
                    _local_2++;
                    var drawDateEnd:Date = new Date();
                    var drawEnd:Number = drawDateEnd.getTime();
                    if (drawEnd - drawStart > 50) {
                        break;
                    }
                }
            }
            super.draw(_arg_1);
        }

        protected function drawText(_arg_1:String)
        {
            if (this.objArray.length < this.objLimit) {
                var _local_2:Array = _arg_1.split(";");
                var _local_3:String = String(_local_2[0]);
                var _local_4:int = int(_local_2[1]);
                var _local_5:int = int(_local_2[2]);
                var _local_6:int = int(_local_2[3]);
                var _local_7:Number = Number(_local_2[4]) / 100;
                var _local_8:Number = Number(_local_2[5]) / 100;
                var _local_9:TextObject = this.addText(_local_3, _local_4, _local_5, _local_6);
                _local_9.scaleX = _local_7;
                _local_9.scaleY = _local_8;
            }
        }

        // _loc2 = arr
        protected function method_489(s:String)
        {
            if (this.objArray.length < this.objLimit) {
                var arr:Array = s.split(";");
                var _local_3:int = int(arr[0]);
                var _local_4:Number = Number(arr[1]);
                var _local_5:Number = Number(arr[2]);
                this.attachObject(_local_3, _local_4, _local_5);
                if (arr[3] != null) {
                    this.method_393((this.objArray.length - 1) + ";" + arr[3] + ";" + arr[4]);
                }
            }
        }

        protected function moveDrawObject(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var _local_6:DrawObject = DrawObject(this.objArray[_local_3]);
            if (_local_6 != null) {
                _local_6.x = _local_4;
                _local_6.y = _local_5;
            }
        }

        protected function method_763(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:int = int(_local_2[0]);
            var _local_4:String = String(_local_2[1]);
            var _local_5:int = int(_local_2[2]);
            var _local_6:TextObject = TextObject(this.objArray[_local_3]);
            _local_6.showParsedText(_local_4);
            _local_6.setColor(_local_5);
        }

        protected function method_476(_arg_1:String)
        {
            var _local_2:Number = Number(_arg_1);
            var _local_3:DrawObject = DrawObject(this.objArray[_local_2]);
            _local_3.remove();
        }

        protected function method_393(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var _local_6:DrawObject = DrawObject(this.objArray[_local_3]);
            _local_6.scaleX = _local_4;
            _local_6.scaleY = _local_5;
        }

        // _loc1 = saveStr
        override public function getSaveString():String
        {
            var saveStr:String = "";
            var _local_4:int, _local_13:int, _local_14:int;
            if (this.objArray.length > 0) {
                var _local_2:String = "";
                var _local_5:Array = new Array();
                var _local_15:int = 0;
                while (_local_15 < this.objArray.length) {
                    var _local_6:DrawObject = this.objArray[_local_15];
                    if (_local_6 != null) {
                        var _local_7:int = int(_local_6.x / this.var_367);
                        var _local_8:int = int(_local_6.y / this.var_367);
                        var _local_11:int = _local_7 - _local_9;
                        var _local_12:int = _local_8 - _local_10;
                        var _local_9:int = _local_7;
                        var _local_10:int = _local_8;
                        _local_2 = _local_11 + ";" + _local_12;
                        var _local_3:int = _local_6.displayCode + this.var_0379;
                        if (_local_3 != _local_4) {
                            _local_4 = _local_3;
                            _local_2 = _local_2 + ";" + _local_3;
                        }
                        if (_local_6.scaleX != 1 || _local_6.scaleY != 1) {
                            _local_13 = _local_6.scaleX * 100;
                            _local_14 = _local_6.scaleY * 100;
                            _local_2 = _local_2 + ";" + _local_13 + ";" + _local_14;
                        }
                        if (_local_6 is TextObject) {
                            _local_13 = _local_6.scaleX * 100;
                            _local_14 = _local_6.scaleY * 100;
                            var _local_16:TextObject = TextObject(_local_6);
                            if (_local_16.getText() != "" && _local_16.getText() != " ") {
                                _local_2 = _local_11 + ";" + _local_12 + ";" + "t" + ";" + _local_16.getEscapedText() + ";" + _local_16.getColor() + ";" + _local_13 + ";" + _local_14;
                            } else {
                                _local_2 = "";
                            }
                        }
                        if (_local_2 != "") {
                            _local_5.push(_local_2);
                        }
                    }
                    _local_15++;
                }
                saveStr = _local_5.join(",");
            }
            return saveStr;
        }

        override public function setSaveString(_arg_1:String, fromLE:Boolean = true)
        {
            this.clear();
            if (_arg_1 != null) {
                saveArray = _arg_1.split(",");
                this.draw();
            }
        }

        // _loc3 = i
        // _loc5 = drawObj
        public function removeObjectsTouchingPoint(_arg_1:Number, _arg_2:Number)
        {
            var i:int = 0;
            var _local_4:int = this.objArray.length;
            while (i < _local_4) {
                var drawObj:DrawObject = this.objArray[i];
                if (drawObj != null && drawObj.deleteable && drawObj.hitTestPoint(_arg_1, _arg_2, true)) {
                    this.recordDelete(drawObj);
                    drawObj.remove();
                }
                i++;
            }
        }

        public function method_771(_arg_1:*)
        {
            var _local_2:int = this.objArray.indexOf(_arg_1);
            if (_local_2 != -1) {
                this.objArray.splice(_local_2, 1);
            }
        }

        // _loc4 = drawObj
        override public function clear()
        {
            var _local_1:Array = new Array();
            var _local_2:int = 0;
            var _local_3:int = this.objArray.length;
            while (_local_2 < _local_3) {
                _local_1[_local_2] = this.objArray[_local_2];
                _local_2++;
            }
            this.objArray = new Array();
            _local_2 = 0;
            while (_local_2 < _local_3) {
                var drawObj:DrawObject = _local_1[_local_2];
                drawObj.remove();
                _local_2++;
            }
            _local_1 = null;
            super.clear();
        }

        override public function remove()
        {
            this.clear();
            this.var_84 = null;
            super.remove();
        }


    }
}//package background