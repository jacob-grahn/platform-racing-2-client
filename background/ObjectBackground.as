// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.ObjectBackground = background.class_77

package background
{
    import com.jiggmin.data.Objects;
    import flash.display.Sprite;
    import levelEditor.BlockObject;
    import levelEditor.DrawObject;
    import levelEditor.LevelEditor;
    import levelEditor.TextObject;
    import dialogs.MessagePopup;
    import page.GamePage;

    public class ObjectBackground extends Background 
    {

        public var objCanvas:Sprite; // var_84
        public var objArray:Array = new Array(); // var_10
        private var objLimit:int = 50000; // var_356
        protected var var_0379:int = 0; // class_10
        protected var segMult:int = 1; // var_367

        public function ObjectBackground(gp:GamePage)
        {
            this.objCanvas = this;
            super(gp);
        }

        public function addObject(objId:int, objX:int, objY:int, blockOpts:String = '')
        {
            if (this.objArray.length < this.objLimit) {
                this.attachObject(objId, objX, objY);
                this.recordAddObject(objId, objX, objY);
            } else {
                LevelEditor.editor.menu.reset();
                new MessagePopup("Error: Object limit reached.");
            }
        }

        protected function attachObject(objId:int, objX:int, objY:int, blockOpts:String = '')
        {
            var _local_4:DrawObject = new DrawObject(objId, objX, objY);
            this.objCanvas.addChild(_local_4);
            this.objArray.push(_local_4);
        }

        // method_129 = addText
        public function addText(str:String, textX:int, textY:int, textId:int, record:Boolean = false):TextObject
        {
            if (this.objArray.length < this.objLimit) {
                var _local_6:TextObject = new TextObject(str, textX, textY, textId);
                this.objCanvas.addChild(_local_6);
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
                        this.placeObject(_local_5);
                    } else if (_local_4 == "m") {
                        this.moveDrawObject(_local_5);
                    } else if (_local_4 == "d") {
                        this.deleteObject(_local_5);
                    } else if (_local_4 == "r") {
                        this.resizeObject(_local_5);
                    } else if (_local_4 == "u") {
                        this.drawText(_local_5);
                    } else if (_local_4 == "y") {
                        this.updateText(_local_5);
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

        // _loc2 = obj
        // deleted _loc3, _loc4, _loc5 (params in attachObject call)
        // method_489 = placeObject
        protected function placeObject(s:String)
        {
            if (this.objArray.length < this.objLimit) {
                var obj:Array = s.split(";");
                this.attachObject(int(obj[0]), Number(obj[1]), Number(obj[2]), this is BlockBackground && obj[3] != null ? obj[3] : '');
                if (obj[4] != null) {
                    this.resizeObject((this.objArray.length - 1) + ";" + obj[3] + ";" + obj[4]);
                }
            }
        }

        // _loc2 = objData
        // deleted _loc3, _loc4, _loc5 (combined with = calls)
        protected function moveDrawObject(s:String)
        {
            var objData:Array = s.split(";");
            var obj:DrawObject = DrawObject(this.objArray[Number(objData[0])]);
            if (obj != null) {
                obj.x = Number(objData[1]);
                obj.y = Number(objData[2]);
            }
        }

        // method_763 = updateText
        protected function updateText(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:int = int(_local_2[0]);
            var _local_4:String = String(_local_2[1]);
            var _local_5:int = int(_local_2[2]);
            var _local_6:TextObject = TextObject(this.objArray[_local_3]);
            _local_6.showParsedText(_local_4);
            _local_6.setColor(_local_5);
        }

        // _loc2 = int(i)
        // _loc3 = drawObj
        // method_476 = deleteObject
        protected function deleteObject(i:String)
        {
            var drawObj:DrawObject = DrawObject(this.objArray[int(i)]);
            if (
                drawObj.displayCode != Objects.BLOCK_START1
                && drawObj.displayCode != Objects.BLOCK_START2
                && drawObj.displayCode != Objects.BLOCK_START3
                && drawObj.displayCode != Objects.BLOCK_START4
            ) {
                drawObj.remove();
            }
        }

        // _loc6 = obj
        // method_393 = resizeObject
        protected function resizeObject(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var obj:DrawObject = DrawObject(this.objArray[_local_3]);
            obj.scaleX = _local_4;
            obj.scaleY = _local_5;
        }

        // _loc1 = saveStr
        // _loc2 = relCoord
        // _loc3 = currentObjCode
        // _loc4 = lastObjCode
        // _loc5 = objSaveArr
        // _loc6 = obj
        // _loc7 = currentX
        // _loc8 = currentY
        // _loc9 = lastX
        // _loc10 = lastY
        // _loc11 = relX
        // _loc12 = relY
        // _loc13 = widthPerc
        // _loc14 = heightPerc
        // _loc15 = i
        // _loc16 = textObj
        override public function getSaveString():String
        {
            var saveStr:String = "";
            var lastObjCode:int, widthPerc:int, heightPerc:int;
            if (this.objArray.length > 0) {
                var relCoord:String = ""; // x;y relative to last processed object
                var objSaveArr:Array = new Array();
                for (var i:int = 0; i < this.objArray.length; i++) {
                    var obj:DrawObject = this.objArray[i];
                    if (obj != null) {
                        var currentX:int = int(obj.x / this.segMult); // current X
                        var currentY:int = int(obj.y / this.segMult); // current Y
                        var relX:int = currentX - lastX; // "pointer" for objX (difference in x between new obj and old one)
                        var relY:int = currentY - lastY; // "pointer" for objY (difference in y between new obj and old one)
                        var lastX:int = currentX; // last X (for relative positioning in save string)
                        var lastY:int = currentY; // last Y (for relative positioning in save string)
                        var currentObjCode:int = obj.displayCode + this.var_0379;
                        relCoord = relX + ";" + relY;
                        if (obj is BlockObject && this is BlockBackground) {
                            var blockObj:BlockObject = BlockObject(obj);
                            var blockOpts:String = blockObj.getOptionsString();
                            if (currentObjCode != lastObjCode || blockOpts != '') {
                                lastObjCode = currentObjCode;
                                relCoord += ";" + currentObjCode;
                                if (blockOpts != null && blockOpts != '') {
                                    relCoord += ';' + blockOpts;
                                }
                            }
                        } else {
                            if (currentObjCode != lastObjCode) {
                                lastObjCode = currentObjCode;
                                relCoord += ";" + currentObjCode;
                            }
                            if (obj.scaleX != 1 || obj.scaleY != 1) {
                                widthPerc = obj.scaleX * 100;
                                heightPerc = obj.scaleY * 100;
                                relCoord += ";" + widthPerc + ";" + heightPerc;
                            }
                            if (obj is TextObject) {
                                widthPerc = obj.scaleX * 100;
                                heightPerc = obj.scaleY * 100;
                                var textObj:TextObject = TextObject(obj);
                                if (textObj.getText() != "" && textObj.getText() != " ") {
                                    relCoord = relX + ";" + relY + ";" + "t" + ";" + textObj.getEscapedText() + ";" + textObj.getColor() + ";" + widthPerc + ";" + heightPerc;
                                } else {
                                    relCoord = "";
                                }
                            }
                        }
                        if (relCoord != "") {
                            objSaveArr.push(relCoord);
                        }
                    }
                }
                saveStr = objSaveArr.join(",");
            }
            return saveStr;
        }

        override public function setSaveString(saveString:String, fromLE:Boolean = true)
        {
            this.clear();
            if (saveString != null) {
                saveArray = saveString.split(",");
                this.draw();
            }
        }

        // _loc3 = i
        // deleted _loc4 (this.objArray.length)
        // _loc5 = drawObj
        public function removeObjectsTouchingPoint(ptX:Number, ptY:Number)
        {
            for (var i:int = 0; i < this.objArray.length; i++) {
                var drawObj:DrawObject = this.objArray[i];
                if (drawObj != null && drawObj.deleteable && drawObj.hitTestPoint(ptX, ptY, true)) {
                    this.recordDelete(drawObj);
                    drawObj.remove();
                }
            }
        }

        public function method_771(_arg_1:*)
        {
            var _local_2:int = this.objArray.indexOf(_arg_1);
            if (_local_2 != -1) {
                this.objArray.splice(_local_2, 1);
            }
        }

        // refactored
        override public function clear()
        {
            for (var i:int = this.objArray.length - 1; i >= 0; i--) {
                var drawObj:DrawObject = this.objArray[i];
                drawObj.remove();
            }
            this.objArray = new Array();
            super.clear();
        }

        override public function remove()
        {
            this.clear();
            this.objCanvas = null;
            super.remove();
        }


    }
}
