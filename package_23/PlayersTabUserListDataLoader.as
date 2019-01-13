// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTabUserListDataLoader = package_23.class_293

package package_23
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
            var request:URLRequest = new URLRequest(Main.baseURL + "/get_user_list.php");
            request.data = vars;
            this.superLoader.load(request);
            this.superLoader.addEventListener(Event.COMPLETE, this.populateList);
        }

        // _loc2 = request
        // _loc3 = i
        // method_281 = populateList
        private function populateList(e:Event)
        {
            var users:Array = this.superLoader.parsedData.users;
            for each (var user:Object in users) {
                method_138(user.name, user.group, user.rank, user.hats, user.status);
            }
            hideLoadingGraphic();
        }

        override public function remove()
        {
            this.superLoader.removeEventListener(Event.COMPLETE, this.populateList);
            super.remove();
        }


    }
}//package package_23

