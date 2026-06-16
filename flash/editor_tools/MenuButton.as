

package editor_tools
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class MenuButton extends Sprite 
    {

        // _loc1 = sq
        public function MenuButton()
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
}

