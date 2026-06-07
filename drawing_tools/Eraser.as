package drawing_tools
{
    import levelEditor.LevelEditor;

    public class Eraser extends Brush 
    {

        public function Eraser()
        {
            color = 0xFFFFFF;
            mode = "erase";
        }

        override protected function stopDrawing()
        {
            drawing = false;
            LevelEditor.editor.var_220.erase();
        }


    }
}//package drawing_tools

