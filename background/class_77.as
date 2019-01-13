// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.class_77

package background
{
    import flash.display.Sprite;
    import page.GamePage;
    import levelEditor.class_130;
    import levelEditor.class_131;

    public class class_77 extends class_75 
    {

        public var var_84:Sprite;
        public var var_10:Array = new Array();
        private var var_356:int = 20000;
        protected var var_0379:int = 0; // class_10
        protected var var_367:int = 1;

        public function class_77(_arg_1:GamePage)
        {
            this.var_84 = this;
            super(_arg_1);
        }

        public function addObject(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            if (this.var_10.length < this.var_356) {
                this.attachObject(_arg_1, _arg_2, _arg_3);
                this.method_821(_arg_1, _arg_2, _arg_3);
            }
        }

        protected function attachObject(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            var _local_4:class_130 = new class_130(_arg_1, _arg_2, _arg_3);
            this.var_84.addChild(_local_4);
            this.var_10.push(_local_4);
        }

        public function method_129(_arg_1:String, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:Boolean=false):class_131
        {
            var _local_6:class_131;
            if (this.var_10.length < this.var_356) {
                _local_6 = new class_131(_arg_1, _arg_2, _arg_3, _arg_4);
                this.var_84.addChild(_local_6);
                this.var_10.push(_local_6);
                if (_arg_5) {
                    this.method_606(_local_6.method_184(), _arg_2, _arg_3, _arg_4);
                }
                return (_local_6);
            }
            return (null);
        }

        public function method_821(_arg_1:int, _arg_2:int, _arg_3:int)
        {
            method_14(((((("o" + _arg_1) + ";") + _arg_2) + ";") + _arg_3));
        }

        public function method_606(_arg_1:String, _arg_2:int, _arg_3:int, _arg_4:int)
        {
            method_14((((((((("u" + _arg_1) + ";") + _arg_2) + ";") + _arg_3) + ";") + _arg_4) + ";100;100"));
        }

        public function recordChangeText(_arg_1:class_131)
        {
            var _local_2:int = this.var_10.indexOf(_arg_1);
            method_14(((((("y" + _local_2) + ";") + _arg_1.method_184()) + ";") + _arg_1.method_12()));
        }

        public function method_761(_arg_1:class_130)
        {
            var _local_2:int = this.var_10.indexOf(_arg_1);
            method_14(((((("m" + _local_2) + ";") + _arg_1.x) + ";") + _arg_1.y));
        }

        public function recordDelete(_arg_1:class_130)
        {
            var _local_2:int = this.var_10.indexOf(_arg_1);
            method_14(("d" + _local_2));
        }

        public function method_686(_arg_1:class_130)
        {
            var _local_2:int = this.var_10.indexOf(_arg_1);
            method_14(((((("r" + _local_2) + ";") + _arg_1.scaleX) + ";") + _arg_1.scaleY));
        }

        // _loc6 = drawStart
        override public function draw(_arg_1:Number=50)
        {
            var _local_2:int;
            var _local_3:String;
            var _local_4:String;
            var _local_5:String;
            var _local_7:int;
            course.startDrawing(this);
            if (course.goodToDraw(this)) {
                _local_2 = 0;
                var drawDateStart:Date = new Date();
                var drawStart:Number = drawDateStart.getTime();
                _local_7 = var_15.length;
                while (var_39 < _local_7) {
                    _local_3 = var_15[var_39];
                    _local_4 = _local_3.substr(0, 1);
                    _local_5 = _local_3.substr(1);
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
                    if ((drawEnd - drawStart) > 50) {
                        break;
                    }
                }
            }
            super.draw(_arg_1);
        }

        protected function drawText(_arg_1:String)
        {
            var _local_2:Array;
            var _local_3:String;
            var _local_4:int;
            var _local_5:int;
            var _local_6:int;
            var _local_7:Number;
            var _local_8:Number;
            var _local_9:class_131;
            if (this.var_10.length < this.var_356) {
                _local_2 = _arg_1.split(";");
                _local_3 = String(_local_2[0]);
                _local_4 = int(_local_2[1]);
                _local_5 = int(_local_2[2]);
                _local_6 = int(_local_2[3]);
                _local_7 = Number(_local_2[4]) / 100;
                _local_8 = Number(_local_2[5]) / 100;
                _local_9 = this.method_129(_local_3, _local_4, _local_5, _local_6);
                _local_9.scaleX = _local_7;
                _local_9.scaleY = _local_8;
            }
        }

        // _loc2 = arr
        protected function method_489(s:String)
        {
            var _local_3:int;
            var _local_4:Number;
            var _local_5:Number;
            if (this.var_10.length < this.var_356) {
                var arr:Array = s.split(";");
                _local_3 = int(arr[0]);
                _local_4 = Number(arr[1]);
                _local_5 = Number(arr[2]);
                this.attachObject(_local_3, _local_4, _local_5);
                if (arr[3] != null) {
                    this.method_393((this.var_10.length - 1) + ";" + arr[3] + ";" + arr[4]);
                }
            }
        }

        protected function moveDrawObject(_arg_1:String)
        {
            var _local_5:Number;
            var _local_6:class_130;
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            _local_5 = Number(_local_2[2]);
            _local_6 = class_130(this.var_10[_local_3]);
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
            var _local_6:class_131 = class_131(this.var_10[_local_3]);
            _local_6.method_262(_local_4);
            _local_6.setColor(_local_5);
        }

        protected function method_476(_arg_1:String)
        {
            var _local_2:Number = Number(_arg_1);
            var _local_3:class_130 = class_130(this.var_10[_local_2]);
            _local_3.remove();
        }

        protected function method_393(_arg_1:String)
        {
            var _local_2:Array = _arg_1.split(";");
            var _local_3:Number = Number(_local_2[0]);
            var _local_4:Number = Number(_local_2[1]);
            var _local_5:Number = Number(_local_2[2]);
            var _local_6:class_130 = class_130(this.var_10[_local_3]);
            _local_6.scaleX = _local_4;
            _local_6.scaleY = _local_5;
        }

        override public function getSaveString():String
        {
            var _local_2:String;
            var _local_3:int;
            var _local_4:int;
            var _local_5:Array;
            var _local_6:class_130;
            var _local_7:int;
            var _local_8:int;
            var _local_9:int;
            var _local_10:int;
            var _local_11:int;
            var _local_12:int;
            var _local_13:int;
            var _local_14:int;
            var _local_15:int;
            var _local_16:class_131;
            var _local_1:* = "";
            if (this.var_10.length > 0) {
                _local_2 = "";
                _local_5 = new Array();
                _local_15 = 0;
                while (_local_15 < this.var_10.length) {
                    _local_6 = this.var_10[_local_15];
                    if (_local_6 != null) {
                        _local_7 = int(_local_6.x / this.var_367);
                        _local_8 = int(_local_6.y / this.var_367);
                        _local_11 = _local_7 - _local_9;
                        _local_12 = _local_8 - _local_10;
                        _local_9 = _local_7;
                        _local_10 = _local_8;
                        _local_2 = _local_11 + ";" + _local_12;
                        _local_3 = _local_6.displayCode + this.var_0379;
                        if (_local_3 != _local_4) {
                            _local_4 = _local_3;
                            _local_2 = _local_2 + ";" + _local_3;
                        }
                        if (_local_6.scaleX != 1 || _local_6.scaleY != 1) {
                            _local_13 = _local_6.scaleX * 100;
                            _local_14 = _local_6.scaleY * 100;
                            _local_2 = _local_2 + ";" + _local_13 + ";" + _local_14;
                        }
                        if (_local_6 is class_131) {
                            _local_13 = _local_6.scaleX * 100;
                            _local_14 = _local_6.scaleY * 100;
                            _local_16 = class_131(_local_6);
                            if (_local_16.method_47() != "" && _local_16.method_47() != " ") {
                                _local_2 = (_local_11 + ";" + _local_12 + ";" + "t" + ";" + _local_16.method_184() + ";" + _local_16.method_12() + ";" + _local_13 + ";" + _local_14);
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
                _local_1 = _local_5.join(",");
            }
            return (_local_1);
        }

        override public function setSaveString(_arg_1:String, fromLE:Boolean = true)
        {
            this.clear();
            if (_arg_1 != null) {
                var_15 = _arg_1.split(",");
                this.draw();
            }
        }

        public function removeObjectsTouchingPoint(_arg_1:Number, _arg_2:Number)
        {
            var _local_5:class_130;
            var _local_3:int;
            var _local_4:int = this.var_10.length;
            _local_3 = 0;
            while (_local_3 < _local_4) {
                _local_5 = this.var_10[_local_3];
                if ((((!(_local_5 == null)) && (_local_5.deleteable)) && (_local_5.hitTestPoint(_arg_1, _arg_2, true)))) {
                    this.recordDelete(_local_5);
                    _local_5.remove();
                }
                _local_3++;
            }
        }

        public function method_771(_arg_1:*)
        {
            var _local_2:int = this.var_10.indexOf(_arg_1);
            if (_local_2 != -1) {
                this.var_10.splice(_local_2, 1);
            }
        }

        override public function clear()
        {
            var _local_4:class_130;
            var _local_1:Array = new Array();
            var _local_2:int;
            var _local_3:int = this.var_10.length;
            _local_2 = 0;
            while (_local_2 < _local_3) {
                _local_1[_local_2] = this.var_10[_local_2];
                _local_2++;
            }
            this.var_10 = new Array();
            _local_2 = 0;
            while (_local_2 < _local_3) {
                _local_4 = _local_1[_local_2];
                _local_4.remove();
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

