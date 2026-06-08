// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.ColorPickerPopup = package_16.class_241

package com.jiggmin.ColorPicker
{
    import dialogs.Popup;
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
    import flash.ui.MouseCursor;

    public class ColorPickerPopup extends Popup
    {

        private var eyedropper:CursorEyedropper; // var_89
        private var palette:Sprite; // var_27
        private var colorChoices:Array; // var_145
        /** Outline on current color (goes around color box if in picker). */
        private var outlineCC:Sprite; // var_48
        /** Outline on preview color (goes around color box if in picker). */
        private var outlinePC:Sprite; // var_144
        private var initialColor:int; // var_598
        private var previewColor:int = -1; // var_188
        private var color:int = -1;
        private var hue:Number = 0;
        private var saturation:Number = 0;
        private var brightness:Number = 50;
        private var spectrum:Sprite; // var_69
        private var hueSlider:Sprite; // var_124
        private var colorPreviewBox:Sprite; // var_121
        // private var var_687:Sprite; // unused?
        private var spectrumBG:BitmapData; // var_326
        private var hueArrow:ColorPickerHueArrowGraphic; // var_146
        private var crosshairs:ColorPickerCrosshairsGraphic; // var_100
        private var priorCursor:CustomCursor; // var_194
        private var priorCursorActive:Boolean;
        private var me:MouseEvent;
        private var m:ColorPickerPopupGraphic;

        // _loc2 = outlineHS
        // _loc3 = outlineCPB
        public function ColorPickerPopup(initialColor:int)
        {
            super(false);
            this.m = new ColorPickerPopupGraphic();
            addChild(this.m);
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOK, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);

            // textbox
            this.m.textBox.restrict = "0123456789abcdefABCDEF#x";
            this.m.textBox.addEventListener(Event.CHANGE, this.setColorFromText, false, 0, true);

            // color spectrum and hue slider
            this.spectrum = this.initSpectrum(60, 60);
            this.spectrum.x = 15;
            this.spectrum.y = 150;
            addChild(this.spectrum);
            this.showOutline(this.spectrum);
            this.hueSlider = this.initHueSlider(15, 60);
            this.hueSlider.x = this.spectrum.x + this.spectrum.width + 10;
            this.hueSlider.y = this.spectrum.y;
            addChild(this.hueSlider);
            var outlineHS:Sprite = this.makeOutline(15, 60);
            outlineHS.x = this.hueSlider.x;
            outlineHS.y = this.hueSlider.y;
            addChild(outlineHS);

            // traditional color picker (palette)
            this.outlineCC = this.makePickedColorBox();
            this.outlineCC.visible = false;
            this.outlinePC = this.makePickedColorBox();
            this.outlinePC.visible = false;
            this.palette = new Sprite();
            this.palette.x = 15;
            this.palette.y = 15;
            this.palette.mouseChildren = false;
            this.palette.addChild(this.outlineCC);
            this.palette.addChild(this.outlinePC);
            this.initPalette();
            addChild(this.palette);

            // color preview box
            this.colorPreviewBox = new Sprite();
            this.colorPreviewBox.graphics.beginFill(0);
            this.colorPreviewBox.graphics.drawRect(0, 0, 120, 25);
            this.colorPreviewBox.graphics.endFill();
            this.colorPreviewBox.x = 115;
            this.colorPreviewBox.y = 185;
            addChild(this.colorPreviewBox);
            var outlineCPB:Sprite = this.makeOutline(120, 25);
            outlineCPB.x = this.colorPreviewBox.x;
            outlineCPB.y = this.colorPreviewBox.y;
            addChild(outlineCPB);

            // init
            this.setColor(initialColor);
            this.initialColor = initialColor;
            this.highlightCurrentColorIfInPalette();
            this.hueSlider.addEventListener(MouseEvent.MOUSE_DOWN, this.clickHueSlider, false, 0, true);
            this.spectrum.addEventListener(MouseEvent.MOUSE_DOWN, this.onSpectrumDown, false, 0, true);
            this.palette.addEventListener(MouseEvent.MOUSE_MOVE, this.hoverOverPalette, false, 0, true);
            this.palette.addEventListener(MouseEvent.MOUSE_DOWN, this.clickPalette, false, 0, true);
            this.palette.addEventListener(MouseEvent.MOUSE_OUT, this.hoverOutPalette, false, 0, true);
        }

        public function init()
        {
            this.eyedropper = new CursorEyedropper();
            this.eyedropper.addExclusion(this);
            this.eyedropper.addEventListener(Event.CHANGE, this.onEyedropperMove, false, 0, true);
            this.eyedropper.addEventListener(Event.COMPLETE, this.applyColor, false, 0, true);
            if (CustomCursor.instance != null) {
                this.priorCursor = CustomCursor.instance;
                this.priorCursorActive = this.priorCursor.isActive();
                this.priorCursor.pause();
            }
            CustomCursor.change(this.eyedropper);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler, false, 0, true);
            if (x + width > Main.stage.stageWidth) {
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

        // _loc2 = newColor
        public function setColor(c:int)
        {
            if (this.color != c) {
                this.color = c;
                var newColor:Object = ColorUtil.hex24ToHSB(c);
                this.hue = newColor.hue;
                this.hueArrow.y = Math.round(60 - ((this.hue / 360) * 60));
                this.updateSpectrumGradient();
                this.saturation = newColor.saturation;
                this.crosshairs.x = Math.round((this.saturation / 100) * 60);
                this.brightness = newColor.brightness;
                this.crosshairs.y = Math.round(60 - ((this.brightness / 100) * 60));
                this.updateColorPreview();
            }
        }

        private function updateColorPreview(c:int = -1)
        {
            if (c == -1) {
                c = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            }
            if (stage.focus != this.m.textBox.textField) {
                this.m.textBox.text = "#" + ColorUtil.decimalToHex(c).substr(2);
            }
            this.changePreviewBoxColor(this.colorPreviewBox, c);
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function getColor():int
        {
            return this.previewColor != -1 ? this.previewColor : this.color;
        }

        public function addExclusion(d:DisplayObject)
        {
            this.eyedropper.addExclusion(d);
        }

        private function changePreviewBoxColor(d:DisplayObject, c:int)
        {
            var newColor:Object = ColorUtil.hex24ToRGB(c);
            d.transform.colorTransform = new ColorTransform(0, 0, 0, 1, newColor.red, newColor.green, newColor.blue, 0);
        }

        private function highlightCurrentColorIfInPalette()
        {
            var paletteBoxSize:int = 10;
            for (var j:int = 0; j < this.colorChoices.length; j++) {
                for (var k:int = 0; k < this.colorChoices[j].length; k++) {
                    if (this.colorChoices[j][k] == this.color) {
                        this.outlineCC.visible = true;
                        this.outlineCC.x = j * paletteBoxSize;
                        this.outlineCC.y = k * paletteBoxSize;
                    }
                }
            }
        }

        private function mouseUpHandler(e:MouseEvent)
        {
            Mouse.show();
            Mouse.cursor = MouseCursor.ARROW;
            Mouse.cursor = MouseCursor.AUTO;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.previewColorAtMouse);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.dragHueSlider);
        }

        private function onSpectrumDown(e:MouseEvent)
        {
            Mouse.hide();
            this.previewColorAtMouse(e);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.previewColorAtMouse, false, 0, true);
        }

        private function clickHueSlider(e:MouseEvent)
        {
            Mouse.hide();
            this.dragHueSlider(e);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.dragHueSlider, false, 0, true);
        }

        private function previewColorAtMouse(e:MouseEvent)
        {
            var mousePt:Point = this.spectrum.globalToLocal(new Point(e.stageX, e.stageY));
            var targetX:int = Data.numLimit(Math.round(mousePt.x), 0, 60);
            var targetY:int = Data.numLimit(Math.round(mousePt.y), 0, 60);
            this.crosshairs.x = targetX;
            this.crosshairs.y = targetY;
            this.saturation = 100 * (targetX / 60);
            this.brightness = 100 - (100 * (targetY / 60));
            this.color = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            this.updateColorPreview();
            this.outlineCC.visible = false;
        }

        private function dragHueSlider(e:MouseEvent)
        {
            var _local_2:Point = this.hueSlider.globalToLocal(new Point(e.stageX, e.stageY));
            var _local_3:int = Data.numLimit(_local_2.y, 0, 60);
            this.hueArrow.y = Math.round(_local_3);
            this.hue = 360 - (360 * (_local_3 / 60));
            this.color = ColorUtil.hsbToHex24(this.hue, this.saturation, this.brightness);
            this.updateSpectrumGradient();
            this.updateColorPreview();
            this.outlineCC.visible = false;
        }

        private function onEyedropperMove(e:Event)
        {
            this.previewColor = this.eyedropper.color;
            this.updateColorPreview(this.previewColor);
        }

        private function applyColor(e:Event)
        {
            this.previewColor = -1;
            this.setColor(this.eyedropper.color);
            this.updateColorPreview();
            safeRemove();
        }

        private function hoverOverPalette(e:MouseEvent)
        {
            var mousePos:Point = this.palette.globalToLocal(new Point(e.stageX, e.stageY));
            var gridX:int = Data.numLimit(Math.floor(mousePos.x / 10), 0, 21);
            var gridY:int = Data.numLimit(Math.floor(mousePos.y / 10), 0, 11);
            this.outlinePC.x = gridX * 10;
            this.outlinePC.y = gridY * 10;
            this.outlinePC.visible = true;
            this.previewColor = this.colorChoices[gridX][gridY];
            this.updateColorPreview(this.previewColor);
        }

        private function clickPalette(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            var choiceX:int = this.outlinePC.x / 10;
            var choiceY:int = this.outlinePC.y / 10;
            this.setColor(this.colorChoices[choiceX][choiceY]);
            this.outlineCC.x = choiceX * 10;
            this.outlineCC.y = choiceY * 10;
            this.outlineCC.visible = true;
            this.remove();
        }

        private function hoverOutPalette(e:MouseEvent)
        {
            this.previewColor = -1;
            this.outlinePC.visible = false;
            this.updateColorPreview();
        }

        private function setColorFromText(e:Event)
        {
            if (stage.focus == this.m.textBox.textField) {
                var hex:String = this.m.textBox.text;
                var c:int = 0;
                if (hex != "") {
                    hex = hex.split("#").join("");
                    hex = hex.split("0x").join("");
                    c = Number("0x" + hex);
                    if (isNaN(c)) {
                        c = 0;
                    }
                }
                this.setColor(c);
            }
        }

        private function clickOK(e:MouseEvent)
        {
            this.remove();
        }

        private function clickCancel(e:MouseEvent)
        {
            this.color = this.initialColor;
            dispatchEvent(new Event(Event.CHANGE));
            this.remove();
        }

        private function initPalette()
        {
            this.palette.graphics.clear();
            this.palette.graphics.lineStyle(1, 0, 1, true);
            this.colorChoices = ColorChoices.populate();
            var _local_4:int = 10;
            for (var _local_6:int = 0; _local_6 < this.colorChoices.length; _local_6++) {
                var _local_3:Array = this.colorChoices[_local_6];
                for (var _local_7:int = 0; _local_7 < _local_3.length; _local_7++) {
                    var _local_5:int = this.colorChoices[_local_6][_local_7];
                    if (_local_5 == this.color) {
                        this.outlineCC.visible = true;
                        this.outlineCC.x = _local_6 * _local_4;
                        this.outlineCC.y = _local_7 * _local_4;
                    }
                    this.palette.graphics.beginFill(_local_5);
                    this.palette.graphics.drawRect(_local_6 * _local_4, _local_7 * _local_4, _local_4, _local_4);
                    this.palette.graphics.endFill();
                }
            }
        }

        // _loc1 = box
        /**
         * Draws the white square that goes around one of the colors in the color picker when hovered over or selected.
         */
        private function makePickedColorBox():Sprite
        {
            var box:Sprite = new Sprite();
            box.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            box.graphics.drawRect(0, 0, 10, 10);
            return box;
        }

        private function initHueSlider(w:int, h:int):Sprite
        {
            var _local_3:BitmapData = new BitmapData(w, h, false, 0xFFFFFF);
            for (var _local_6:int = 0; _local_6 < h; _local_6++) {
                var _local_4:int = 360 - (360 * _local_6 / h);
                var _local_5:Number = ColorUtil.hsbToHex24(_local_4, 100, 100);
                _local_3.fillRect(new Rectangle(0, _local_6, w, 1), _local_5);
            }
            this.hueArrow = new ColorPickerHueArrowGraphic();
            this.hueArrow.x = w + 1;
            this.hueArrow.y = h;
            this.hueArrow.mouseEnabled = this.hueArrow.mouseChildren = false;
            var _local_7:Sprite = new Sprite();
            _local_7.graphics.beginFill(0, 0);
            _local_7.graphics.drawRect(0, 0, (w + 10), h);
            _local_7.graphics.endFill();
            var _local_8:Sprite = new Sprite();
            _local_8.addChild(new Bitmap(_local_3));
            _local_8.addChild(this.hueArrow);
            _local_8.addChild(_local_7);
            return _local_8;
        }

        private function initSpectrum(w:int, h:int):Sprite
        {
            this.spectrumBG = new BitmapData(w, h, false, 0);
            this.crosshairs = new ColorPickerCrosshairsGraphic();
            this.crosshairs.mouseEnabled = this.crosshairs.mouseChildren = false;
            this.crosshairs.x = this.crosshairs.y = 20;
            var _local_4:Sprite = new Sprite();
            _local_4.addChild(new Bitmap(this.spectrumBG));
            _local_4.addChild(this.crosshairs);
            return _local_4;
        }

        private function updateSpectrumGradient()
        {
            for (var _local_9:int = 0; _local_9 < this.spectrumBG.width; _local_9++) {
                var _local_6:Number = (_local_9 / this.spectrumBG.width) * 100;
                for (var _local_10:int = 0; _local_10 < this.spectrumBG.height; _local_10++) {
                    var _local_7:Number = 100 - ((_local_10 / this.spectrumBG.height) * 100);
                    var _local_5:Number = ColorUtil.hsbToHex24(this.hue, _local_6, _local_7);
                    this.spectrumBG.setPixel(_local_9, _local_10, _local_5);
                }
            }
        }

        private function showOutline(d:DisplayObject):Sprite
        {
            var hlo:Sprite = this.makeOutline(Math.round(d.width), Math.round(d.height));
            hlo.x = d.x;
            hlo.y = d.y;
            addChild(hlo);
        }

        private function makeOutline(_arg_1:int, _arg_2:int):Sprite
        {
            var hlo:Sprite = new Sprite();
            hlo.graphics.lineStyle(1, 0x333333, 1, true);
            hlo.graphics.moveTo(0, _arg_2);
            hlo.graphics.lineTo(0, 0);
            hlo.graphics.lineTo(_arg_1, 0);
            hlo.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            hlo.graphics.lineTo(_arg_1, _arg_2);
            hlo.graphics.lineTo(0, _arg_2);
            return hlo;
        }

        override public function remove()
        {
            if (!isRemoved()) {
                stage.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.previewColorAtMouse);
                this.spectrum.removeEventListener(MouseEvent.MOUSE_DOWN, this.onSpectrumDown);
                this.hueSlider.removeEventListener(MouseEvent.MOUSE_DOWN, this.clickHueSlider);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.dragHueSlider);
                this.palette.removeEventListener(MouseEvent.MOUSE_MOVE, this.hoverOverPalette);
                this.palette.removeEventListener(MouseEvent.MOUSE_DOWN, this.clickPalette);
                this.palette.removeEventListener(MouseEvent.MOUSE_OUT, this.hoverOutPalette);
                this.eyedropper.removeEventListener(Event.CHANGE, this.onEyedropperMove);
                this.eyedropper.removeEventListener(Event.COMPLETE, this.applyColor);
                this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOK);
                this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
                this.m.textBox.removeEventListener(Event.CHANGE, this.setColorFromText);
                this.spectrumBG.dispose();
                if (CustomCursor.instance != null) {
                    CustomCursor.unsetInstance();
                    if (this.priorCursor != null) {
                        CustomCursor.change(this.priorCursor);
                        this.priorCursor.init();
                        if (!this.priorCursorActive) {
                            this.priorCursor.pause();
                        }
                    }
                } else if (this.priorCursor != null) {
                    this.priorCursor.remove();
                }
                this.spectrum = null;
                this.hueSlider = null;
                this.palette = null;
                this.spectrumBG = null;
                this.hueArrow = null;
                this.crosshairs = null;
                this.eyedropper = null;
                this.priorCursor = null;
                this.me = null;
            }
            super.remove();
        }


    }
}
