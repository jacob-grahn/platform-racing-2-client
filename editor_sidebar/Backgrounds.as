

package editor_sidebar
{
    import editor_tools.BackgroundColorPickerButton;
    import editor_tools.BackgroundButton;
    import com.jiggmin.data.Objects;

    public class Backgrounds extends SideBar 
    {

        public var cp_btn:BackgroundColorPickerButton = new BackgroundColorPickerButton(); // var_542

        public function Backgrounds()
        {
            addItem(this.cp_btn);
            addItem(new BackgroundButton(Objects.BG1Code, 8172673));
            addItem(new BackgroundButton(Objects.BG2Code, 13283754));
            addItem(new BackgroundButton(Objects.BG3Code, 528392));
            addItem(new BackgroundButton(Objects.BG4Code, 14731448));
            addItem(new BackgroundButton(Objects.BG5Code, 0));
            addItem(new BackgroundButton(Objects.BG6Code, 0));
            addItem(new BackgroundButton(Objects.BG7Code, 0));
        }

    }
}
