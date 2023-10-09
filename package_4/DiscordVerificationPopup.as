package package_4
{
    import com.jiggmin.data.Data;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.events.Event;

    public class DiscordVerificationPopup extends UploadingPopup 
    {

        public function DiscordVerificationPopup(code:String)
        {
            var vars:URLVariables = new URLVariables();
            vars.code = code;
            vars.pr2_name = Data.trimWhitespace(Main.loggedInAs);
            var request:URLRequest = new URLRequest("https://jiggmin2.com/discord/verify_pr2.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            super(request, SuperLoader.j);
            m.textBox.text = 'Verifying...';
        }

    }
}
