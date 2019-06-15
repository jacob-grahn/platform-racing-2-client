// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.class_75

package background
{
    import flash.display.Sprite;
    import page.GamePage;
    import levelEditor.LevelEditorMenu;
    import levelEditor.LevelEditor;
    import data.class_122;
    import flash.geom.ColorTransform;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import data.class_28;
    import flash.geom.Point;
    import flash.display.DisplayObjectContainer;
    import flash.display.DisplayObject;

    public class class_75 extends Sprite 
    {

        protected var course:GamePage;
        private var var_394:uint;
        private var bgColor:Number = 13092571;
        public var scale:Number = 1;
        public var var_15:Array = new Array();
        public var var_88:Array = new Array();
        protected var var_39:Number = 0;
        protected var var_104:int;
        protected var var_141:int;
        protected var var_118:int;
        protected var var_120:int;

        public function class_75(c:GamePage)
        {
            this.course = c;
            this.setScale(1);
        }

        public function setScale(_arg_1:Number)
        {
            this.scale = _arg_1;
            scaleX = scaleY = _arg_1;
            this.method_59();
        }

        public function setColor(_arg_1:Number)
        {
            this.bgColor = _arg_1;
            this.method_59();
        }

        public function setPos(_arg_1:Number, _arg_2:Number)
        {
            x = Math.round(_arg_1 * this.scale);
            y = Math.round(_arg_2 * this.scale);
        }

        public function focusNone()
        {
            this.method_22();
            alpha = 1;
        }

        public function focusOn()
        {
            alpha = 1;
            mouseEnabled = true;
            mouseChildren = true;
        }

        public function method_22()
        {
            alpha = 0.25;
            mouseEnabled = false;
            mouseChildren = false;
        }

        public function method_14(_arg_1:String)
        {
            var _local_2:LevelEditorMenu;
            this.var_15.push(_arg_1);
            this.method_817();
            if (LevelEditor.editor != null) {
                _local_2 = LevelEditor.editor.menu;
                _local_2.m.undoButton.enabled = true;
                _local_2.m.redoButton.enabled = false;
            }
        }

        protected function method_817()
        {
            this.var_88 = new Array();
        }

        protected function method_59()
        {
            var _local_1:Object = class_122.hex24torgb(this.bgColor);
            var _local_2:Number = ((1 - this.scale) * 0.4) + 0.1;
            var _local_3:ColorTransform = new ColorTransform(1 - _local_2, 1 - _local_2, 1 - _local_2, 1, _local_1.red * _local_2, _local_1.green * _local_2, _local_1.blue * _local_2, 0);
            transform.colorTransform = _local_3;
        }

        public function undo()
        {
            if (this.var_15.length > 0) {
                this.var_88.push(this.var_15.pop());
            }
            this.clear();
            this.draw();
        }

        public function redo()
        {
            if (this.var_88.length > 0) {
                this.var_15.push(this.var_88.pop());
            }
            this.clear();
            this.draw();
        }

        public function clear()
        {
            this.var_39 = 0;
            clearTimeout(this.var_394);
        }

        public function draw(_arg_1:Number=100)
        {
            if (this.var_39 < this.var_15.length){
                this.var_394 = setTimeout(this.draw, 10, _arg_1);
            } else {
                this.course.finishDrawing(this);
            };
        }

        public function getSaveString():String
        {
            return this.var_15.join(",");
        }

        public function setSaveString(_arg_1:String, fromLE:Boolean = true)
        {
            if (_arg_1 != "" && _arg_1 != "," && _arg_1 != null) {
                this.var_15 = _arg_1.split(",");
            } else {
                this.var_15 = new Array();
            }
            this.clear();
            this.draw();
        }

        public function remove()
        {
            this.course = null;
            clearTimeout(this.var_394);
            this.var_15 = new Array();
            this.var_88 = new Array();
            parent.removeChild(this);
        }

        protected function method_118(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:int, _arg_6:int, _arg_7:DisplayObjectContainer, _arg_8:Array)
        {
            var _local_16:int;
            var _local_9:Point = class_28.method_9(_arg_3, _arg_5, rotation);
            var _local_10:Point = class_28.method_9(_arg_4, _arg_6, rotation);
            _arg_3 = Math.abs(_local_9.x);
            _arg_4 = Math.abs(_local_10.x);
            _arg_5 = Math.abs(_local_9.y);
            _arg_6 = Math.abs(_local_10.y);
            var _local_11:Number = (1 / scaleX) * (1 / this.course.scale);
            _arg_3 = Math.ceil((_arg_3 * _local_11));
            _arg_4 = Math.ceil((_arg_4 * _local_11));
            _arg_5 = Math.ceil((_arg_5 * _local_11));
            _arg_6 = Math.ceil((_arg_6 * _local_11));
            var _local_12:int = (_arg_1 - _arg_3);
            var _local_13:int = (_arg_1 + _arg_4);
            var _local_14:int = (_arg_2 - _arg_5);
            var _local_15:int = (_arg_2 + _arg_6);
            if (((((Math.abs((_local_12 - this.var_104)) > 5) || (Math.abs((_local_13 - this.var_141)) > 5)) || (Math.abs((_local_14 - this.var_118)) > 5)) || (Math.abs((_local_15 - this.var_120)) > 5))) {
                _local_16 = 0;
                while ((this.var_104 + _local_16) <= this.var_141) {
                    this.method_64((this.var_104 + _local_16), this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                    _local_16++;
                }
                _local_16 = 0;
                while ((_local_12 + _local_16) <= _local_13) {
                    this.method_64((_local_12 + _local_16), _local_14, _local_15, _arg_7, _arg_8, "add");
                    _local_16++;
                }
            } else {
                _local_16 = 0;
                while ((this.var_104 + _local_16) != _local_12) {
                    if (this.var_104 < _local_12) {
                        this.method_64((this.var_104 + _local_16), this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                        _local_16++;
                    } else {
                        _local_16--;
                        this.method_64((this.var_104 + _local_16), _local_14, _local_15, _arg_7, _arg_8, "add");
                    }
                }
                _local_16 = 0;
                while ((this.var_141 + _local_16) != _local_13) {
                    if (this.var_141 < _local_13) {
                        this.method_64((this.var_141 + ++_local_16), _local_14, _local_15, _arg_7, _arg_8, "add");
                    } else {
                        this.method_64((this.var_141 + _local_16), this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                        _local_16--;
                    }
                }
                _local_16 = 0;
                while ((this.var_118 + _local_16) != _local_14) {
                    if (this.var_118 < _local_14) {
                        this.method_94((this.var_118 + _local_16), this.var_104, this.var_141, _arg_7, _arg_8, "remove");
                        _local_16++;
                    } else {
                        _local_16--;
                        this.method_94((this.var_118 + _local_16), _local_12, _local_13, _arg_7, _arg_8, "add");
                    }
                }
                _local_16 = 0;
                while ((this.var_120 + _local_16) != _local_15) {
                    if (this.var_120 < _local_15) {
                        this.method_94((this.var_120 + ++_local_16), _local_12, _local_13, _arg_7, _arg_8, "add");
                    } else {
                        this.method_94((this.var_120 + _local_16), this.var_104, this.var_141, _arg_7, _arg_8, "remove");
                        _local_16--;
                    }
                }
            }
            this.var_104 = _local_12;
            this.var_141 = _local_13;
            this.var_118 = _local_14;
            this.var_120 = _local_15;
        }

        protected function method_94(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:DisplayObjectContainer, _arg_5:Array, _arg_6:String)
        {
            var _local_7:int;
            _local_7 = _arg_2;
            while (_local_7 <= _arg_3) {
                this.method_447(_local_7, _arg_1, _arg_4, _arg_6, _arg_5);
                _local_7++;
            }
        }

        protected function method_64(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:DisplayObjectContainer, _arg_5:Array, _arg_6:String)
        {
            var _local_7:int;
            _local_7 = _arg_2;
            while (_local_7 <= _arg_3) {
                this.method_447(_arg_1, _local_7, _arg_4, _arg_6, _arg_5);
                _local_7++;
            }
        }

        protected function method_447(_arg_1:int, _arg_2:int, _arg_3:DisplayObjectContainer, _arg_4:String, _arg_5:Array=null)
        {
            var _local_6:DisplayObject;
            if (((!(_arg_5[_arg_1] == null)) && (!(_arg_5[_arg_1][_arg_2] == null)))) {
                _local_6 = _arg_5[_arg_1][_arg_2];
                if (_arg_4 == "add") {
                    _arg_3.addChild(_local_6);
                } else {
                    if (_local_6.parent == _arg_3) {
                        _arg_3.removeChild(_local_6);
                    }
                }
            }
        }

        public function method_32(_arg_1:int, _arg_2:int):Boolean
        {
            if (((((_arg_1 >= this.var_104) && (_arg_1 <= this.var_141)) && (_arg_2 >= this.var_118)) && (_arg_2 <= this.var_120))) {
                return (true);
            }
            return (false);
        }


    }
}//package background

