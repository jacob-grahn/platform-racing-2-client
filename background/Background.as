// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.class_75 = background.Background

package background
{
    import flash.display.Sprite;
    import page.GamePage;
    import levelEditor.LevelEditorMenu;
    import levelEditor.LevelEditor;
    import com.jiggmin.data.ColorUtil;
    import flash.geom.ColorTransform;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import com.jiggmin.data.Data;
    import flash.geom.Point;
    import flash.display.DisplayObjectContainer;
    import flash.display.DisplayObject;
    import dialogs.MessagePopup;
    import dialogs.Popup;
    import gameplay.Course;
    import gameplay.Game;
    import gameplay.PrizePopup;

    public class Background extends Sprite 
    {

        protected var course:GamePage;
        private var var_394:uint;
        private var bgColor:Number = 13092571;
        public var scale:Number = 1;
        public var saveArray:Array = new Array(); // var_15
        public var redoArray:Array = new Array(); // var_88
        protected var var_39:Number = 0;
        protected var var_104:int;
        protected var var_141:int;
        protected var var_118:int;
        protected var var_120:int;

        public function Background(c:GamePage)
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

        public function setColor(c:Number)
        {
            this.bgColor = c;
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

        // _loc2 = leMenu
        // method_14 = recordAction
        public function recordAction(action:String)
        {
            this.saveArray.push(action);
            this.redoArray = new Array();
            if (LevelEditor.editor != null) {
                var leMenu:LevelEditorMenu = LevelEditor.editor.menu;
                leMenu.m.undoButton.enabled = true;
                leMenu.m.redoButton.enabled = false;
            }
        }

        /*protected function method_817()
        {
            this.redoArray = new Array();
        }*/

        protected function method_59()
        {
            var _local_1:Object = ColorUtil.hex24ToRGB(this.bgColor);
            var _local_2:Number = ((1 - this.scale) * 0.4) + 0.1;
            var _local_3:ColorTransform = new ColorTransform(1 - _local_2, 1 - _local_2, 1 - _local_2, 1, _local_1.red * _local_2, _local_1.green * _local_2, _local_1.blue * _local_2, 0);
            transform.colorTransform = _local_3;
        }

        public function undo()
        {
            if (this.saveArray.length > 0) {
                this.redoArray.push(this.saveArray.pop());
            }
            this.clear();
            this.draw();
        }

        public function redo()
        {
            if (this.redoArray.length > 0) {
                this.saveArray.push(this.redoArray.pop());
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
            if (this.var_39 < this.saveArray.length) {
                if (this is DrawableBackground) {
                    var thisLayer:Background = this;
                    this.var_394 = setTimeout(function () {
                        try {
                            draw(_arg_1);
                        } catch (e:Error) {
                            var msg:String = 'Error: Some art didn\'t load correctly. ';
                            msg += Course.course is Game ? 'Don\'t worry! You can still play the level.' : 'This could be because there\'s too much art on your level. Saving the level now may cause permanent damage to its playability. Try undoing your recent changes until you don\'t get this error, and then saving your work.';
                            msg += "\n\nIf this persists, please contact a member of the PR2 staff team.";
                            var openPopups:Array = Popup.getOpen();
                            if (openPopups.length == 0 || (openPopups.length == 1 && openPopups[0] is PrizePopup)) {
                                new MessagePopup(msg);
                            };
                            course.finishDrawing(thisLayer);
                        }
                    }, 10);
                } else {
                    this.var_394 = setTimeout(this.draw, 10, _arg_1);
                }
            } else {
                this.course.finishDrawing(this);
            }
        }

        public function getSaveString():String
        {
            return this.saveArray.join(",");
        }

        public function setSaveString(s:String, fromLE:Boolean = true)
        {
            this.saveArray = s != "" && s != "," && s != null ? s.split(",") : new Array();
            this.clear();
            this.draw();
        }

        public function remove()
        {
            this.course = null;
            clearTimeout(this.var_394);
            this.saveArray = new Array();
            this.redoArray = new Array();
            parent.removeChild(this);
        }

        protected function method_118(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:int, _arg_6:int, _arg_7:DisplayObjectContainer, _arg_8:Array)
        {
            var _local_16:int;
            var _local_9:Point = Data.method_9(_arg_3, _arg_5, rotation);
            var _local_10:Point = Data.method_9(_arg_4, _arg_6, rotation);
            _arg_3 = Math.abs(_local_9.x);
            _arg_4 = Math.abs(_local_10.x);
            _arg_5 = Math.abs(_local_9.y);
            _arg_6 = Math.abs(_local_10.y);
            var _local_11:Number = (1 / scaleX) * (1 / this.course.scale);
            _arg_3 = Math.ceil(_arg_3 * _local_11);
            _arg_4 = Math.ceil(_arg_4 * _local_11);
            _arg_5 = Math.ceil(_arg_5 * _local_11);
            _arg_6 = Math.ceil(_arg_6 * _local_11);
            var _local_12:int = _arg_1 - _arg_3;
            var _local_13:int = _arg_1 + _arg_4;
            var _local_14:int = _arg_2 - _arg_5;
            var _local_15:int = _arg_2 + _arg_6;
            if (Math.abs(_local_12 - this.var_104) > 5 || Math.abs(_local_13 - this.var_141) > 5 || Math.abs(_local_14 - this.var_118) > 5 || Math.abs(_local_15 - this.var_120) > 5) {
                _local_16 = 0;
                while (this.var_104 + _local_16 <= this.var_141) {
                    this.method_64(this.var_104 + _local_16, this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                    _local_16++;
                }
                _local_16 = 0;
                while (_local_12 + _local_16 <= _local_13) {
                    this.method_64(_local_12 + _local_16, _local_14, _local_15, _arg_7, _arg_8, "add");
                    _local_16++;
                }
            } else {
                _local_16 = 0;
                while (this.var_104 + _local_16 != _local_12) {
                    if (this.var_104 < _local_12) {
                        this.method_64(this.var_104 + _local_16, this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                        _local_16++;
                    } else {
                        _local_16--;
                        this.method_64(this.var_104 + _local_16, _local_14, _local_15, _arg_7, _arg_8, "add");
                    }
                }
                _local_16 = 0;
                while (this.var_141 + _local_16 != _local_13) {
                    if (this.var_141 < _local_13) {
                        this.method_64(this.var_141 + ++_local_16, _local_14, _local_15, _arg_7, _arg_8, "add");
                    } else {
                        this.method_64(this.var_141 + _local_16, this.var_118, this.var_120, _arg_7, _arg_8, "remove");
                        _local_16--;
                    }
                }
                _local_16 = 0;
                while (this.var_118 + _local_16 != _local_14) {
                    if (this.var_118 < _local_14) {
                        this.method_94(this.var_118 + _local_16, this.var_104, this.var_141, _arg_7, _arg_8, "remove");
                        _local_16++;
                    } else {
                        _local_16--;
                        this.method_94(this.var_118 + _local_16, _local_12, _local_13, _arg_7, _arg_8, "add");
                    }
                }
                _local_16 = 0;
                while (this.var_120 + _local_16 != _local_15) {
                    if (this.var_120 < _local_15) {
                        this.method_94(this.var_120 + ++_local_16, _local_12, _local_13, _arg_7, _arg_8, "add");
                    } else {
                        this.method_94(this.var_120 + _local_16, this.var_104, this.var_141, _arg_7, _arg_8, "remove");
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
            for (var _local_7:int = _arg_2; _local_7 <= _arg_3; _local_7++) {
                this.method_447(_local_7, _arg_1, _arg_4, _arg_6, _arg_5);
            }
        }

        protected function method_64(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:DisplayObjectContainer, _arg_5:Array, _arg_6:String)
        {
            for (var _local_7:int = _arg_2; _local_7 <= _arg_3; _local_7++) {
                this.method_447(_arg_1, _local_7, _arg_4, _arg_6, _arg_5);
            }
        }

        protected function method_447(_arg_1:int, _arg_2:int, _arg_3:DisplayObjectContainer, _arg_4:String, _arg_5:Array=null)
        {
            if (_arg_5[_arg_1] != null && _arg_5[_arg_1][_arg_2] != null) {
                var _local_6:DisplayObject = _arg_5[_arg_1][_arg_2];
                if (_arg_4 == "add") {
                    _arg_3.addChild(_local_6);
                } else if (_local_6.parent == _arg_3) {
                    _arg_3.removeChild(_local_6);
                }
            }
        }

        public function method_32(_arg_1:int, _arg_2:int):Boolean
        {
            return _arg_1 >= this.var_104 && _arg_1 <= this.var_141 && _arg_2 >= this.var_118 && _arg_2 <= this.var_120;
        }


    }
}
