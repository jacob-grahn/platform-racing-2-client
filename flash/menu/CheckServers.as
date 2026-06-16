// menu.CheckServers = menu.class_14

package menu
{
    import fl.controls.ComboBox;
    import flash.utils.setInterval;
    import flash.utils.clearInterval;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class CheckServers 
    {

        private static var interval:uint;
        private static var target:ComboBox;
        private static var servers:Array;
        private static var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private static var active:Boolean = false;


        public static function activate()
        {
            if (!active) {
                deactivate();
                active = true;
                interval = setInterval(load, 60000);
                load();
            }
        }

        public static function deactivate()
        {
            clearInterval(interval);
            active = false;
        }

        public static function reload()
        {
            load();
        }

        private static function maybeLoad()
        {
            if (servers == null || servers.length == 0) {
                load();
            } else {
                target.enabled = true;
                target.prompt = '';
            }
        }

        private static function load()
        {
            if (target != null) {
                target.enabled = false;
                target.prompt = 'Loading...';
            }
            var request:URLRequest = new URLRequest(Main.baseURL + "/files/server_status_2.txt");
            superLoader.addEventListener(SuperLoader.d, parseData, false, 0, true);
            superLoader.addEventListener(SuperLoader.e, handleError, false, 0, true);
            superLoader.load(request);
        }

        // _loc2 = server
        private static function parseData(e:Event)
        {
            var server:Object;
            servers = superLoader.parsedData.servers;
            if (target != null) {
                if (servers == null || servers.length == 0) {
                    target.enabled = false;
                    target.prompt = 'No servers found. :(';
                    return;
                } else {
                    target.enabled = true;
                    target.prompt = '';
                }
            }
            for each (server in servers) {
                server.guild_id = parseInt(server.guild_id);
                server.server_id = parseInt(server.server_id);
                server.population = parseInt(server.population);
                server.port = parseInt(server.port);
            }
            if (target != null) {
                selectServer(target);
            }
        }

        private static function handleError(e:Event)
        {
            if (target != null) {
                target.enabled = false;
                target.prompt = 'No servers found. :(';
            }
        }

        public static function determineServer(box:ComboBox)
        {
            target = box;
            maybeLoad();
            if (servers != null) {
                selectServer(target);
            }
        }

        public static function removeBox()
        {
            target = null;
        }

        // _loc2 = complete
        // _loc3 = i
        // _loc4 = boxLength
        // _loc5 = boxItem
        // _loc6 = server
        private static function selectServer(box:ComboBox)
        {
            var complete:Boolean = false;
            var boxLength:int = box.length;
            if (boxLength > 0) {
                complete = true;
            }
            servers.sort(CheckServers.sortServers);
            for each (var server:Object in servers) {
                addToList(box, server);
            }
            if (!complete) {
                var boxItem:Object;

                // sets a user's private server
                var i:int = 0;
                while (i < boxLength) {
                    boxItem = box.getItemAt(i);
                    if (boxItem.server.guild_id != 0 && boxItem.server.guild_id == Main.guild && boxItem.server.status == "open") {
                        box.selectedItem = boxItem;
                        complete = true;
                        box.validateNow();
                        return;
                    }
                    i++;
                }

                // sets a server that's open, public, and under 180 players
                i = 0;
                while (i < boxLength) {
                    boxItem = box.getItemAt(i);
                    if (boxItem.server.guild_id == 0 && boxItem.server.status == "open" && boxItem.server.population < 180) {
                        box.selectedItem = boxItem;
                        complete = true;
                        box.validateNow();
                        return;
                    }
                    i++;
                }
            }
        }

        // _loc3 = ret
        private static function sortServers(s1:Object, s2:Object):int
        {
            if (Main.guild != 0) {
                if (s1.guild_id == Main.guild && s1.status !== 'down') {
                    return -1;
                }
                if (s2.guild_id == Main.guild) {
                    return 1;
                }
            }
            if (s1.guild_id == 0 && s2.guild_id != 0) {
                return -1; // if it's a regular vs private server, favor the first
            }
            if (s1.guild_id != 0 && s2.guild_id == 0) {
                return 1; // if it's a private vs regular server, favor the second
            }
            if (s1.guild_id == 0 && s2.guild_id == 0) { // if both the servers are public
                if (int(s1.port) < int(s2.port)) { // put the lowest port number first
                    return -1;
                } else {
                    return 1;
                }
            }
            if (s1.guild_id != 0 && s2.guild_id != 0) { // if both the servers are private
                if (int(s1.population) > int(s2.population)) { // put the highest population first
                    return -1;
                } else {
                    return 1;
                }
            }
        }

        // _loc3 = dropdownItem
        // _loc4 = serverStatus
        // _loc5 = serverName
        private static function addToList(dropdown:ComboBox, server:Object)
        {
            var dropdownItem:Object = getServerFromId(server.server_id, dropdown);
            var serverStatus:String = server.status;
            if (serverStatus == "open") {
                serverStatus = server.population + " online";
            }
            var serverName:String = server.server_name + " (" + serverStatus + ")";
            if (server.happy_hour == 1) {
                serverName = "!! " + serverName;
            }
            if (server.guild_id != 0) {
                serverName = "* " + serverName;
            }
            if (dropdownItem == null) {
                dropdownItem = {
                    "label":serverName,
                    "server":server
                }
                if (Main.beta == false || (Main.beta == true && server.guild_id == 205)) {
                    dropdown.addItem(dropdownItem);
                }
            }
        }

        // _loc3 = server
        // _loc4 = boxLength
        // _loc5 = i
        // _loc6 = boxItem
        private static function getServerFromId(id:int, box:ComboBox):Object
        {
            var i:int = 0;
            var boxLength:int = box.length;
            var boxItem:Object;
            while (i < boxLength) {
                boxItem = box.getItemAt(i);
                if (boxItem.server.server_id == id) {
                    var server:Object = boxItem;
                    break;
                }
                i++;
            }
            return server;
        }


    }
}//package menu

