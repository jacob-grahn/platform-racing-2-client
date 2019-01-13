// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// SizePickerMenuGraphic = class_296

package 
{
    import flash.display.MovieClip;
    import fl.controls.Slider;
    import fl.controls.TextInput;

    public dynamic class SizePickerMenuGraphic extends MovieClip 
    {

        public var slider:Slider; // var_11
        public var textBox:TextInput;

        public function SizePickerMenuGraphic()
        {
            this.method_728();
            this.method_640();
        }

        internal function method_728():*
        {
            try {
                this.slider["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.slider.direction = "horizontal";
            this.slider.enabled = true;
            this.slider.liveDragging = true;
            this.slider.maximum = 0xFF;
            this.slider.minimum = 1;
            this.slider.snapInterval = 1;
            this.slider.tickInterval = 0;
            this.slider.value = 0;
            this.slider.visible = true;
            try {
                this.slider["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }

        internal function method_640():*
        {
            try {
                this.textBox["componentInspectorSetting"] = true;
            } catch(e:Error) {
            }
            this.textBox.displayAsPassword = false;
            this.textBox.editable = true;
            this.textBox.enabled = true;
            this.textBox.maxChars = 0;
            this.textBox.restrict = "1234567890";
            this.textBox.text = "25";
            this.textBox.visible = true;
            try {
                this.textBox["componentInspectorSetting"] = false;
            } catch(e:Error) {
            }
        }


    }
}
