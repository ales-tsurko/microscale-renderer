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


// 0 at the end of the each title is a silence sample

(
fork {
	var initialScore, grushaScore, grushaPattern,
	sampleChooserFunc, probs, songDur,
	titles, samples;

	// sample probabilities corresponding to letters
	// (probability of a character in the article)
	probs = Dictionary.new;
	probs["grusha"] = [0.02015, 0.05987, 0.02758, 0.06327, 0.06094, 0.08167];
	probs["random"] = [0.05987, 0.08167, 0.06749, 0.04253, 0.07507, 0.02406];
	probs["module"] = [0.02406, 0.07507, 0.04253, 0.02758, 0.04025, 0.12702];
	probs["beacon"] = [0.01492, 0.12702, 0.08167, 0.02782, 0.07507, 0.06749];

	// calculate and add a non-match character probability
	probs.keys.do({arg key;
		probs[key].add(1-probs[key].sum);
	});

	s.sync;

	//
	// The sampler SynthDef
	//

	SynthDef("microscale-sampler", {arg buf, loop;
		var out = PlayBuf.ar(2,
			buf,
			BufRateScale.kr(buf),
			loop: loop,
			doneAction: 2);
		Out.ar(0, out);
	}).load(s);

	// score that contains all the buffers
	initialScore = Score.new;

	s.sync;

	titles = ["grusha", "random", "module", "beacon"];
	samples = Dictionary.new;

	//
	// load samples
	//

	s.sync;

	titles.do({arg item;
		// init empty array per track to hold voices
		samples[item.asSymbol] = Array.newClear(item.size);

		item.do({arg i, n;
			// voices initialization
			samples[item.asSymbol][n] = Dictionary.new;

			// item++0 because of 0.aif — the silence sample
			(item++0).do({arg letter;
				// map letters per each voice to samples

				var samplePath = ("samples"+/+item.asString+/+"voice-"++(n+1)+/+letter++".aif").resolveRelative;
				var newBuf = Buffer.new;

				initialScore.add([0, newBuf.allocReadMsg(samplePath)]);
				samples[item.asSymbol][n][letter.asSymbol] = newBuf;
			});
		});
	});

	s.sync;

	//
	// [grusha]
	//

	TempoClock.default.tempo = 60/59;

	songDur = 1040;

	grushaPattern = Ppar([
		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][0]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),

		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][1]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),

		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][2]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),

		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][3]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),

		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][4]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),

		Pbind(\instrument, "microscale-sampler",
			\buf, Pfunc({samples[\grusha][5]["grusha0".wchoose(probs["grusha"]).asSymbol]}),
			\dur, Pseq([4], songDur/2)
		),
	], 1);

	grushaScore = grushaPattern.asScore(songDur);
	initialScore.score.do({arg m, n;
		grushaScore.add(m);
	});


	grushaScore.sort;

	//
	// Rendering
	//
	grushaScore.recordNRT("temposc-trashme".resolveRelative, "grusha.aif".resolveRelative, duration: songDur+32);

};

)