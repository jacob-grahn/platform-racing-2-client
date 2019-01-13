// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//class_7

package 
{
    import flash.display.Sprite;
    import flash.events.Event;

    public class class_7 extends Sprite 
    {

        public static var REMOVE:String = "remove";

        private var var_214:Boolean = false;

        public function class_7()
        {
        }

        public function method_20()
        {
            return (this.var_214);
        }

        public function method_136()
        {
            if (!this.var_214) {
                this.remove();
            }
        }

        public function remove()
        {
            if (!this.var_214) {
                this.var_214 = true;
                if (parent != null) {
                    parent.removeChild(this);
                }
                while (numChildren > 0) {
                    removeChildAt(0);
                }
                dispatchEvent(new Event(REMOVE));
            }
        }


    }
}//package 

