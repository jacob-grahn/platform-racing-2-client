// dialogs.GuildJoinPopup = dialogs.class_187

package dialogs
{
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.events.Event;

    public class GuildJoinPopup extends UploadingPopup 
    {

        public function GuildJoinPopup(id:int)
        {
            var vars:URLVariables = new URLVariables();
            vars.guild_id = id;
            var request:URLRequest = new URLRequest(Main.baseURL + "/guild_join.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            super(request, SuperLoader.j);
            m.textBox.text = 'Joining guild...';
        }

        override protected function parsedDataHandler(e:Event)
        {
            var ret:Object = loader.parsedData;
            Main.guild = ret.guild_id;
            Main.emblem = ret.emblem;
            Main.guildName = ret.guild_name;
            Main.guildOwner = 0;
            super.parsedDataHandler(e);
        }

    }
}

