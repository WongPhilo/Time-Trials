package;

import haxe.Timer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import openfl.Lib;
import haxe.ds.HashMap;

using StringTools;

class PlayState extends FlxState
{
	// Public Groups
	public var _vowels:Array<String> = ["A", "E", "I", "O", "U"];
	public var _consonants:Array<String> = [
		"B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
	];
	public var _values:Map<String, Int> = [
		"E" => 1,
		"T" => 1,
		"A" => 1,
		"I" => 1,
		"N" => 1,
		"O" => 1,
		"S" => 1,
		"H" => 1,
		"R" => 1,
		"D" => 1,
		"L" => 1,
		"U" => 1,
		"C" => 1,
		"M" => 1,
		"F" => 1,
		"W" => 2,
		"Y" => 2,
		"G" => 2, 
		"P" => 2, 
		"B" => 2,
		"V" => 2, 
		"K" => 2, 
		"Q" => 3,
		"J" => 3,
		"X" => 3,
		"Z" => 3];
		
	// Private Groups
	private var _tiles:Array<Tile>;
	private var _selected:Array<Tile>;
	private var _dictionary:Array<String>;

	// Text
	private var built:FlxText;
	private var dmgDis:FlxText;
	private var scoreDis:FlxText;
	private var gameOverText:FlxText;
	private var timetext:FlxText;

	// Buttons
	private var _gui:FlxGroup;
	private var launch:FlxButton;
	private var sbclear:FlxButton;
	private var delete:FlxButton;
	private var random:FlxButton;
	private var resetButton:FlxButton;

	// Variables
	private var launchString:String;
	private var _tile:Tile;
	private var dmg:Int;
	private var score:Int;
	private var sb:StringBuf;
	private var validSb:Bool;
	private var gameOver:Bool;

	//Timer
	private var ticker:FlxTimer;

	/**
	 * Creates and initializes a new game state.
	 */
	override public function create():Void
	{	
		// Initialize arrays.
		super.create();
		gameOver = false;
		_tiles = new Array<Tile>();
		_selected = new Array<Tile>();
		_dictionary = new Array<String>();
		fillDictionary();

		// Set up the bottom line of buttons.
		_gui = new FlxGroup();
		var height:Int = FlxG.height - 22;
		launch = new FlxButton(0, height, "Launch", launchCallback.bind());
		launch.color = FlxColor.GRAY;
		delete = new FlxButton(80, height, "Delete", deleteCallback.bind());
		sbclear = new FlxButton(160, height, "Clear", sbClearCallback.bind());
		random = new FlxButton(240, height, "Random", randomCallback.bind());
		_gui.add(launch);
		_gui.add(delete);
		_gui.add(sbclear);
		_gui.add(random);
		add(_gui);

		// Set up variables and text.
		dmg = 0;
		score = 0;
		dmgDis = new FlxText(180, 40, FlxG.width, "Predicted Damage: " + Std.string(dmg), 10);
		scoreDis = new FlxText(180, 80, FlxG.width, "Score: " + Std.string(score), 10);
		add(dmgDis);
		add(scoreDis);

		// Set up the grid of letters.
		var tileX = 10;
		var tileY = 10;
		sb = new StringBuf();
		built = new FlxText(25, FlxG.height - 50, FlxG.width, sb.toString(), 16);
		add(built);
		for (i in 0...5)
		{
			tileX = 10;
			for (j in 0...5)
			{
				var val:String = genChar();
				_tile = new Tile(tileX, tileY, val, null);
				_tile.onDown.callback = addTileCallback.bind(val, _tile);
				_tile.label.color = FlxColor.WHITE;
				_tiles.push(_tile);
				add(_tile);
				tileX += 30;
			}
			tileY += 30;
		}

		//Starts the timer
		ticker = new FlxTimer().start(30.0, Null -> gameOverCallback());
		timetext = new FlxText(180, 120, FlxG.width, "Time Left: " + Std.string(Std.int(ticker.timeLeft)), 10);
		add(timetext);
	}

	override public function update(elapsed:Float):Void
	{	
		super.update(elapsed);
		timetext.text = "Time Left: " + Std.string(Std.int(ticker.timeLeft));
	}

	/**
	 * Used to get a random letter, 50/50 chance for a consonant/vowel.
	 * @return A random letter. 
	 */
	function genChar():String
	{
		var vowel:Int = Std.int(Math.random() * 2);
		var rand:Int = -1;
		var val:String = null;
		if (vowel == 0)
		{
			rand = Std.int(Math.random() * _vowels.length);
			val = _vowels[rand];
		}
		else
		{
			rand = Std.int(Math.random() * _consonants.length);
			val = _consonants[rand];
		}

		return val;
	}

	/**
	 * Checks if the inputted string is found within the dictionary.
	 * @return Whether the string is present or not. 
	 */
	function validateSb():Bool
	{
		if (_dictionary.contains(sb.toString()))
		{
			launch.color = FlxColor.GREEN;
			return true;
		}
		else
		{
			launch.color = FlxColor.GRAY;
			return false;
		}
	}

	/**
	 * Handles the game over proc when the timer runs out. 
	 */
	function gameOverCallback():Void
	{
		gameOver = true;
		gameOverText = new FlxText(FlxG.width / 2, 40, "Game over!", 32);
		gameOverText.x -= gameOverText.width / 2;
		gameOverText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.RED, 2, 1);
		add(gameOverText);
		resetButton = new FlxButton(0, 0, "Reset?", resetCallback.bind());
		resetButton.screenCenter();
		add(resetButton);
	}

	/**
	 * Resets the game state to its beginning. 
	 */
	function resetCallback():Void
	{
		gameOver = false;
		sb = new StringBuf();
		sbClearCallback();
		for (v in _tiles)
		{
			var val:String = genChar();
			v.text = val;
			v.onDown.callback = addTileCallback.bind(val, v);
			v.label.color = FlxColor.WHITE;
		}

		gameOverText.destroy();
		resetButton.destroy();

		score = 0;
		dmgDis.text = "Predicted Damage: " + Std.string(dmg);
		scoreDis.text = "Score: " + Std.string(score);

		ticker = new FlxTimer().start(30.0, Null -> gameOverCallback());
	}

	/**
	 * Appends the selected tile to the inputted string, and updates the predicted
	 * damage accordingly.
	 * @param str The letter selected.
	 * @param t The tile selected.
	 */
	function addTileCallback(str:String, t:Tile):Void
	{	
		if (gameOver) {
			return;
		}

		if (_selected.contains(t))
		{
			return;
		}

		if (sb.length < 25)
		{
			sb.add(str);
			dmg += _values.get(str);
			dmgDis.text = "Predicted Damage: " + Std.string(dmg);
			t.label.color = FlxColor.RED;
			_selected.push(t);
			validSb = validateSb();
			built.text = sb.toString();
		}
	}

	/**
	 * Increases the score by the predicted damage. 
	 */
	function launchCallback():Void
	{
		if (gameOver)
		{
			return;
		}
		
		if (validSb)
		{
			sb = new StringBuf();
			for (v in _selected)
			{
				v.label.color = FlxColor.WHITE;
			}
			built.text = sb.toString();

			for (v in _selected)
			{	
				var val:String = genChar();
				v.text = val;
				v.onDown.callback = addTileCallback.bind(val, v);
				v.label.color = FlxColor.WHITE;
			}

			_selected = new Array<Tile>();
			score += dmg;
			dmg = 0;
			dmgDis.text = "Predicted Damage: " + Std.string(dmg);
			scoreDis.text = "Score: " + Std.string(score);
			return;
		}
	}

	/**
	 * Clears the inputted string. 
	 */
	function sbClearCallback():Void
	{
		if (gameOver)
		{
			return;
		}
		

		sb = new StringBuf();
		for (v in _selected)
		{
			v.label.color = FlxColor.WHITE;
		}
		_selected = new Array<Tile>();
		dmg = 0;
		dmgDis.text = "Predicted Damage: " + Std.string(dmg);
		built.text = sb.toString();
	}

	/**
	 * Deletes the last character within the inputted string.
	 */
	function deleteCallback():Void
	{
		if (gameOver)
		{
			return;
		}
		
		var tempstr:String = sb.toString();
		sb = new StringBuf();
		sb.addSub(tempstr, 0, tempstr.length - 1);
		var ret:Tile = _selected.pop();
		ret.label.color = FlxColor.WHITE;
		dmg -= _values.get(ret.label.text);
		dmgDis.text = "Predicted Damage: " + Std.string(dmg);
		validSb = validateSb();
		built.text = sb.toString();
	}

	/**
	 * Randomizes all characters within the letter grid, and decrements
	 * the turn. 
	 */
	function randomCallback():Void
	{
		if (gameOver)
		{
			return;
		}
		
		sb = new StringBuf();
		sbClearCallback();
		for (v in _tiles)
		{	
			var val:String = genChar();
			v.text = val;
			v.onDown.callback = addTileCallback.bind(val, v);
			v.label.color = FlxColor.WHITE;
		}
	}

	/**
	 * Fills the dictionary array with the contents of dictionary.txt. Should only be
	 * called once!
	 */
	function fillDictionary():Void
	{
		var lines:Array<String> = Assets.getText("assets/data/dictionary.txt").split("\n");
		var line:String = null;
		for (v in lines)
		{
			line = StringTools.replace(v, "\r", "");
			_dictionary.push(line);
		}
	}
}
