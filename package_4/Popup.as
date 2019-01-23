// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.Popup = package_4.class_25

package package_4
{
    import flash.geom.ColorTransform;
    import flash.events.Event;

    public class Popup extends class_7 
    {
        public static var LOADED = 'loaded';
        public static var REMOVED = 'removed';

        public var notActive:Boolean = false; // var_304 = notActive

        public function Popup(_arg_1:Boolean = true)
        {
            super();
            if (_arg_1) {
                var _local_2:ColorTransform = new ColorTransform();
                var _local_3:Square = new Square();
                _local_2.color = 0;
                _local_3.width = 550;
                _local_3.height = 400;
                _local_3.transform.colorTransform = _local_2;
                _local_3.alpha = 0.55;
                addChild(_local_3);
            }
            x = (550 / 2);
            y = (400 / 2);
            alpha = 0;
            Main.stage.addChild(this);
            addEventListener(Event.ENTER_FRAME, this.fadeIn, false, 0, true); // method_117
        }

        private function fadeIn(_arg_1:Event)
        {
            alpha = alpha + 0.15;
            if (alpha >= 1) {
                alpha = 1;
                removeEventListener(Event.ENTER_FRAME, this.fadeIn);
                dispatchEvent(new Event(LOADED));
            }
        }

        private function fadeOut(_arg_1:Event)
        {
            alpha = alpha - 0.15;
            if (alpha <= 0) {
                this.remove();
                dispatchEvent(new Event(REMOVED));
            }
        }

        // method_2 = startFadeOut
        public function startFadeOut()
        {
            this.notActive = true;
            removeEventListener(Event.ENTER_FRAME, this.fadeIn);
            addEventListener(Event.ENTER_FRAME, this.fadeOut, false, 0, true);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.fadeIn);
            removeEventListener(Event.ENTER_FRAME, this.fadeOut);
            if (stage != null) {
                stage.focus = stage;
            }
            super.remove();
        }


    }
}//package package_4

