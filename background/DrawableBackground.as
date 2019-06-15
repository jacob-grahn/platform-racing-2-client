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
    import data.class_28;
    import data.Objects;
    import data.Settings;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import levelEditor.TextObject;

    public class DrawableBackground extends class_75 
    {

        private var var_210:Number = 200;
        private var var_541:int = 750;
        private var var_87:Number = 1;
        private var bitmapArray:Array = new Array();
        public var var_33:Sprite = new Sprite();
        public var var_122:Sprite = new Sprite();
        public var var_84:Sprite = new Sprite();
        private var var_136:Number = 4;
        private var color:Number = 0;
        private var mode:String = "draw";
        private var var_302:Number;
        private var var_298:Number;
        public var drawing:Boolean = false;

        public function DrawableBackground(_arg_1:GamePage)
        {
            super(_arg_1);
            this.var_122.cacheAsBitmap = true;
            addChild(this.var_122);
            addChild(this.var_33);
            addChild(this.var_84);
            this.var_33.graphics.lineStyle(this.var_136, this.color);
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

        private function method_268(_arg_1:Boolean)
        {
            var _local_4:DisplayObject;
            var _local_2:int;
            var _local_3:int = this.var_84.numChildren;
            _local_2 = 0;
            while (_local_2 < _local_3) {
                _local_4 = this.var_84.getChildAt(_local_2);
                _local_4.cacheAsBitmap = _arg_1;
                _local_2++;
            }
        }

        override public function setSaveString(saveStr:String, fromLE:Boolean = true)
        {
            if (!Settings.getValue(Settings.DRAW_ART, true) && !fromLE) {
                saveStr = "";
            }
            super.setSaveString(saveStr);
        }

        override public function setScale(_arg_1:Number)
        {
            scale = _arg_1;
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
            this.var_33.graphics.lineStyle(this.var_136, this.color);
        }

        private function method_607(_arg_1:Sprite, _arg_2:Array, _arg_3:Sprite)
        {
            var _local_4:Rectangle = _arg_3.getBounds(this);
            var _local_5:int = (this.var_210 * this.var_87);
            var _local_6:Number = (Math.floor((_local_4.x / _local_5)) * _local_5);
            var _local_7:Number = (Math.floor((_local_4.y / _local_5)) * _local_5);
            var _local_8:Number = (_local_4.x + _local_4.width);
            var _local_9:Number = (_local_4.y + _local_4.height);
            var _local_10:Number = _local_6;
            var _local_11:Number = _local_7;
            while (_local_10 < _local_8) {
                _local_11 = _local_7;
                while (_local_11 < _local_9) {
                    this.method_208(_local_10, _local_11, _arg_1, _arg_2, _arg_3);
                    _local_11 = (_local_11 + _local_5);
                }
                _local_10 = (_local_10 + _local_5);
            }
            if (Main.var_184 >= this.var_541) {
                this.var_87++;
                this.clear();
                this.draw();
            }
        }

        private function method_208(_arg_1:Number, _arg_2:Number, _arg_3:Sprite, _arg_4:Array, _arg_5:Sprite)
        {
            var _local_6:Number;
            var _local_7:Number;
            var _local_9:DisplayObjectContainer;
            var _local_10:Sprite;
            var _local_11:BitmapData;
            var _local_12:Bitmap;
            _local_6 = Math.floor((_arg_1 / (this.var_210 * this.var_87)));
            _local_7 = Math.floor((_arg_2 / (this.var_210 * this.var_87)));
            var _local_8:Boolean = true;
            if (_arg_4[_local_6] == null) {
                _arg_4[_local_6] = new Array();
            } else {
                if (_arg_4[_local_6][_local_7] != null) {
                    _local_8 = false;
                }
            }
            if (((!(_local_8)) || (Main.var_184 <= this.var_541))) {
                if (_local_8) {
                    Main.var_184++;
                    _local_11 = new BitmapData((this.var_210 + 1), (this.var_210 + 1), true, 0);
                    _local_12 = new Bitmap(_local_11);
                    _local_12.scaleX = (_local_12.scaleY = this.var_87);
                    _arg_4[_local_6][_local_7] = _local_12;
                    if (((!(_arg_3 == this.var_122)) || (method_32(_local_6, _local_7)))) {
                        _arg_3.addChild(_local_12);
                    }
                    _local_12.x = _arg_1;
                    _local_12.y = _arg_2;
                }
                _local_9 = _arg_5.parent;
                _local_10 = new Sprite();
                _local_10.addChild(_arg_5);
                _arg_5.scaleX = (_arg_5.scaleY = (1 / this.var_87));
                _arg_5.x = -(_arg_1 * (1 / this.var_87));
                _arg_5.y = -(_arg_2 * (1 / this.var_87));
                Bitmap(_arg_4[_local_6][_local_7]).bitmapData.draw(_local_10);
                _arg_5.x = (_arg_5.y = 0);
                _arg_5.scaleX = (_arg_5.scaleY = 1);
                if (_local_9 != null) {
                    _local_9.addChild(_arg_5);
                }
            }
        }

        public function erase()
        {
            var _local_6:Bitmap;
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
            var _local_5:Number = _local_3.numChildren;
            var _local_7:int;
            while (_local_7 < _local_5) {
                _local_6 = Bitmap(_local_3.getChildAt(_local_7));
                this.method_208(_local_6.x, _local_6.y, this.var_122, this.bitmapArray, _local_4);
                _local_7++;
            }
            this.method_373(_local_1);
            this.method_373(_local_3);
            addChildAt(this.var_122, 0);
            addChildAt(this.var_33, 1);
        }

        private function method_553(_arg_1:Sprite, _arg_2:Array, _arg_3:Array)
        {
            var _local_5:Number;
            var _local_4:Number = 0;
            while (_local_4 < _arg_3.length) {
                if (_arg_3[_local_4] != null) {
                    _local_5 = 0;
                    while (_local_5 < _arg_3[_local_4].length) {
                        if (_arg_3[_local_4][_local_5] != null) {
                            if (_arg_2[_local_4] != null) {
                                if (_arg_2[_local_4][_local_5] != null) {
                                    _arg_1.addChild(_arg_2[_local_4][_local_5]);
                                    _arg_2[_local_4][_local_5] = null;
                                }
                            }
                        }
                        _local_5++;
                    }
                }
                _local_4++;
            }
        }

        override public function draw(_arg_1:Number=50)
        {
            var _local_2:String;
            var _local_3:String;
            var _local_4:String;
            var _local_5:Point;
            var _local_6:Number;
            var _local_7:Number;
            var _local_8:int;
            var _local_9:Number;
            this.drawing = true;
            course.startDrawing(this);
            if (course.goodToDraw(this)) {
                _local_6 = 0;
                _local_7 = new Date().time;
                this.var_33.graphics.lineStyle(this.var_136, this.color);
                while (var_39 < var_15.length) {
                    _local_8++;
                    _local_2 = var_15[var_39];
                    _local_3 = _local_2.substr(0, 1);
                    _local_4 = _local_2.substr(1);
                    if (_local_3 == "d") {
                        this.method_795(_local_4);
                    } else if (_local_3 == "c") {
                        this.color = Number("0x" + _local_4);
                        this.var_33.graphics.lineStyle(this.var_136, this.color);
                    } else if (_local_3 == "t") {
                        this.var_136 = Number(_local_4);
                        this.var_33.graphics.lineStyle(this.var_136, this.color);
                    } else if (_local_3 == "m") {
                        this.mode = _local_4;
                    } else if (_local_3 == "o") {
                        this.method_489(_local_4);
                    } else if (_local_3 == "u") {
                        this.drawText(_local_4);
                    }
                    if (this.mode == "erase") {
                        this.erase();
                    }
                    if (this.mode == "draw") {
                        this.rasterize();
                    }
                    var_39++;
                    _local_6++;
                    _local_9 = (new Date().time - _local_7);
                    if ((((_local_9 > 50) && (_local_8 > 20)) || (_local_9 > 250))) {
                        break;
                    }
                }
            }
            if (var_39 >= var_15.length) {
                this.drawing = false;
            }
            super.draw(_arg_1);
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            super.setPos(_arg_1, _arg_2);
            var _local_3:Point = class_28.method_9(-(course.posX), -(course.posY), rotation);
            var _local_4:int = int(Math.floor((_local_3.x * scale) / (this.var_210 * this.var_87)));
            var _local_5:int = int(Math.floor((_local_3.y * scale) / (this.var_210 * this.var_87)));
            method_118(_local_4, _local_5, 2, 2, 1, 1, this.var_122, this.bitmapArray);
        }

        protected function method_489(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:int = int(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var _local_6:Number = Number(_local_2[3]);
            var _local_7:Number = Number(_local_2[4]);
            var _local_8:DisplayObject = Objects.getFromCode(_local_3);
            _local_8.scaleX = _local_8.scaleY = scale;
            _local_8.x = _local_4 * scale;
            _local_8.y = _local_5 * scale;
            if (!isNaN(_local_6) && !isNaN(_local_7)) {
                _local_8.scaleX = _local_8.scaleX * _local_6;
                _local_8.scaleY = _local_8.scaleY * _local_7;
            }
            _local_8.cacheAsBitmap = true;
            this.var_84.addChild(_local_8);
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
            textBox.text = TextObject.method_192(textStr);
            textBox.scaleX = textScaleX * scale; //(textScaleX / 1.33) * scale;
            textBox.scaleY = textScaleY * scale; //(textScaleY / 1.27) * scale;
            textBox.height = 24;
            textBox.x = textX * scale;
            textBox.y = textY * scale;
            textBox.cacheAsBitmap = true;
            this.var_84.addChild(textBox);
        }

        private function method_795(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            this.method_422(_local_2[0], _local_2[1]);
            var _local_3:Number = 2;
            while (_local_3 < _local_2.length) {
                this.method_317(_local_2[_local_3], _local_2[(_local_3 + 1)]);
                _local_3 = (_local_3 + 2);
            }
        }

        private function method_838(_arg_1:String):Point
        {
            var _local_2:Number = _arg_1.indexOf(";");
            var _local_3:Number = Number(_arg_1.substring(0, _local_2));
            var _local_4:Number = Number(_arg_1.substr((_local_2 + 1)));
            var _local_5:Point = new Point(_local_3, _local_4);
            return (_local_5);
        }

        public function method_585(_arg_1:Number)
        {
            if (this.color != _arg_1) {
                this.color = _arg_1;
                this.var_33.graphics.lineStyle(this.var_136, _arg_1);
                method_14(("c" + _arg_1.toString(16)));
            }
        }

        public function method_708(_arg_1:Number)
        {
            if (this.var_136 != _arg_1) {
                this.var_136 = _arg_1;
                this.var_33.graphics.lineStyle(_arg_1, this.color);
                method_14(("t" + _arg_1));
            }
        }

        public function setMode(_arg_1:String)
        {
            if (this.mode != _arg_1) {
                this.mode = _arg_1;
                method_14(("m" + _arg_1));
            }
        }

        public function moveTo(_arg_1:Number, _arg_2:Number)
        {
            method_14(((("d" + _arg_1) + ";") + _arg_2));
            if (!this.drawing) {
                this.method_422(_arg_1, _arg_2);
            }
        }

        public function lineTo(_arg_1:Number, _arg_2:Number)
        {
            var _local_3:Number = (_arg_1 - this.var_302);
            var _local_4:Number = (_arg_2 - this.var_298);
            var_15[(var_15.length - 1)] = (var_15[(var_15.length - 1)] + (((";" + _local_3) + ";") + _local_4));
            if (!this.drawing) {
                this.method_317(_local_3, _local_4);
            }
        }

        private function method_422(_arg_1:Number, _arg_2:Number)
        {
            this.var_33.graphics.moveTo(_arg_1, _arg_2);
            this.var_33.graphics.lineTo((_arg_1 - 0.5), (_arg_2 - 0.5));
            this.var_33.graphics.moveTo(_arg_1, _arg_2);
            this.var_302 = _arg_1;
            this.var_298 = _arg_2;
        }

        private function method_317(_arg_1:Number, _arg_2:Number)
        {
            this.var_302 = (this.var_302 + _arg_1);
            this.var_298 = (this.var_298 + _arg_2);
            this.var_33.graphics.lineTo(this.var_302, this.var_298);
        }

        override public function undo()
        {
            var _local_2:String;
            var _local_3:String;
            var _local_1:Number = (var_15.length - 2);
            while (_local_1 >= 0) {
                _local_2 = var_15[_local_1];
                _local_3 = _local_2.charAt(0);
                if (_local_3 == "d") break;
                var_88.push(var_15.pop());
                _local_1--;
            }
            super.undo();
        }

        override public function redo()
        {
            var _local_2:String;
            var _local_3:String;
            var _local_1:Number = (var_88.length - 2);
            while (_local_1 >= 0) {
                _local_2 = var_88[_local_1];
                _local_3 = _local_2.charAt(0);
                if (_local_3 == "d") {
                    break;
                }
                var_15.push(var_88.pop());
                _local_1--;
            }
            super.redo();
        }

        override public function clear()
        {
            this.method_812(this.bitmapArray);
            this.bitmapArray = new Array();
            this.var_33.graphics.clear();
            this.color = 0;
            this.var_136 = 4;
            this.mode = "draw";
            super.clear();
        }

        protected function method_373(_arg_1:Sprite)
        {
            var _local_2:Bitmap;
            while (_arg_1.numChildren != 0) {
                _local_2 = Bitmap(_arg_1.getChildAt(0));
                this.method_248(_local_2);
            }
        }

        private function method_812(_arg_1:Array)
        {
            var _local_2:Array;
            var _local_3:DisplayObject;
            var _local_4:Bitmap;
            for each (_local_2 in _arg_1) {
                if (_local_2 != null) {
                    for each (_local_3 in _local_2) {
                        _local_4 = Bitmap(_local_3);
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

