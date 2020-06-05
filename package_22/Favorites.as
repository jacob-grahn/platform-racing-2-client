package package_22
{
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class Favorites extends LevelListing 
    {

        public function Favorites()
        {
            mode = "favorites";
            this.requestCourses();
        }

        override protected function requestCourses()
        {
            var vars:URLVariables = new URLVariables();
            vars.user_id = Main.userId;
            vars.page = pageNum;
            var request:URLRequest = new URLRequest(Main.levelsURL.substr(0, -7) + "/favorite_levels_get.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            superLoader.load(request);
            loadingGraphic.visible = true;
        }

    }
}
