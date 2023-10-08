// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.DrawableBackground

package background
{
    import flash.display.Sprite;
    import page.GamePage;
    import flash.display.DisplayObject;
    import flash.geom.Rectangle;
    import flash.display.DisplayObjectContainer;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.display.BlendMode;
    import flash.geom.Point;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import levelEditor.TextObject;
    import levelEditor.LevelEditor;

    public class DrawableBackground extends Background 
    {

        private var var_210:Number = 200; // ART COMPRESSION ONCE PIXELIZATION THRESHOLD HIT?
        private var var_541:int = 750; //500 + ((1 + Settings.getValue(Settings.ART_QUALITY, 0)) * 250); // PIXELIZATION THRESHOLD?
        private var losslessQuality:Boolean = false;
        private var fromLE:Boolean;
        private var rasterCycles:Number = 1; // var_87
        private var bitmapArray:Array = new Array();
        public var var_33:Sprite = new Sprite();
        public var var_122:Sprite = new Sprite();
        public var objCanvas:Sprite = new Sprite(); // var_84
        private var brushSize:Number = 4; // var_136
        private var color:Number = 0;
        private var mode:String = "draw";
        private var var_302:Number;
        private var var_298:Number;
        public var drawing:Boolean = false;
        public var stoppedRasterizing:Boolean = false; // stop the rasterization process after 5 attempts to avoid crashing

        public function DrawableBackground(gp:GamePage)
        {
            super(gp);
            this.fromLE = LevelEditor.editor != null;
            this.losslessQuality = Settings.getValue(Settings.ART_LOSSLESS_QUALITY, false);
            this.var_122.cacheAsBitmap = true;
            addChild(this.var_122);
            addChild(this.var_33);
            addChild(this.objCanvas);
            this.var_33.graphics.lineStyle(this.brushSize, this.color);
        }

        public function method_86()
        {
            this.var_122.cacheAsBitmap = false;
            this.method_268(false);
        }

        public function method_74()
        {
            this.var_122.cacheAsBitmap = true;
            this.method_268(true);
        }

        // _loc2 = i
        // _loc3 = this.objCanvas.numChildren
        private function method_268(_arg_1:Boolean)
        {
            for (var i:int = 0; i < this.objCanvas.numChildren; i++) {
                var _local_4:DisplayObject = this.objCanvas.getChildAt(i);
                _local_4.cacheAsBitmap = _arg_1;
            }
        }

        override public function setSaveString(saveStr:String, fromLE:Boolean = true)
        {
            if (!Settings.getValue(Settings.DRAW_ART, true) && !fromLE) {
                saveStr = "";
            }
            super.setSaveString(saveStr);
        }

        override public function setScale(n:Number)
        {
            scale = n;
            method_59();
        }

        public function rasterize()
        {
            this.method_446(this.var_122, this.bitmapArray);
        }

        private function method_446(_arg_1:Sprite, _arg_2:Array)
        {
            this.method_607(_arg_1, _arg_2, this.var_33);
            this.var_33.graphics.clear();
            this.var_33.graphics.lineStyle(this.brushSize, this.color);
        }

        private function method_607(_arg_1:Sprite, _arg_2:Array, _arg_3:Sprite)
        {
            var _local_4:Rectangle = _arg_3.getBounds(this);
            var _local_5:int = this.var_210 * this.rasterCycles;
            var _local_6:Number = Math.floor(_local_4.x / _local_5) * _local_5;
            var _local_7:Number = Math.floor(_local_4.y / _local_5) * _local_5;
            var _local_8:Number = _local_4.x + _local_4.width;
            var _local_9:Number = _local_4.y + _local_4.height;
            var _local_10:Number = _local_6;
            var _local_11:Number = _local_7;
            while (_local_10 < _local_8) {
                _local_11 = _local_7;
                while (_local_11 < _local_9) {
                    this.method_208(_local_10, _local_11, _arg_1, _arg_2, _arg_3);
                    _local_11 += _local_5;
                }
                _local_10 += _local_5;
            }
            if (!this.losslessQuality && !this.fromLE && this.rasterCycles < 5 && Main.var_184 >= this.var_541) {
                this.rasterCycles++;
                this.clear();
                this.draw();
            } else if (this.rasterCycles >= 5) {
                this.stoppedRasterizing = true;
            }
        }

        private function method_208(_arg_1:Number, _arg_2:Number, _arg_3:Sprite, _arg_4:Array, _arg_5:Sprite)
        {
            var _local_6:Number = Math.floor(_arg_1 / (this.var_210 * this.rasterCycles));
            var _local_7:Number = Math.floor(_arg_2 / (this.var_210 * this.rasterCycles));
            var _local_8:Boolean = true;
            if (_arg_4[_local_6] == null) {
                _arg_4[_local_6] = new Array();
            } else if (_arg_4[_local_6][_local_7] != null) {
                _local_8 = false;
            }
            if (!_local_8 || Main.var_184 <= this.var_541 || this.losslessQuality || this.fromLE) {
                if (_local_8) {
                    Main.var_184++;
                    var _local_11:BitmapData = new BitmapData(this.var_210 + 1, this.var_210 + 1, true, 0);
                    var _local_12:Bitmap = new Bitmap(_local_11);
                    _local_12.scaleX = _local_12.scaleY = this.rasterCycles;
                    _arg_4[_local_6][_local_7] = _local_12;
                    if (_arg_3 != this.var_122 || method_32(_local_6, _local_7)) {
                        _arg_3.addChild(_local_12);
                    }
                    _local_12.x = _arg_1;
                    _local_12.y = _arg_2;
                }
                var _local_9:DisplayObjectContainer = _arg_5.parent;
                var _local_10:Sprite = new Sprite();
                _local_10.addChild(_arg_5);
                _arg_5.scaleX = _arg_5.scaleY = 1 / this.rasterCycles;
                _arg_5.x = -(_arg_1 * (1 / this.rasterCycles));
                _arg_5.y = -(_arg_2 * (1 / this.rasterCycles));
                Bitmap(_arg_4[_local_6][_local_7]).bitmapData.draw(_local_10);
                _arg_5.x = _arg_5.y = 0;
                _arg_5.scaleX = _arg_5.scaleY = 1;
                if (_local_9 != null) {
                    _local_9.addChild(_arg_5);
                }
            }
        }

        // _loc5 = _local_3.numChildren
        public function erase()
        {
            var _local_1:Sprite = new Sprite();
            var _local_2:Array = new Array();
            this.method_446(_local_1, _local_2);
            var _local_3:Sprite = new Sprite();
            this.method_553(_local_3, this.bitmapArray, _local_2);
            var _local_4:Sprite = new Sprite();
            _local_4.blendMode = BlendMode.LAYER;
            _local_1.blendMode = BlendMode.ERASE;
            _local_4.addChild(_local_3);
            _local_4.addChild(_local_1);
            for (var _local_7:int = 0; _local_7 < _local_3.numChildren; _local_7++) {
                var _local_6:Bitmap = Bitmap(_local_3.getChildAt(_local_7));
                this.method_208(_local_6.x, _local_6.y, this.var_122, this.bitmapArray, _local_4);
            }
            this.method_373(_local_1);
            this.method_373(_local_3);
            addChildAt(this.var_122, 0);
            addChildAt(this.var_33, 1);
        }

        private function method_553(_arg_1:Sprite, _arg_2:Array, _arg_3:Array)
        {
            for (var _local_4:int = 0; _local_4 < _arg_3.length; _local_4++) {
                if (_arg_3[_local_4] != null) {
                    for (var _local_5:int = 0; _local_5 < _arg_3[_local_4].length; _local_5++) {
                        if (_arg_3[_local_4][_local_5] != null && _arg_2[_local_4] != null && _arg_2[_local_4][_local_5] != null) {
                            _arg_1.addChild(_arg_2[_local_4][_local_5]);
                            _arg_2[_local_4][_local_5] = null;
                        }
                    }
                }
            }
        }

        // _loc2 = action
        // _loc3 = type
        // _loc4 = data
        // deleted _loc5, _loc6
        // _loc8 = actionsProcessed
        override public function draw(_arg_1:Number=50)
        {
            this.drawing = true;
            course.startDrawing(this);
            if (course.goodToDraw(this)) {
                var _local_7:Number = new Date().time;
                this.var_33.graphics.lineStyle(this.brushSize, this.color);
                for (var actionsProcessed:int = 0; var_39 < saveArray.length; ++actionsProcessed) {
                    var action:String = saveArray[var_39];
                    var type:String = action.substr(0, 1);
                    var data:String = action.substr(1);
                    if (type == "d") { // draw using brush
                        this.placeStroke(data);
                    } else if (type == "c") { // change brush color
                        this.color = Number("0x" + data);
                        this.var_33.graphics.lineStyle(this.brushSize, this.color);
                    } else if (type == "t") { // change brush size
                        this.brushSize = Number(data);
                        this.var_33.graphics.lineStyle(this.brushSize, this.color);
                    } else if (type == "m") { // change draw mode
                        this.mode = data;
                    } else if (type == "o") { // place an object
                        this.placeObject(data);
                    } else if (type == "u") {
                        this.drawText(data); // place a text object
                    }
                    if (this.mode == "erase") {
                        this.erase();
                    }
                    if (this.mode == "draw") {
                        this.rasterize();
                    }
                    var_39++;
                    var _local_9:Number = new Date().time - _local_7;
                    if ((_local_9 > 50 && actionsProcessed > 20) || _local_9 > 250) {
                        break;
                    }
                }
            }
            if (var_39 >= saveArray.length) {
                this.drawing = false;
            }
            super.draw(_arg_1);
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            var _local_3:Point = Data.method_9(-course.posX, -course.posY, rotation);
            var _local_4:int = Math.floor((_local_3.x * scale) / (this.var_210 * this.rasterCycles));
            var _local_5:int = Math.floor((_local_3.y * scale) / (this.var_210 * this.rasterCycles));
            method_118(_local_4, _local_5, 2, 2, 1, 1, this.var_122, this.bitmapArray);
        }

        // _loc2 = arr
        // _loc3 = code
        // method_489 = placeObject
        protected function placeObject(s:String)
        {
            var arr:Array = s.split(";");
            var scaleModX:Number = arr[3];
            var scaleModY:Number = arr[4];
            var obj:DisplayObject = Objects.getFromCode(Number(arr[0]));
            obj.scaleX = obj.scaleY = scale;
            obj.x = Number(arr[1]) * scale;
            obj.y = Number(arr[2]) * scale;
            if (!isNaN(scaleModX) && !isNaN(scaleModY)) {
                obj.scaleX = obj.scaleX * scaleModX;
                obj.scaleY = obj.scaleY * scaleModY;
            }
            obj.cacheAsBitmap = true;
            this.objCanvas.addChild(obj);
        }

        // _loc2 = arr
        // _loc3 = textStr
        // _loc4 = textX
        // _loc5 = textY
        // _loc6 = textCol
        // _loc7 = textScaleX
        // _loc8 = textScaleY
        // _loc9 = textBox
        protected function drawText(s:String)
        {
            var arr:Array = s.split(";");
            var textStr:String = String(arr[0]);
            var textX:int = int(arr[1]);
            var textY:int = int(arr[2]);
            var textColor:int = int(arr[3]);
            var textScaleX:Number = Number(arr[4]) / 100;
            var textScaleY:Number = Number(arr[5]) / 100;
            var textBox:TextField = new TextObjectGraphic().textBox;
            textBox.selectable = false;
            textBox.wordWrap = false;
            textBox.autoSize = TextFieldAutoSize.LEFT;
            textBox.multiline = true;
            textBox.textColor = textColor;
            textBox.text = TextObject.parseText(textStr);
            textBox.scaleX = textScaleX * scale;
            textBox.scaleY = textScaleY * scale;
            textBox.height = 24;
            textBox.x = textX * scale;
            textBox.y = textY * scale;
            textBox.cacheAsBitmap = true;
            this.objCanvas.addChild(textBox);
        }

        // _loc2 = data
        // _loc3 = i
        // method_795 = placeStroke
        private function placeStroke(s:String)
        {
            var data:Array = s.split(";");
            this.method_422(data[0], data[1]);
            for (var i:int = 2; i < data.length; i += 2) {
                this.drawLine(data[i], data[i + 1]);
            }
        }

        // deleted _loc5 (combined w/ return)
        /*private function method_838(_arg_1:String):Point
        {
            var _local_2:Number = _arg_1.indexOf(";");
            var _local_3:Number = _arg_1.substring(0, _local_2);
            var _local_4:Number = _arg_1.substr(_local_2 + 1);
            return new Point(_local_3, _local_4);
        }*/ // unused?

        // method_585 = recordColor
        public function recordColor(c:Number)
        {
            if (this.color != c) {
                this.color = c;
                this.var_33.graphics.lineStyle(this.brushSize, this.color);
                recordAction("c" + this.color.toString(16));
            }
        }

        // method_708 = setBrushSize
        public function setBrushSize(n:Number)
        {
            if (this.brushSize != n) {
                this.brushSize = n;
                this.var_33.graphics.lineStyle(n, this.color);
                recordAction("t" + n);
            }
        }

        public function setMode(m:String)
        {
            if (this.mode != m) {
                this.mode = m;
                recordAction("m" + m);
            }
        }

        public function moveTo(_arg_1:Number, _arg_2:Number)
        {
            recordAction("d" + _arg_1 + ";" + _arg_2);
            if (!this.drawing) {
                this.method_422(_arg_1, _arg_2);
            }
        }

        public function lineTo(_arg_1:Number, _arg_2:Number)
        {
            var _local_3:Number = _arg_1 - this.var_302;
            var _local_4:Number = _arg_2 - this.var_298;
            saveArray[saveArray.length - 1] = saveArray[saveArray.length - 1] + ";" + _local_3 + ";" + _local_4;
            if (!this.drawing) {
                this.drawLine(_local_3, _local_4);
            }
        }

        private function method_422(_arg_1:Number, _arg_2:Number)
        {
            this.var_33.graphics.moveTo(_arg_1, _arg_2);
            this.var_33.graphics.lineTo(_arg_1 - 0.5, _arg_2 - 0.5);
            this.var_33.graphics.moveTo(_arg_1, _arg_2);
            this.var_302 = _arg_1;
            this.var_298 = _arg_2;
        }

        // method_317 = drawLine
        private function drawLine(_arg_1:Number, _arg_2:Number)
        {
            this.var_302 += _arg_1;
            this.var_298 += _arg_2;
            this.var_33.graphics.lineTo(this.var_302, this.var_298);
        }

        // _loc1 = i
        // _loc2 = action
        // deleted _loc3 (action.charAt(0))
        override public function undo()
        {
            for (var i:int = saveArray.length - 2; i >= 0; i--) {
                var action:String = saveArray[i];
                if (action.charAt(0) == "d") break;
                redoArray.push(saveArray.pop());
            }
            super.undo();
        }

        // _loc1 = i
        // _loc2 = redoArray[i]
        // deleted _loc3 (action.charAt(0))
        override public function redo()
        {
            for (var i:Number = redoArray.length - 2; i >= 0; i--) {
                var action:String = redoArray[i];
                if (action.charAt(0) == "d") break;
                saveArray.push(redoArray.pop());
            }
            super.redo();
        }

        override public function clear()
        {
            this.method_812(this.bitmapArray);
            this.bitmapArray = new Array();
            this.var_33.graphics.clear();
            this.color = 0;
            this.brushSize = 4;
            this.mode = "draw";
            super.clear();
        }

        protected function method_373(_arg_1:Sprite)
        {
            while (_arg_1.numChildren != 0) {
                var _local_2:Bitmap = Bitmap(_arg_1.getChildAt(0));
                this.method_248(_local_2);
            }
        }

        private function method_812(_arg_1:Array)
        {
            for each (var _local_2:Array in _arg_1) {
                if (_local_2 != null) {
                    for each (var _local_3:DisplayObject in _local_2) {
                        var _local_4:Bitmap = Bitmap(_local_3);
                        this.method_248(_local_4);
                    }
                }
            }
        }

        private function method_248(_arg_1:Bitmap)
        {
            if (_arg_1 != null) {
                Main.var_184--;
                _arg_1.bitmapData.dispose();
                _arg_1.bitmapData = null;
                if (_arg_1.parent != null) {
                    _arg_1.parent.removeChild(_arg_1);
                }
                _arg_1 = null;
            }
        }

        override public function remove()
        {
            this.clear();
            super.remove();
        }


    }
}//package background

