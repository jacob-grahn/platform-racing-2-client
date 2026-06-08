// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// Keys = class_2

package 
{
    import flash.events.KeyboardEvent;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.display.Stage;

    public class Keys 
    {

        private static var initialized:Boolean = false;
        private static var keys:Object = new Object(); // var_183


        public static function initialize(stage:Stage)
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
            stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
            stage.addEventListener(Event.DEACTIVATE, resetKeys);
            stage.addEventListener(FocusEvent.FOCUS_OUT, resetKeys);
            initialized = true;
        }

        public static function isPressed(i:uint):Boolean
        {
            if (!initialized) {
                return false;
            }
            return Boolean(i in keys);
        }

        private static function keyPressed(e:KeyboardEvent)
        {
            keys[e.keyCode] = true;
        }

        private static function keyReleased(e:KeyboardEvent)
        {
            if (e.keyCode in keys) {
                delete keys[e.keyCode];
            }
        }

        private static function resetKeys(e:*)
        {
            keys = new Object();
        }


    }
}//package 

