// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.GuildName = ui.class_193

package ui
{
    import data.class_28;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import package_4.GuildPopup;

    public class GuildName extends Removable 
    {

        private var m:GuildNameGraphic;
        private var loader:Loader;
        private var guildId:int;

        public function GuildName(id:int, name:String, _arg_3:String, _arg_4:Boolean=false)
        {
            this.guildId = id;
            this.m = new GuildNameGraphic();
            addChild(this.m);
            useHandCursor = true;
            buttonMode = true;
            mouseChildren = false;
            if (_arg_4) {
                this.m.nameBox.htmlText = "<b>" + class_28.escapeString(name) + "</b>";
            } else {
                this.m.nameBox.text = name;
            }
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        public function makeWidth(n:Number)
        {
            this.m.nameBox.width = n;
        }

        private function clickHandler(_arg_1:MouseEvent)
        {
            new GuildPopup(this.guildId);
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.CLICK, this.clickHandler);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package ui

