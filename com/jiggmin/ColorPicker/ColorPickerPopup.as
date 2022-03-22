// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.ColorPickerPopup = package_16.class_241

package com.jiggmin.ColorPicker
{
    import package_4.Popup;
    import flash.display.Sprite;
    import flash.display.BitmapData;
    import ui.CustomCursor;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.ColorUtil;
    import flash.display.DisplayObject;
    import flash.geom.ColorTransform;
    import flash.ui.Mouse;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.display.Bitmap;

    public class ColorPickerPopup extends Popup
    {

        private var var_89:CursorEyedropper;
        private var var_27:Sprite;
        private var var_145:Array;
        private var var_48:Sprite;
        private var var_144:Sprite;
        private var var_598:int;
        private var var_188:int = -1;
        private var color:int = -1;
        private var hue:Number = 0;
        private var saturation:Number = 0;
        private var brightness:Number = 50;
        private var var_69:Sprite;
        private var var_124:Sprite;
        private var var_121:Sprite;
        private var var_687:Sprite;
        private var var_326:BitmapData;
        private var var_146:ColorPickerHueArrowGraphic;
        private var var_100:ColorPickerCrosshairsGraphic;
        private var priorCursor:CustomCursor; // var_194
        private var priorCursorActive:Boolean;
        private var me:MouseEvent;
        private var m:ColorPickerPopupGraphic;

        public function ColorPickerPopup(_arg_1:int)
        {
            var _local_2:Sprite;
            var _local_3:Sprite;
            super(false);
            this.m = new ColorPickerPopupGraphic();
            addChild(this.m);
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOK, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.textBox.restrict = "0123456789abcdefABCDEF#x";
            this.m.textBox.addEventListener(Event.CHANGE, this.method_415, false, 0, true);
            this.var_69 = this.method_814(60, 60);
            this.var_69.x = 15;
            this.var_69.y = 150;
            addChild(this.var_69);
            this.method_532(this.var_69);
            this.var_124 = this.method_755(15, 60);
            this.var_124.x = this.var_69.x + this.var_69.width + 10;
            this.var_124.y = this.var_69.y;
            addChild(this.var_124);
            _local_2 = this.showHighlight(15, 60);
            _local_2.x = this.var_124.x;
            _local_2.y = this.var_124.y;
            addChild(_local_2);
            this.var_48 = this.method_256();
            this.var_48.visible = false;
            this.var_144 = this.method_256();
            this.var_144.visible = false;
            this.var_27 = new Sprite();
            this.var_27.x = 15;
            this.var_27.y = 15;
            this.var_27.mouseChildren = false;
            this.var_27.addChild(this.var_48);
            this.var_27.addChild(this.var_144);
            this.method_523();
            addChild(this.var_27);
            this.var_121 = new Sprite();
            this.var_121.graphics.beginFill(0);
            this.var_121.graphics.drawRect(0, 0, 120, 25);
            this.var_121.graphics.endFill();
            this.var_121.x = 115;
            this.var_121.y = 185;
            addChild(this.var_121);
            _local_3 = this.showHighlight(120, 25);
            _local_3.x = this.var_121.x;
            _local_3.y = this.var_121.y;
            addChild(_local_3);
            this.setColor(_arg_1);
            this.var_598 = _arg_1;
            this.method_569();
            this.var_124.addEventListener(MouseEvent.MOUSE_DOWN, this.method_399, false, 0, true);
            this.var_69.addEventListener(MouseEvent.MOUSE_DOWN, this.method_266, false, 0, true);
            this.var_27.addEventListener(MouseEvent.MOUSE_MOVE, this.method_334, false, 0, true);
            this.var_27.addEventListener(MouseEvent.MOUSE_DOWN, this.method_452, false, 0, true);
            this.var_27.addEventListener(MouseEvent.MOUSE_OUT, this.method_417, false, 0, true);
        }

        public function init()
        {
            this.var_89 = new CursorEyedropper();
            this.var_89.method_101(this);
            this.var_89.addEventListener(Event.CHANGE, this.method_212, false, 0, true);
            this.var_89.addEventListener(Event.COMPLETE, this.method_275, false, 0, true);
            if (CustomCursor.instance != null) {
                this.priorCursor = CustomCursor.instance;
                this.priorCursorActive = this.priorCursor.isActive();
                this.priorCursor.pause();
            }
            CustomCursor.change(this.var_89);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler, false, 0, true);
            if ((x + width) > Main.stage.stageWidth) {
                x = Main.stage.stageWidth - width;
            }
            if (x < 0) {
                x = 0;
            }
            if (y + height > Main.stage.stageHeight) {
                y = Main.stage.stageHeight - height;
            }
            if (y < 0) {
                y = 0;
            }
        }

        public function setColor(_arg_1:int)
        {
            var _local_2:Object;
            if (this.color != _arg_1) {
                this.color = _arg_1;
                _local_2 = ColorUtil.hex24ToHSB(_arg_1);
                this.hue = _local_2.hue;
                this.var_146.y = Math.round(60 - ((this.hue / 360) * 60));
                this.method_382(this.hue);
                this.saturation = _local_2.saturation;
                this.var_100.x = Math.round((this.saturation / 100) * 60);
                this.brightness = _local_2.brightness;
                this.var_100.y = Math.round(60 - ((this.brightness / 100) * 60));
                this.method_40();
            }
        }

        private function method_40(_arg_1:int=-1)
        {
            if (_arg_1 == -1) {
                _arg_1 = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            }
            if (stage.focus != this.m.textBox.textField) {
                this.m.textBox.text = "#" + ColorUtil.decimalToHex(_arg_1).substr(2);
            }
            this.method_765(this.var_121, _arg_1);
            dispatchEvent(new Event(Event.CHANGE));
        }

        // method_12 = getColor
        public function getColor():int
        {
            if (this.var_188 != -1) {
                return this.var_188;
            }
            return this.color;
        }

        public function method_101(_arg_1:DisplayObject)
        {
            this.var_89.method_101(_arg_1);
        }

        private function method_765(_arg_1:DisplayObject, _arg_2:int)
        {
            var _local_3:Object = ColorUtil.hex24ToRGB(_arg_2);
            _arg_1.transform.colorTransform = new ColorTransform(0, 0, 0, 1, _local_3.red, _local_3.green, _local_3.blue, 0);
        }

        private function method_569()
        {
            var _local_2:int;
            var _local_3:Array;
            var _local_4:int;
            var _local_7:int;
            var _local_1:int = this.var_145.length;
            var _local_5:int = 10;
            var _local_6:int;
            while (_local_6 < _local_1) {
                _local_3 = this.var_145[_local_6];
                _local_2 = _local_3.length;
                _local_7 = 0;
                while (_local_7 < _local_2) {
                    _local_4 = this.var_145[_local_6][_local_7];
                    if (_local_4 == this.color) {
                        this.var_48.visible = true;
                        this.var_48.x = _local_6 * _local_5;
                        this.var_48.y = _local_7 * _local_5;
                    }
                    _local_7++;
                }
                _local_6++;
            }
        }

        private function mouseUpHandler(_arg_1:MouseEvent)
        {
            Mouse.show();
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_116);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_114);
            removeEventListener(Event.ENTER_FRAME, this.method_155);
        }

        private function method_266(_arg_1:MouseEvent)
        {
            Mouse.hide();
            this.method_116(_arg_1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.method_116, false, 0, true);
        }

        private function method_399(_arg_1:MouseEvent)
        {
            Mouse.hide();
            this.method_114(_arg_1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.method_114, false, 0, true);
            addEventListener(Event.ENTER_FRAME, this.method_155, false, 0, true);
        }

        private function method_116(_arg_1:MouseEvent)
        {
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.var_69.globalToLocal(_local_2);
            var _local_3:int = _local_2.x;
            var _local_4:int = _local_2.y;
            _local_3 = Data.numLimit(_local_3, 0, 60);
            _local_4 = Data.numLimit(_local_4, 0, 60);
            this.var_100.x = Math.round(_local_3);
            this.var_100.y = Math.round(_local_4);
            this.saturation = 100 * (_local_3 / 60);
            this.brightness = 100 - (100 * (_local_4 / 60));
            this.color = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            this.method_40();
            this.var_48.visible = false;
        }

        private function method_114(_arg_1:MouseEvent)
        {
            var _local_3:int;
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.var_124.globalToLocal(_local_2);
            _local_3 = _local_2.y;
            _local_3 = Data.numLimit(_local_3, 0, 60);
            this.var_146.y = Math.round(_local_3);
            this.hue = 360 - (360 * (_local_3 / 60));
            this.color = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            this.method_40();
            this.var_48.visible = false;
        }

        private function method_155(_arg_1:Event)
        {
            this.method_382(this.hue);
        }

        private function method_212(_arg_1:Event)
        {
            this.var_188 = this.var_89.color;
            this.method_40(this.var_188);
        }

        private function method_275(_arg_1:Event)
        {
            this.var_188 = -1;
            this.setColor(this.var_89.color);
            this.method_40();
            method_136();
        }

        private function method_334(_arg_1:MouseEvent)
        {
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.var_27.globalToLocal(_local_2);
            var _local_3:int = int(Math.floor((_local_2.x / 10)));
            var _local_4:int = int(Math.floor((_local_2.y / 10)));
            _local_3 = Data.numLimit(_local_3, 0, 21);
            _local_4 = Data.numLimit(_local_4, 0, 11);
            this.var_144.x = _local_3 * 10;
            this.var_144.y = _local_4 * 10;
            this.var_144.visible = true;
            this.var_188 = this.var_145[_local_3][_local_4];
            this.method_40(this.var_188);
        }

        private function method_452(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            var _local_2:int = int((this.var_144.x / 10));
            var _local_3:int = int((this.var_144.y / 10));
            this.setColor(this.var_145[_local_2][_local_3]);
            this.var_48.x = _local_2 * 10;
            this.var_48.y = _local_3 * 10;
            this.var_48.visible = true;
            this.remove();
        }

        private function method_417(_arg_1:MouseEvent)
        {
            this.var_188 = -1;
            this.var_144.visible = false;
            this.method_40();
        }

        private function method_415(_arg_1:Event)
        {
            var _local_2:String;
            var _local_3:int;
            if (stage.focus == this.m.textBox.textField) {
                _local_2 = this.m.textBox.text;
                _local_3 = 0;
                if (_local_2 != "") {
                    _local_2 = _local_2.split("#").join("");
                    _local_2 = _local_2.split("0x").join("");
                    _local_3 = Number(("0x" + _local_2));
                    if (isNaN(_local_3)) {
                        _local_3 = 0;
                    }
                }
                this.setColor(_local_3);
            }
        }

        // method_363 = clickOK
        private function clickOK(e:MouseEvent)
        {
            this.remove();
        }

        // method_400 = clickCancel
        private function clickCancel(e:MouseEvent)
        {
            this.color = this.var_598;
            dispatchEvent(new Event(Event.CHANGE));
            this.remove();
        }

        private function method_523()
        {
            var _local_2:int;
            var _local_3:Array;
            var _local_5:int;
            var _local_7:int;
            this.var_27.graphics.clear();
            this.var_27.graphics.lineStyle(1, 0, 1, true);
            this.var_145 = class_280.method_605();
            var _local_1:int = this.var_145.length;
            var _local_4:int = 10;
            var _local_6:int;
            while (_local_6 < _local_1) {
                _local_3 = this.var_145[_local_6];
                _local_2 = _local_3.length;
                _local_7 = 0;
                while (_local_7 < _local_2) {
                    _local_5 = this.var_145[_local_6][_local_7];
                    if (_local_5 == this.color) {
                        this.var_48.visible = true;
                        this.var_48.x = _local_6 * _local_4;
                        this.var_48.y = _local_7 * _local_4;
                    }
                    this.var_27.graphics.beginFill(_local_5);
                    this.var_27.graphics.drawRect((_local_6 * _local_4), (_local_7 * _local_4), _local_4, _local_4);
                    this.var_27.graphics.endFill();
                    _local_7++;
                }
                _local_6++;
            }
        }

        private function method_256():Sprite
        {
            var _local_1:Sprite = new Sprite();
            _local_1.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            _local_1.graphics.drawRect(0, 0, 10, 10);
            return _local_1;
        }

        private function method_755(_arg_1:int, _arg_2:int):Sprite
        {
            var _local_4:int;
            var _local_5:Number;
            var _local_3:BitmapData = new BitmapData(_arg_1, _arg_2, false, 0xFFFFFF);
            var _local_6:int;
            while (_local_6 < _arg_2) {
                _local_4 = int((360 - (360 * (_local_6 / _arg_2))));
                _local_5 = ColorUtil.hsbToHex24(_local_4, 100, 100);
                _local_3.fillRect(new Rectangle(0, _local_6, _arg_1, 1), _local_5);
                _local_6++;
            }
            this.var_146 = new ColorPickerHueArrowGraphic();
            this.var_146.x = _arg_1 + 1;
            this.var_146.y = _arg_2;
            this.var_146.mouseEnabled = this.var_146.mouseChildren = false;
            var _local_7:Sprite = new Sprite();
            _local_7.graphics.beginFill(0, 0);
            _local_7.graphics.drawRect(0, 0, (_arg_1 + 10), _arg_2);
            _local_7.graphics.endFill();
            var _local_8:Sprite = new Sprite();
            _local_8.addChild(new Bitmap(_local_3));
            _local_8.addChild(this.var_146);
            _local_8.addChild(_local_7);
            return _local_8;
        }

        private function method_814(_arg_1:int, _arg_2:int):Sprite
        {
            this.var_326 = new BitmapData(_arg_1, _arg_2, false, 0);
            var _local_3:Bitmap = new Bitmap(this.var_326);
            this.var_100 = new ColorPickerCrosshairsGraphic();
            this.var_100.mouseEnabled = this.var_100.mouseChildren = false;
            this.var_100.x = this.var_100.y = 20;
            var _local_4:Sprite = new Sprite();
            _local_4.addChild(_local_3);
            _local_4.addChild(this.var_100);
            return _local_4;
        }

        private function method_382(_arg_1:Number)
        {
            var _local_5:Number;
            var _local_6:Number;
            var _local_7:Number;
            var _local_8:Object;
            var _local_10:int;
            var _local_2:BitmapData = this.var_326;
            var _local_3:int = _local_2.width;
            var _local_4:int = _local_2.height;
            var _local_9:int;
            while (_local_9 < _local_3) {
                _local_6 = (_local_9 / _local_3) * 100;
                _local_10 = 0;
                while (_local_10 < _local_4) {
                    _local_7 = 100 - ((_local_10 / _local_4) * 100);
                    _local_5 = ColorUtil.hsbToHex24(_arg_1, _local_6, _local_7);
                    _local_2.setPixel(_local_9, _local_10, _local_5);
                    _local_10++;
                }
                _local_9++;
            }
        }

        private function method_532(_arg_1:DisplayObject):Sprite
        {
            var _local_2:Sprite = this.showHighlight(Math.round(_arg_1.width), Math.round(_arg_1.height));
            _local_2.x = _arg_1.x;
            _local_2.y = _arg_1.y;
            addChild(_local_2);
            return _local_2;
        }

        private function showHighlight(_arg_1:int, _arg_2:int):Sprite
        {
            var _local_3:Sprite = new Sprite();
            _local_3.graphics.lineStyle(1, 0x333333, 1, true);
            _local_3.graphics.moveTo(0, _arg_2);
            _local_3.graphics.lineTo(0, 0);
            _local_3.graphics.lineTo(_arg_1, 0);
            _local_3.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            _local_3.graphics.lineTo(_arg_1, _arg_2);
            _local_3.graphics.lineTo(0, _arg_2);
            return _local_3;
        }

        override public function remove()
        {
            if (!method_20()) {
                stage.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_116);
                this.var_69.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_266);
                this.var_124.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_399);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_114);
                removeEventListener(Event.ENTER_FRAME, this.method_155);
                this.var_27.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_334);
                this.var_27.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_452);
                this.var_27.removeEventListener(MouseEvent.MOUSE_OUT, this.method_417);
                this.var_89.removeEventListener(Event.CHANGE, this.method_212);
                this.var_89.removeEventListener(Event.COMPLETE, this.method_275);
                this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOK);
                this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
                this.m.textBox.removeEventListener(Event.CHANGE, this.method_415);
                this.var_326.dispose();
                if (CustomCursor.instance != null) {
                    CustomCursor.unsetInstance();
                    if (this.priorCursor != null) {
                        CustomCursor.change(this.priorCursor);
                        this.priorCursor.init();
                        if (!this.priorCursorActive) {
                            this.priorCursor.pause();
                        }
                    }
                } else {
                    if (this.priorCursor != null) {
                        this.priorCursor.remove();
                    }
                }
                this.var_69 = null;
                this.var_124 = null;
                this.var_27 = null;
                this.var_326 = null;
                this.var_146 = null;
                this.var_100 = null;
                this.var_89 = null;
                this.priorCursor = null;
                this.me = null;
            }
            super.remove();
        }


    }
}
