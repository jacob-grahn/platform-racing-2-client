// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// Page = class_5

package page
{
    import flash.display.Sprite;

    public class Page extends Sprite 
    {

        public var var_677:String = "0";

        public function Page()
        {
        }

        public function initialize()
        {
        }

        public function remove()
        {
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package page
