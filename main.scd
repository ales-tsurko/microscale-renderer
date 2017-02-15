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
fork {
	var score, pattern, titles, samples, numOfSamples, synth,
	loadedPercentage = 0, loadingIncr, buffer;

	SynthDef("microscale-sampler", {arg buf, loop;
		var out = PlayBuf.ar(2,
			buf,
			BufRateScale.kr(buf),
			loop: loop,
			doneAction: 2);
		Out.ar(0, out);
	}).load(s);

	score = Score.new;

	s.sync;

	titles = ["grusha", "random", "module", "beacon"];
	samples = Dictionary.new;

	//
	// load samples
	//

	// 4 tracks, 6 samples (4*6*6), 6 voices
	loadingIncr = 100 / (titles.size * titles[0].size * 6);

	s.sync;

	titles.do({arg item;
		// init empty array per track to hold voices
		samples[item.asSymbol] = Array.newClear(item.size);

		item.do({arg i, n;
			// voices initialization
			samples[item.asSymbol][n] = Dictionary.new;

			item.do({arg letter;
				// map letters per each voice to samples

				var samplePath = ("samples"+/+item.asString+/+"voice-"++(n+1)+/+letter++".aif").resolveRelative;
				var newBuf = Buffer.new;

				score.add([0, newBuf.allocReadMsg(samplePath)]);
				samples[item.asSymbol][n][letter.asSymbol] = newBuf;

				s.sync;
				(letter ++ ".aif of the voice-" ++ (n+1) + "of the track" + item + "is loaded into buffer").postln;

				loadedPercentage = loadedPercentage + loadingIncr;
				(loadedPercentage.round(0.01).asString ++ "%" + "loaded").postln;
			});
		});
	});

	s.sync;

	TempoClock.default.tempo = 60/59;

	pattern = Pbind(\instrument, "microscale-sampler",
		\loop, 0,
		\buf, samples[\grusha][0]["grusha.choose".asSymbol],
		\dur, Pseq([4], inf)
	);

	pattern.asScore(16).score.do({arg m, n;
		if(n > 0, {score.add(m)});
	});

	score.sort;

	score.render("out-pleaaaase.aiff".resolveRelative);

};

)