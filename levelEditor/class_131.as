// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.class_131

package levelEditor
{
    import flash.text.TextField;
    import com.jiggmin.ColorPicker.ColorPicker;
    import data.Objects;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFieldType;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class class_131 extends class_130
    {

        public static var var_380:int = 0;

        private var textField:TextField;
        private var var_13:TextField;
        private var var_56:EditTextButton;
        private var var_12:ColorPicker;
        private var var_483:Boolean = false;
        private var var_565:String;
        private var var_563:int;

        public function class_131(_arg_1:String, _arg_2:int, _arg_3:int, _arg_4:int)
        {
            super(Objects.TextCode, _arg_2, _arg_3);
            this.textField = TextField(m);
            this.textField.wordWrap = false;
            this.textField.autoSize = TextFieldAutoSize.LEFT;
            this.textField.multiline = true;
            this.textField.textColor = _arg_4;
            this.method_262(_arg_1);
            method_31();
        }

        public static function method_343(_arg_1:String):String
        {
            _arg_1 = _arg_1.replace(/#/g, "#35");
            _arg_1 = _arg_1.replace(/`/g, "#96");
            _arg_1 = _arg_1.replace(/&/g, "#38");
            _arg_1 = _arg_1.replace(/,/g, "#44");
            return (_arg_1.replace(/;/g, "#59"));
        }

        public static function method_192(s:String):String
        {
            s = s.replace(/#96/g, "`");
            s = s.replace(/#38/g, "&");
            s = s.replace(/#44/g, ",");
            s = s.replace(/#59/g, ";");
            return s.replace(/#35/g, "#");
        }


        public function method_47():String
        {
            return (this.textField.text);
        }

        public function method_475(_arg_1:String)
        {
            this.textField.text = _arg_1;
            method_31();
        }

        public function method_184():String
        {
            return method_343(this.method_47());
        }

        public function method_262(_arg_1:String)
        {
            this.method_475(method_192(_arg_1));
        }

        // method_12 = getColor
        public function getColor():int
        {
            return this.textField.textColor;
        }

        public function setColor(_arg_1:int)
        {
            this.textField.textColor = _arg_1;
            if (this.var_13 != null) {
                this.var_13.textColor = _arg_1;
            }
        }

        override public function select()
        {
            this.method_788();
            this.method_624();
            super.select();
            addChild(this.var_56);
            addChild(this.var_12);
            this.var_565 = this.method_47();
            this.var_563 = this.getColor();
        }

        override public function deselect()
        {
            super.deselect();
            this.method_574();
            this.method_105();
            if (this.var_12 != null) {
                removeChild(this.var_12);
            }
            if (this.method_47() != this.var_565 || this.getColor() != this.var_563) {
                editor.cur.recordChangeText(this);
            }
        }

        public function method_270()
        {
            this.textField.visible = false;
            this.method_518();
            this.method_169(null);
            this.method_105();
        }

        public function method_574()
        {
            if (this.var_13 != null) {
                this.textField.visible = true;
                this.textField.text = this.var_13.text;
                this.method_172();
                method_31();
            }
        }

        private function method_518()
        {
            this.method_172();
            this.var_13 = new TextObjectGraphic().textBox;
            m = this.var_13;
            addChildAt(this.var_13, 1);
            Main.stage.focus = this.var_13;
            this.var_13.type = TextFieldType.INPUT;
            this.var_13.wordWrap = false;
            this.var_13.autoSize = TextFieldAutoSize.LEFT;
            this.var_13.multiline = true;
            this.var_13.background = true;
            this.var_13.border = true;
            this.var_13.selectable = true;
            this.var_13.textColor = this.textField.textColor;
            this.var_13.width = this.textField.width;
            this.var_13.height = this.textField.height;
            this.var_13.maxChars = 500;
            this.var_13.text = this.textField.text;
            if (this.var_13.width < 100) {
                this.var_13.width = 100;
            }
            this.var_13.addEventListener(Event.CHANGE, this.method_169, false, 0, true);
        }

        private function method_172()
        {
            if (this.var_13 != null) {
                m = this.textField;
                this.var_13.removeEventListener(Event.CHANGE, this.method_169);
                this.var_13.text = "";
                removeChild(this.var_13);
                this.var_13 = null;
            }
            Main.stage.focus = Main.stage;
        }

        private function method_788()
        {
            this.method_105();
            this.var_56 = new EditTextButton();
            this.var_56.addEventListener(MouseEvent.MOUSE_DOWN, this.method_421, false, 0, true);
            addChild(this.var_56);
        }

        private function method_105()
        {
            if (this.var_56 != null) {
                this.var_56.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_421);
                removeChild(this.var_56);
                this.var_56 = null;
            }
        }

        private function method_624()
        {
            if (this.var_12 == null) {
                this.var_12 = new ColorPicker();
                this.var_12.setColor(this.getColor());
                this.var_12.addEventListener(MouseEvent.MOUSE_DOWN, this.method_432, false, 0, true);
                this.var_12.addEventListener(Event.CLOSE, this.method_364, false, 0, true);
            }
            addChild(this.var_12);
        }

        private function method_768()
        {
            if (this.var_12 != null) {
                this.var_12.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_432);
                this.var_12.removeEventListener(Event.CLOSE, this.method_364);
                this.var_12.remove();
                this.var_12 = null;
            }
        }

        private function method_432(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            this.var_483 = true;
        }

        private function method_364(_arg_1:Event)
        {
            this.var_483 = false;
            class_131.var_380 = this.var_12.getColor();
            this.setColor(this.var_12.getColor());
        }

        private function method_169(_arg_1:Event)
        {
            method_31();
            method_345();
            this.positionInternals();
        }

        override protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            if (_arg_1.target != this.var_13 && !this.var_483) {
                super.mouseDownHandler(_arg_1);
            }
        }

        override protected function positionInternals()
        {
            super.positionInternals();
            if (this.var_56 != null) {
                this.var_56.x = 0;
                this.var_56.y = 0;
                this.var_56.scaleX = var_321;
                this.var_56.scaleY = var_307;
            }
            if (this.var_12 != null) {
                this.var_12.scaleX = var_321 * 0.4;
                this.var_12.scaleY = var_307 * 0.4;
                if (this.var_12.scaleX > 0) {
                    this.var_12.x = m.width - (this.var_12.width / 2);
                } else {
                    this.var_12.x = m.width + (this.var_12.width / 2);
                }
                if (this.var_12.scaleY > 0) {
                    this.var_12.y = 0 - (this.var_12.height / 2);
                } else {
                    this.var_12.y = 0 + (this.var_12.height / 2);
                }
            }
        }

        private function method_421(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            this.method_270();
        }

        override public function remove()
        {
            this.method_172();
            this.method_105();
            this.method_768();
            removeChild(this.textField);
            this.textField = null;
            super.remove();
        }


    }
}
