// Removable = class_7

package 
{
    import flash.display.Sprite;
    import flash.events.Event;

    public class Removable extends Sprite 
    {

        public static var REMOVE:String = "remove";

        private var removed:Boolean = false;

        public function Removable()
        {
        }

        public function isRemoved()
        {
            return this.removed;
        }

        public function safeRemove()
        {
            if (!this.removed) {
                this.remove();
            }
        }

        public function remove()
        {
            if (!this.removed) {
                this.removed = true;
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

