// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.GuildMemberName = package_4.class_189

package package_4
{
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.Data;

    public class GuildMemberName extends Removable 
    {

        private var m:GuildMemberNameGraphic = new GuildMemberNameGraphic();
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function GuildMemberName(name:String, group:String, gpToday:int, gpTotal:int, owner:Boolean)
        {
            addChild(this.m);
            this.m.nameBox.htmlText = this.htmlNameMaker.makeName(name, group);
            this.m.gpTodayBox.text = Data.formatNumber(gpToday);
            this.m.gpTotalBox.text = Data.formatNumber(gpTotal);
            if (owner) {
                this.m.hat.gotoAndStop(6);
                this.m.hat.colorMC.gotoAndStop(6);
                this.m.hat.colorMC2.gotoAndStop(6);
                this.m.nameBox.x = this.m.nameBox.x + 14;
                this.m.nameBox.width = this.m.nameBox.width - 14;
            }
            this.htmlNameMaker.listenForLink(this.m.nameBox);
        }

        override public function remove()
        {
            this.htmlNameMaker.remove();
            this.htmlNameMaker = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_4

