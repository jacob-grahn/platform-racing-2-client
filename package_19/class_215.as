// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_215

package package_19
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class class_215 extends Sprite 
    {

        // _loc1 = sq
        public function class_215()
        {
            super();
            var sq:Square = new Square();
            sq.width = sq.height = 30;
            sq.alpha = 0;
            sq.x = sq.y = 15;
            addChild(sq);
            addEventListener(MouseEvent.CLICK, this.onClick);
        }

        protected function onClick(e:MouseEvent)
        {
        }

        public function remove()
        {
            removeEventListener(MouseEvent.CLICK, this.onClick);
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package package_19

