// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_19.SizePickerMenuGraphic = package_19.class_277

package package_19
{
    import package_4.class_264;
    import fl.events.SliderEvent;
    import flash.events.Event;

    public class SizePickerMenu extends class_264 
    {

        private var m:SizePickerMenuGraphic = new SizePickerMenuGraphic();
        private var target:SizePicker;

        public function SizePickerMenu(sp:SizePicker, s:Number = 4)
        {
            this.target = sp;
            this.setSize(s);
            addChild(this.m);
            super(this.target);
            this.m.slider.addEventListener(SliderEvent.CHANGE, this.slideChange);
            this.m.textBox.addEventListener(Event.CHANGE, this.textChange);
        }

        // method_409 = slideChange
        private function slideChange(se:SliderEvent)
        {
            this.setSize(se.value);
        }

        // method_327 = textChange
        private function textChange(e:Event)
        {
            this.setSize(e.target.text);
        }

        private function setSize(size:Number)
        {
            size = Math.round(size);
            size = size < 1 ? 1 : size;
            size = size > 255 ? 255 : size;
            this.m.textBox.text = size.toString();
            this.m.slider.value = size;
            this.target.setSize(size);
        }

        override public function remove()
        {
            Main.stage.focus = Main.stage;
            this.m.slider.removeEventListener(SliderEvent.CHANGE, this.slideChange);
            this.m.textBox.removeEventListener(Event.CHANGE, this.textChange);
            super.remove();
        }


    }
}
