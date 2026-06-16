// ui.MuteButton = ui.class_13

package ui
{
    import flash.events.MouseEvent;
    import flash.media.SoundTransform;
    import flash.media.SoundMixer;
    import flash.geom.ColorTransform;

    public class MuteButton extends Removable 
    {

        public static var muted:Boolean = true;

        private var m:MuteButtonGraphic = new MuteButtonGraphic();

        public function MuteButton()
        {
            addChild(this.m);
            addEventListener(MouseEvent.CLICK, this.onClick, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OVER, this.hoverOverColorChange, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.hoverOutColorChange);
            this.doToggle(false);
        }

        public function toggle()
        {
            this.doToggle(!MuteButton.muted);
        }

        public function doToggle(bool:Boolean)
        {
            var st:SoundTransform = new SoundTransform();
            MuteButton.muted = bool;
            this.m.button.waves.visible = !MuteButton.muted;
            if (MuteButton.muted) {
                st.volume = 0;
            } else {
                st.volume = 1;
            }
            SoundMixer.soundTransform = st;
        }

        private function onClick(e:MouseEvent)
        {
            this.toggle();
        }

        private function hoverOverColorChange(e:MouseEvent)
        {
            var ct:ColorTransform = new ColorTransform(0.5, 0.5, 0.5, 1, 127, 127, 127, 0);
            this.m.button.transform.colorTransform = ct;
        }

        private function hoverOutColorChange(e:MouseEvent)
        {
            var ct:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
            this.m.button.transform.colorTransform = ct;
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.CLICK, this.onClick);
            removeEventListener(MouseEvent.MOUSE_OVER, this.hoverOverColorChange);
            removeEventListener(MouseEvent.MOUSE_OUT, this.hoverOutColorChange);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package ui

