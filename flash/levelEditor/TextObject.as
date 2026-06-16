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

        public static var lastColor:int = 0;

        private var textField:TextField;
        private var editableTextField:TextField;
        private var editButton:EditTextButton;
        private var cp:ColorPicker;
        private var editing:Boolean = false;
        private var text:String;
        private var color:int;

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

        public function getText():String
        {
            return this.textField.text;
        }

        public function setText(s:String)
        {
            this.textField.text = s;
            recordRealDimensions();
        }

        public function getEscapedText():String
        {
            return escapeText(this.getText());
        }

        public function showParsedText(s:String)
        {
            this.setText(parseText(s));
        }

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

        public function startEditing()
        {
            this.textField.visible = false;
            this.addEditBox();
            this.onTextChange(null);
            this.removeEditButton();
        }

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
            this.editableTextField.addEventListener(Event.CHANGE, this.onTextChange, false, 0, true);
        }

        private function removeEditBox()
        {
            this.editing = false;
            if (this.editableTextField != null) {
                m = this.textField;
                this.editableTextField.removeEventListener(Event.CHANGE, this.onTextChange);
                this.editableTextField.text = "";
                removeChild(this.editableTextField);
                this.editableTextField = null;
            }
            Main.stage.focus = Main.stage;
        }

        private function addEditButton()
        {
            this.removeEditButton();
            this.editButton = new EditTextButton();
            this.editButton.addEventListener(MouseEvent.MOUSE_DOWN, this.clickEdit, false, 0, true);
            addChild(this.editButton);
        }

        private function removeEditButton()
        {
            if (this.editButton != null) {
                this.editButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.clickEdit);
                removeChild(this.editButton);
                this.editButton = null;
            }
        }

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

        private function removeColorPicker()
        {
            if (this.cp != null) {
                this.cp.removeEventListener(MouseEvent.MOUSE_DOWN, this.openColorPicker);
                this.cp.removeEventListener(Event.CLOSE, this.closeColorPicker);
                this.cp.remove();
                this.cp = null;
            }
        }

        private function openColorPicker(e:MouseEvent)
        {
            this.editing = true;
            e.stopImmediatePropagation();
        }

        private function closeColorPicker(e:Event)
        {
            this.editing = false;
            TextObject.lastColor = this.cp.getColor();
            this.setColor(this.cp.getColor());
        }

        private function onTextChange(_arg_1:Event)
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
