

package editor_sidebar
{
    import flash.display.Sprite;
    import ui.CustomScrollBar;
    import editor_tools.SidebarEntry;
    import flash.display.DisplayObject;

    public class SideBar extends Sprite 
    {

        private var scrollBar:CustomScrollBar = new CustomScrollBar();
        private var scroll:Sprite = new Sprite();
        private var scrollMask:Sprite = new Sprite();
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var itemGap:Number = 10;

        public function SideBar()
        {
            addChild(this.scrollBar);
            addChild(this.scroll);
            addChild(this.scrollMask);
            this.scroll.y = 4;
            this.scrollBar.x = 35;
            this.scrollBar.y = 2;
            this.scrollBar.init(this.scroll, 348, 346);
            x = 222;
            y = -195;
            this.drawScrollMask();
        }

        private function drawScrollMask()
        {
            var x1:Number = 0;
            var y1:Number = 2;
            var maskWidth:Number = 30;
            var maskHeight:Number = 348;
            var x2:Number = (x1 + maskWidth);
            var y2:Number = (y1 + maskHeight);
            this.scrollMask.graphics.beginFill(0);
            this.scrollMask.graphics.moveTo(x1, y1);
            this.scrollMask.graphics.lineTo(x1, y2);
            this.scrollMask.graphics.lineTo(x2, y2);
            this.scrollMask.graphics.lineTo(x2, y1);
            this.scrollMask.graphics.lineTo(x1, y1);
            this.scrollMask.graphics.endFill();
            this.scroll.mask = this.scrollMask;
        }

        protected function addItem(item:DisplayObject, title:String="", desc:String="")
        {
            var entry:SidebarEntry = new SidebarEntry(item, title, desc);
            this.scroll.addChild(entry);
            entry.x = this.posX;
            entry.y = this.posY;
            this.posY = (this.posY + (entry.height + this.itemGap));
        }

        public function init()
        {
        }

        public function exit()
        {
            if (parent != null) {
                parent.removeChild(this);
            }
        }

        public function remove()
        {
            while (this.scroll.numChildren > 0) {
                SidebarEntry(this.scroll.getChildAt(0)).remove();
            }
            this.scrollBar.remove();
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}

