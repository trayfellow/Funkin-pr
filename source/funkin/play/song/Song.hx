package funkin.play.song;

import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.song.SongData.SongTimeChange;
import funkin.play.song.SongData.SongTimeFormat;

/**
 * This is a data structure managing information about the current song.
 * This structure is created when the game starts, and includes all the data
 * from the `metadata.json` file.
 * It also includes the chart data, but only when this is the currently loaded song.
 *
 * It also receives script events; scripted classes which extend this class
 * can be used to perform custom gameplay behaviors only on specific songs.
 */
class Song // implements IPlayStateScriptedClass
{
	public final songId:String;

	final _metadata:Array<SongMetadata>;

	final variations:Array<String>;
	final difficulties:Map<String, SongDifficulty>;

	public function new(id:String)
	{
		this.songId = id;

		variations = [];
		difficulties = new Map<String, SongDifficulty>();

		_metadata = SongDataParser.parseSongMetadata(songId);
		if (_metadata == null || _metadata.length == 0)
		{
			throw 'Could not find song data for songId: $songId';
		}

		populateFromMetadata();

		// TODO: Disable later.
		cacheCharts();
	}

	function populateFromMetadata()
	{
		// Variations may have different artist, time format, generatedBy, etc.
		for (metadata in _metadata)
		{
			for (diffId in metadata.playData.difficulties)
			{
				var difficulty = new SongDifficulty(diffId, metadata.variation);

				variations.push(metadata.variation);

				difficulty.songName = metadata.songName;
				difficulty.songArtist = metadata.artist;
				difficulty.timeFormat = metadata.timeFormat;
				difficulty.divisions = metadata.divisions;
				difficulty.timeChanges = metadata.timeChanges;
				difficulty.loop = metadata.loop;
				difficulty.generatedBy = metadata.generatedBy;

				difficulty.stage = metadata.playData.stage;
				// difficulty.noteSkin = metadata.playData.noteSkin;

				difficulty.chars = new Map<String, SongPlayableChar>();
				for (charId in metadata.playData.playableChars.keys())
				{
					var char = metadata.playData.playableChars.get(charId);

					difficulty.chars.set(charId, char);
				}

				difficulties.set(diffId, difficulty);
			}
		}
	}

	/**
	 * Parse and cache the chart for all difficulties of this song.
	 */
	public function cacheCharts()
	{
		trace('Caching ${variations.length} chart files for song $songId');
		for (variation in variations)
		{
			var chartData = SongDataParser.parseSongChartData(songId, variation);

			for (diffId in chartData.notes.keys())
			{
				trace('  Difficulty $diffId');
				var difficulty = difficulties.get(diffId);
				if (difficulty == null)
				{
					trace('Could not find difficulty $diffId for song $songId');
					continue;
				}

				difficulty.notes = chartData.notes.get(diffId);
				difficulty.scrollSpeed = chartData.scrollSpeed.get(diffId);
				difficulty.events = chartData.events;
			}
		}
		trace('Done caching charts.');
	}

	/**
	 * Retrieve the metadata for a specific difficulty, including the chart if it is loaded.
	 */
	public function getDifficulty(diffId:String):SongDifficulty
	{
		return difficulties.get(diffId);
	}

	/**
	 * Purge the cached chart data for each difficulty of this song.
	 */
	public function clearCharts()
	{
		for (diff in difficulties)
		{
			diff.clearChart();
		}
	}

	public function toString():String
	{
		return 'Song($songId)';
	}
}

class SongDifficulty
{
	/**
	 * The difficulty ID, such as `easy` or `hard`.
	 */
	public final difficulty:String;

	/**
	 * The metadata file that contains this difficulty.
	 */
	public final variation:String;

	public var songName:String = SongValidator.DEFAULT_SONGNAME;
	public var songArtist:String = SongValidator.DEFAULT_ARTIST;
	public var timeFormat:SongTimeFormat = SongValidator.DEFAULT_TIMEFORMAT;
	public var divisions:Int = SongValidator.DEFAULT_DIVISIONS;
	public var loop:Bool = SongValidator.DEFAULT_LOOP;
	public var generatedBy:String = SongValidator.DEFAULT_GENERATEDBY;

	public var timeChanges:Array<SongTimeChange> = [];

	public var stage:String = SongValidator.DEFAULT_STAGE;
	public var chars:Map<String, SongPlayableChar> = null;

	public var scrollSpeed:Float = SongValidator.DEFAULT_SCROLLSPEED;

	public var notes:Array<SongNoteData>;
	public var events:Array<SongEventData>;

	public function new(diffId:String, variation:String)
	{
		this.difficulty = diffId;
		this.variation = variation;
	}

	public function clearChart():Void
	{
		notes = null;
	}
}
