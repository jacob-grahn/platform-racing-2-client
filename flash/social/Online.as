package social
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
            addUserEntry(name, group, rank, hats);
        }

        override public function remove()
        {
            this.cm.defineCommand("addUser", null);
            this.cm = null;
            super.remove();
        }


    }
}

