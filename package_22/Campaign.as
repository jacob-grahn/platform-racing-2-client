// package_22.Campaign

package package_22
{
    import data.Memory;
    import flash.net.URLVariables;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import ui.PageNavigation;

    public class Campaign extends LevelListing
    {
        public static var campaignPage:int;

        // _loc1 = serverId
        // _loc2 = day
        // _loc3 = vars
        public function Campaign()
        {
            mode = "campaign";
            var serverId:int = Main.server.server_id;
            var day:int = Main.lastAuthTime.getDay();
            Campaign.campaignPage = this.pageNum = ((serverId + day) % 6) + 1;
            var levels:Array = Memory.memory["campaignInfo" + Campaign.campaignPage];
            if (levels != null) {
                clearTimeout(var_280);
                var_280 = setTimeout(this.showCourses, 250, levels);
            } else {
                requestCourses();
            }
            removeChild(pageNavigation);
            pageNavigation = new PageNavigation(this, "vertical", Campaign.campaignPage, 6, 283);
            pageNavigation.x = 328;
            pageNavigation.y = 26;
            addChild(pageNavigation);
        }

        override protected function showCourses(levels:Array)
        {
            Memory.memory["campaignInfo" + Campaign.campaignPage] = levels;
            super.showCourses(levels);
        }


    }
}
