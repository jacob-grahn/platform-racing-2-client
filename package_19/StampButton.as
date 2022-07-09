// package_19.class_221 = package_19.StampButton

package package_19
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import package_20.class_269;
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
            var _local_2:Number = 24;
            Data.method_314(stamp, _local_2, _local_2);
            stamp.x = ((_local_2 - stamp.width) / 2) + 3;
            stamp.y = ((_local_2 - stamp.height) / 2) + 3;
        }

        protected function select(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            CustomCursor.change(new class_269(this.displayCode));
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.select);
            parent.removeChild(this);
        }


    }
}
