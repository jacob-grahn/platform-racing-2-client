// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_23.Online

package package_23
{
    import com.jiggmin.data.CommandHandler;

    public class Online extends PlayersTabList 
    {

        private var cm:CommandHandler = CommandHandler.commandHandler;

        public function Online()
        {
            hideLoadingGraphic();
            this.cm.defineCommand("addUser", this.addUser);
            Main.socket.write("get_online_list`");
        }

        // _loc2 = name
        // _loc3 = group
        // _loc4 = rank
        // _loc5 = hats
        public function addUser(a:Array)
        {
            var name:String = a[0];
            var group:String = a[1];
            var rank:int = int(a[2]);
            var hats:int = int(a[3]);
            method_138(name, group, rank, hats);
        }

        override public function remove()
        {
            this.cm.defineCommand("addUser", null);
            this.cm = null;
            super.remove();
        }


    }
}//package package_23

