// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.TextObject = levelEditor.class_131

package levelEditor
{
    import flash.text.TextField;
    import com.jiggmin.ColorPicker.ColorPicker;
    import com.jiggmin.data.Objects;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFieldType;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    public class TextObject extends DrawObject
    {

        public static var var_380:int = 0;

        private var textField:TextField;
        private var editableTextField:TextField; // var_13
        private var editButton:EditTextButton; // var_56
        private var cp:ColorPicker; // var_12
        private var editing:Boolean = false; // var_483
        private var text:String; // var_565
        private var color:int; // var_563

        public function TextObject(_arg_1:String, objX:int, objY:int, objColor:int)
        {
            super(Objects.TextCode, objX, objY);
            this.textField = TextField(m);
            this.textField.wordWrap = false;
            this.textField.autoSize = TextFieldAutoSize.LEFT;
            this.textField.multiline = true;
            this.textField.textColor = objColor;
            this.showParsedText(_arg_1);
            recordRealDimensions();
        }

        override protected function onDelPress(e:KeyboardEvent)
        {
            if ((this.editing === false || this.editableTextField.text === '') && (e.keyCode === 46 || e.keyCode === 8)) {
                deleteObject();
            }
        }

        // method_343 = escapeText
        public static function escapeText(s:String):String
        {
            s = s.replace(/#/g, "#35");
            s = s.replace(/`/g, "#96");
            s = s.replace(/&/g, "#38");
            s = s.replace(/,/g, "#44");
            s = s.replace(/\+/g, "#43");
            s = s.replace(/-/g, "#45");
            return s.replace(/;/g, "#59");
        }

        // method_192 = parseText
        public static function parseText(s:String):String
        {
            s = s.replace(/#96/g, "`");
            s = s.replace(/#38/g, "&");
            s = s.replace(/#44/g, ",");
            s = s.replace(/#59/g, ";");
            s = s.replace(/#43/g, "+");
            s = s.replace(/#45/g, "-");
            return s.replace(/#35/g, "#");
        }

        // method_47 = getText
        public function getText():String
        {
            return this.textField.text;
        }

        // method_475 = setText
        public function setText(s:String)
        {
            this.textField.text = s;
            recordRealDimensions();
        }

        // method_184 = getEscapedText
        public function getEscapedText():String
        {
            return escapeText(this.getText());
        }

        // method_262 = showParsedText
        public function showParsedText(s:String)
        {
            this.setText(parseText(s));
        }

        // method_12 = getColor
        public function getColor():int
        {
            return this.textField.textColor;
        }

        public function setColor(tc:int)
        {
            this.textField.textColor = tc;
        }

        override public function select()
        {
            this.addEditButton();
            this.addColorPicker();
            super.select();
            addChild(this.editButton);
            addChild(this.cp);
            this.text = this.getText();
            this.color = this.getColor();
            stageRef.addEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
        }

        override public function deselect()
        {
            super.deselect();
            this.stopEditing();
            this.removeEditButton();
            if (this.cp != null) {
                removeChild(this.cp);
            }
            if (this.textField != null && (this.getText() != this.text || this.getColor() != this.color)) {
                editor.cur.recordChangeText(this);
            }
            stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
        }

        // method_270 = startEditing
        public function startEditing()
        {
            this.textField.visible = false;
            this.addEditBox();
            this.method_169(null);
            this.removeEditButton();
        }

        // method_574 = stopEditing
        private function stopEditing()
        {
            if (this.editableTextField != null) {
                this.textField.visible = true;
                this.textField.text = this.editableTextField.text;
                this.removeEditBox();
                recordRealDimensions();
                if (this.textField.text.replace(/^\s+|\s+$/g, '') === '') {
                    deleteObject();
                }
            }
        }

        // method_518 = addEditBox
        private function addEditBox()
        {
            this.removeEditBox();
            this.editing = true;
            this.editableTextField = new TextObjectGraphic().textBox;
            m = this.editableTextField;
            addChildAt(this.editableTextField, 1);
            Main.stage.focus = this.editableTextField;
            this.editableTextField.type = TextFieldType.INPUT;
            this.editableTextField.wordWrap = false;
            this.editableTextField.autoSize = TextFieldAutoSize.LEFT;
            this.editableTextField.multiline = true;
            this.editableTextField.background = true;
            this.editableTextField.border = true;
            this.editableTextField.selectable = true;
            this.editableTextField.width = this.textField.width;
            this.editableTextField.height = this.textField.height;
            this.editableTextField.maxChars = 500;
            this.editableTextField.text = this.textField.text;
            if (this.editableTextField.width < 100) {
                this.editableTextField.width = 100;
            }
            this.editableTextField.addEventListener(Event.CHANGE, this.method_169, false, 0, true);
        }

        // method_172 = removeEditBox
        private function removeEditBox()
        {
            this.editing = false;
            if (this.editableTextField != null) {
                m = this.textField;
                this.editableTextField.removeEventListener(Event.CHANGE, this.method_169);
                this.editableTextField.text = "";
                removeChild(this.editableTextField);
                this.editableTextField = null;
            }
            Main.stage.focus = Main.stage;
        }

        // method_788 = addEditButton
        private function addEditButton()
        {
            this.removeEditButton();
            this.editButton = new EditTextButton();
            this.editButton.addEventListener(MouseEvent.MOUSE_DOWN, this.clickEdit, false, 0, true);
            addChild(this.editButton);
        }

        // method_105 = removeEditButton
        private function removeEditButton()
        {
            if (this.editButton != null) {
                this.editButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.clickEdit);
                removeChild(this.editButton);
                this.editButton = null;
            }
        }

        // method_624 = addColorPicker
        private function addColorPicker()
        {
            if (this.cp == null) {
                this.cp = new ColorPicker();
                this.cp.setColor(this.getColor());
                this.cp.addEventListener(MouseEvent.MOUSE_DOWN, this.openColorPicker, false, 0, true);
                this.cp.addEventListener(Event.CLOSE, this.closeColorPicker, false, 0, true);
            }
            addChild(this.cp);
        }

        // method_768 = removeColorPicker
        private function removeColorPicker()
        {
            if (this.cp != null) {
                this.cp.removeEventListener(MouseEvent.MOUSE_DOWN, this.openColorPicker);
                this.cp.removeEventListener(Event.CLOSE, this.closeColorPicker);
                this.cp.remove();
                this.cp = null;
            }
        }

        // method_432 = openColorPicker
        private function openColorPicker(e:MouseEvent)
        {
            this.editing = true;
            e.stopImmediatePropagation();
        }

        // method_364 = closeColorPicker
        private function closeColorPicker(e:Event)
        {
            this.editing = false;
            TextObject.var_380 = this.cp.getColor();
            this.setColor(this.cp.getColor());
        }

        private function method_169(_arg_1:Event)
        {
            recordRealDimensions();
            hideHighlight();
            this.positionInternals();
        }

        override protected function mouseDownHandler(e:MouseEvent)
        {
            if (e.target != this.editableTextField) {
                super.mouseDownHandler(e);
            }
        }

        override protected function positionInternals()
        {
            super.positionInternals();
            if (this.editButton != null) {
                this.editButton.x = 0;
                this.editButton.y = 0;
                this.editButton.scaleX = buttonScaleX;
                this.editButton.scaleY = buttonScaleY;
            }
            if (this.cp != null) {
                this.cp.scaleX = buttonScaleX * 0.4;
                this.cp.scaleY = buttonScaleY * 0.4;
                if (this.cp.scaleX > 0) {
                    this.cp.x = m.width - (this.cp.width / 2);
                } else {
                    this.cp.x = m.width + (this.cp.width / 2);
                }
                if (this.cp.scaleY > 0) {
                    this.cp.y = 0 - (this.cp.height / 2);
                } else {
                    this.cp.y = 0 + (this.cp.height / 2);
                }
            }
        }

        // method_421 = clickEdit
        private function clickEdit(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            this.startEditing();
        }

        override public function remove()
        {
            this.removeEditBox();
            this.removeEditButton();
            this.removeColorPicker();
            removeChild(this.textField);
            this.textField = null;
            super.remove();
        }


    }
}
