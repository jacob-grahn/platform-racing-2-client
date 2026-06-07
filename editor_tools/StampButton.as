
package editor_tools
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import drawing_tools.ObjectPlacer;
    import ui.CustomCursor;

    public class StampButton extends Sprite 
    {

        protected var displayCode:int;

        // _loc2 = bg
        // _loc3 = stamp
        public function StampButton(code:int)
        {
            super();
            this.displayCode = code;
            var bg:Square = new Square();
            bg.width = bg.height = 30;
            bg.x = bg.y = 15;
            bg.alpha = 0;
            addChild(bg);
            var stamp:DisplayObject = Objects.getFromCode(this.displayCode);
            this.fit(stamp);
            addChild(stamp);
            addEventListener(MouseEvent.MOUSE_DOWN, this.select);
        }

        protected function fit(stamp:DisplayObject)
        {
            var size:Number = 24;
            Data.method_314(stamp, size, size);
            stamp.x = ((size - stamp.width) / 2) + 3;
            stamp.y = ((size - stamp.height) / 2) + 3;
        }

        protected function select(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            CustomCursor.change(new ObjectPlacer(this.displayCode));
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.select);
            parent.removeChild(this);
        }


    }
}
