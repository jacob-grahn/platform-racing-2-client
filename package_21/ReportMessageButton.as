// package_21.ReportMessageButton = package_21.class_302

package package_21
{
    public class ReportMessageButton extends HoverDelayPopup 
    {

        private var m:ReportMessageButtonGraphic = new ReportMessageButtonGraphic();

        public function ReportMessageButton()
        {
            addChild(this.m);
            super("Report Message", 'If this message is inappropriate, you can report it to the moderators.');
        }

    }
}
