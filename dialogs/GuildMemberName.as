// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// dialogs.GuildMemberName = dialogs.class_189

package dialogs
{
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.Data;

    public class GuildMemberName extends Removable 
    {

        private var m:GuildMemberNameGraphic = new GuildMemberNameGraphic();
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function GuildMemberName(member:Object, owner:Boolean)
        {
            addChild(this.m);
            this.m.nameBox.htmlText = this.htmlNameMaker.makeName(member.name, member.group);
            this.m.gpTodayBox.text = Data.formatNumber(member.gp_today);
            this.m.gpTotalBox.text = Data.formatNumber(member.gp_total);
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
}//package dialogs

