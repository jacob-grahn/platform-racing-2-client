// ui.GuildName = ui.class_193

package ui
{
    import com.jiggmin.data.Data;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import dialogs.GuildPopup;

    public class GuildName extends Removable 
    {

        private var m:GuildNameGraphic;
        private var loader:Loader;
        private var guildId:int;

        public function GuildName(id:int, name:String, emblem:String, boldText:Boolean=false, wide:Boolean=false)
        {
            this.guildId = id;
            this.m = new GuildNameGraphic();
            addChild(this.m);
            useHandCursor = true;
            buttonMode = true;
            mouseChildren = false;
            if (boldText) {
                this.m.nameBox.htmlText = "<b>" + Data.escapeString(name) + "</b>";
            } else {
                this.m.nameBox.text = name;
            }
            this.m.nameBox.width = wide ? 145 : 110;
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

