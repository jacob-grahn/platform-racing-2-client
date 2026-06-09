// Decompiled by AS3 Sorcerer 5.98


package social
{
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class PlayersTabUserListDataLoader extends PlayersTabList
    {

        private var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);

        public function PlayersTabUserListDataLoader(mode:String)
        {
            var vars:URLVariables = new URLVariables();
            vars.mode = mode;
            var request:URLRequest = new URLRequest(Main.baseURL + "/user_list_get.php");
            request.data = vars;
            this.superLoader.load(request);
            this.superLoader.addEventListener(Event.COMPLETE, this.populateList);
        }

        private function populateList(e:Event)
        {
            var users:Array = this.superLoader.parsedData.users;
            for each (var user:Object in users) {
                addUserEntry(user.name, user.group, user.rank, user.hats, user.status);
            }
            hideLoadingGraphic();
        }

        override public function remove()
        {
            this.superLoader.removeEventListener(Event.COMPLETE, this.populateList);
            super.remove();
        }


    }
}

