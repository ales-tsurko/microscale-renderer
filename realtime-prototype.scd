// https://en.wikipedia.org/wiki/Letter_frequency#Relative_frequencies_of_letters_in_the_English_language
// letters probabilities:
// a - 0.08167
// b - 0.01492
// c - 0.02782
// d - 0.04253
// e - 0.12702
// g - 0.02015
// h - 0.06094
// l - 0.04025
// m - 0.02406
// n - 0.06749
// o - 0.07507
// r - 0.05987
// s - 0.06327
// u - 0.02758

(
//
// Realtime prototype
//

fork {
	var loadedPercentage, loadingIncr;
	loadedPercentage = 0;

	~titles = ["grusha", "random", "module", "beacon"];
	~samples = Dictionary.new;
	// 4 tracks, 6 samples (4*6*6), 6 voices
	loadingIncr = 100 / (~titles.size * ~titles[0].size * 6);

	//
	// load samples
	//

	s.sync;

	~titles.do({arg item;
		// init empty array per track to hold voices
		~samples[item.asSymbol] = Array.newClear(item.size);

		item.do({arg i, n;
			// voices initialization
			~samples[item.asSymbol][n] = Dictionary.new;

			item.do({arg letter;
				// map letters per each voice to samples

				var samplePath = ("samples"+/+item.asString+/+"voice-"++(n+1)+/+letter++".aif").resolveRelative;
				var newBuf = Buffer.read(s, samplePath);

				s.sync;
				(letter ++ ".aif of the voice-" ++ (n+1) + "of the track" + item + "is loaded into buffer").postln;

				loadedPercentage = loadedPercentage + loadingIncr;
				(loadedPercentage.round(0.01).asString ++ "%" + "loaded").postln;

				~samples[item.asSymbol][n][letter.asSymbol] = newBuf;
			});
		});
	});

	s.sync;

	"All the samples are loaded".postln;

};

SynthDef("microscale-sampler", {arg buf, loop;
	var out = PlayBuf.ar(2,
		buf,
		BufRateScale.kr(buf),
		loop: loop,
		doneAction: 2);
	Out.ar(0, out);
}).add;



//
// [grusha]
//

~grushaProbs = [0.02015, 0.05987, 0.02758, 0.06327, 0.06094, 0.08167];
~probsWithDismatch = ~grushaProbs.copy;
~probsWithDismatch.add(1-~probsWithDismatch.sum);

~sampleChooser = {arg trackName, voiceNum, probsWithDismatch;
	var currSym = (trackName++0).wchoose(probsWithDismatch).asSymbol;

	if(currSym != \0, {
		Synth("microscale-sampler", [buf: ~samples[trackName.asSymbol][voiceNum][currSym]]);
	});

	// type should be always \rest
	\rest;
};

// duration in measures
~duration = 32;

~song = Ppar([
	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 0, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	),

	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 1, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	),

	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 2, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	),

	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 3, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	),

	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 4, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	),

	Pbind(
		\type, Pfunc({~sampleChooser.value("grusha", 5, ~probsWithDismatch)}),
		\dur, Pseq([4], ~duration)
	)
], 1);


~song.play;

)