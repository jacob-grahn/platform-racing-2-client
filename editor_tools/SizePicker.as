
package editor_tools
{
    import flash.display.MovieClip;
    import editor_sidebar.Tools;
    import flash.events.MouseEvent;

    public class SizePicker extends MovieClip 
    {

        private var size:Number;
        private var tools:Tools;
        private var m:SizePickerGraphic = new SizePickerGraphic();
        private var menu:SizePickerMenu;

        public function SizePicker(t:Tools, s:int=4)
        {
            this.tools = t;
            this.setSize(s);
            addChild(this.m);
            addEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
        }

        private function downHandler(e:MouseEvent)
        {
            this.menu = new SizePickerMenu(this, this.size);
        }

        // method_210 = setSize
        public function setSize(s:Number)
        {
            this.size = s;
            this.m.circle.width = this.m.circle.height = Math.sqrt(this.size) * 3;
            this.tools.setSize(this.size);
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.downHandler);
            if (this.menu != null) {
                this.menu.remove();
            }
            parent.removeChild(this);
        }


    }
}
