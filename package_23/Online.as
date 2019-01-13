// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_23.Online

package package_23
{
    import data.CommandHandler;

    public class Online extends PlayersTabList 
    {

        private var cm:CommandHandler = CommandHandler.commandHandler;

        public function Online()
        {
            hideLoadingGraphic();
            this.cm.defineCommand("addUser", this.addUser);
            Main.socket.write("get_online_list`");
        }

        public function addUser(_arg_1:Array)
        {
            var _local_2:String = _arg_1[0];
            var _local_3:int = int(_arg_1[1]);
            var _local_4:int = int(_arg_1[2]);
            var _local_5:int = int(_arg_1[3]);
            method_138(_local_2, _local_3, _local_4, _local_5);
        }

        override public function remove()
        {
            this.cm.defineCommand("addUser", null);
            this.cm = null;
            super.remove();
        }


    }
}//package package_23

