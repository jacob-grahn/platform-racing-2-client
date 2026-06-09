// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// lobby.LobbySide = lobby.class_196

package lobby
{
    import page.PageHolder;
    import ui.TabsHolder;
    import page.Page;

    public class LobbySide extends PageHolder 
    {

        private var bg:HalfSquareBG = new HalfSquareBG();
        private var tabsHolder:TabsHolder;
        public function LobbySide(tabs:Array, hId:String = "", tabSel:Number = 0, maxW:Number = 100, h:Number = 100)
        {
            this.bg.y = 15;
            addChild(this.bg);
            this.tabsHolder = new TabsHolder(tabs, hId, tabSel, maxW);
            addChild(this.tabsHolder);
            this.setSize(maxW, h);
            super();
        }

        public function setSize(w:Number, h:Number)
        {
            this.bg.height = h - 15;
            this.bg.width = w;
            this.tabsHolder.populateTabs(w);
        }

        override public function changePage(p:Page)
        {
            super.changePage(p);
            if (p != null) {
                p.x = 4;
                p.y = 20;
            }
        }

        override public function remove()
        {
            this.tabsHolder.remove();
            super.remove();
        }


    }
}
