// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// dialogs.Popup = dialogs.class_25

package dialogs
{
    import flash.geom.ColorTransform;
    import flash.events.Event;

    public class Popup extends Removable 
    {
        private static var OPEN_POPUPS:Array = new Array();

        public static var LOADED = 'loaded';
        public static var REMOVED = 'removed';

        public var fadeOutStarted:Boolean = false; // var_304

        public function Popup(addOverlay:Boolean = true)
        {
            super();
            if (addOverlay) {
                var ct:ColorTransform = new ColorTransform();
                var overlay:Square = new Square();
                ct.color = 0;
                overlay.width = 550;
                overlay.height = 400;
                overlay.transform.colorTransform = ct;
                overlay.alpha = 0.55;
                addChild(overlay);
            }
            x = (550 / 2);
            y = (400 / 2);
            alpha = 0;
            Main.stage.addChild(this);
            addEventListener(Event.ENTER_FRAME, this.fadeIn, false, 0, true); // method_117
            OPEN_POPUPS.push(this);
        }

        private function fadeIn(e:Event)
        {
            alpha = alpha + 0.15;
            if (alpha >= 1) {
                alpha = 1;
                removeEventListener(Event.ENTER_FRAME, this.fadeIn);
                dispatchEvent(new Event(LOADED));
            }
        }

        private function fadeOut(e:Event)
        {
            alpha = alpha - 0.15;
            if (alpha <= 0) {
                this.remove();
                dispatchEvent(new Event(REMOVED));
            }
        }

        public static function getOpen()
        {
            return OPEN_POPUPS;
        }

        // method_2 = startFadeOut
        public function startFadeOut()
        {
            this.fadeOutStarted = true;
            removeEventListener(Event.ENTER_FRAME, this.fadeIn);
            addEventListener(Event.ENTER_FRAME, this.fadeOut, false, 0, true);
        }

        override public function remove()
        {
            OPEN_POPUPS.splice(OPEN_POPUPS.indexOf(this), 1);
            removeEventListener(Event.ENTER_FRAME, this.fadeIn);
            removeEventListener(Event.ENTER_FRAME, this.fadeOut);
            if (stage != null) {
                stage.focus = stage;
            }
            super.remove();
        }


    }
}//package dialogs

