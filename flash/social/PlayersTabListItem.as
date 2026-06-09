// Decompiled by AS3 Sorcerer 5.98


package social
{
    import com.jiggmin.data.HTMLNameMaker;

    public class PlayersTabListItem extends Removable 
    {

        protected var m:PlayersTabListItemGraphic = new PlayersTabListItemGraphic();
        protected var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function PlayersTabListItem()
        {
            addChild(this.m);
            this.htmlNameMaker.listenForLink(this.m.nameBox);
        }

        override public function remove()
        {
            this.htmlNameMaker.remove();
            this.htmlNameMaker = null;
            super.remove();
        }


    }
}

