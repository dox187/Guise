package guise.platform.html5.controls;
import guise.controls.data.ISelected;
import guise.controls.data.ITextLabel;
import guise.layout.IDisplayPosition;
import guise.platform.html5.display.DisplayTrait;
import guise.traits.core.ISize;
import js.Dom;
import js.Lib;

/**
 * ...
 * @author Tom Byrne
 */

class TextInputTrait extends TextLabelTrait
{

	public function new() 
	{
		super("input");
	}
}