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
var window, textView, startButton;
var choosePathDialog, choosePathAlert, msg;
var currentDir;
var renderFunction, postMessageFunc;

// GUI grid unit
var ggU = 18;

window = Window.new("microscale Renderer", Rect((Window.screenBounds.width/2)-(ggU*21/2),300,ggU*21,ggU*18), false);

textView = TextView.new;
textView.editable = false;
postMessageFunc = {arg message;
	textView.string = textView.string ++ Date.getDate.hourStamp + "     " ++ message ++ "\n";
};

startButton = Button.new.states_([["Start"], ["Processing"]]);

choosePathAlert = Window.new("?",  Rect(Window.screenBounds.width/2-100, 400, 200, 100),false);
choosePathAlert.userCanClose = false;

s.waitForBoot({
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

		//
		// The fadeout SynthDef
		//
		SynthDef("microscale-fadeout", {arg buf, fadeTime, fadeCurve;
			var env, out;
			env = EnvGen.ar(Env([0, 1, 1, 0], [0, (BufDur.kr(buf)-fadeTime), fadeTime], fadeCurve));
			out = PlayBuf.ar(2, buf, BufRateScale.kr(buf), doneAction: 2) * env;
			Out.ar(0, out);
		}).load(s);

		// score that contains all the buffers
		initialScore = Score.new;

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



		renderFunction = {arg button;
			Routine({
				var cond = Condition.new;
				// fadeout
				var nonFadedBuf, bufDur, foscore, fobuf, fosynth;
				var previousSampleHolder = Array.fill(6, {\0});
				var tempOSCFileName = "temposc";










				// если луп, то просто вместо тишины возвращает предыдуший сэмпл



				sampleChooserFunc = {arg songTitle, voiceNumber;
					var newSampleSymbol = (songTitle++0).wchoose(probs[songTitle]).asSymbol;

					while({(newSampleSymbol == previousSampleHolder[voiceNumber]) && (newSampleSymbol !== \0)}, {
						// look up for another letter while
						// match is the same as the previous one,
						var matchingsOnlyProbs = probs[songTitle].clipExtend(songTitle.size).normalizeSum;
						newSampleSymbol = songTitle.wchoose(matchingsOnlyProbs).asSymbol;
					});

					previousSampleHolder[voiceNumber] = newSampleSymbol;

					// return buffer
					samples[songTitle.asSymbol][voiceNumber][newSampleSymbol];
				};

				//
				// [grusha]
				//

				postMessageFunc.value("generating score for [grusha]");

				TempoClock.default.tempo = 60/59;

				songDur = rrand(700, 732);

				grushaPattern = Ppar([
					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 0)}),
						\dur, Pseq([6], songDur/2)
					),

					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 1)}),
						\dur, Pseq([6], songDur/2)
					),

					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 2)}),
						\dur, Pseq([6], songDur/2)
					),

					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 3)}),
						\dur, Pseq([6], songDur/2)
					),

					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 4)}),
						\dur, Pseq([6], songDur/2)
					),

					Pbind(\instrument, "microscale-sampler",
						\buf, Pfunc({sampleChooserFunc.value("grusha", 5)}),
						\dur, Pseq([6], songDur/2)
					)
				], 1);

				grushaScore = grushaPattern.asScore(songDur);
				initialScore.score.do({arg m, n;
					if(n > 0, {grushaScore.add(m)});
				});

				grushaScore.sort;

				//
				// Rendering
				//

				postMessageFunc.value("rendering [grusha]");
				grushaScore.recordNRT(currentDir++tempOSCFileName, currentDir++"grusha-without-fade.aif", sampleRate: 44100, duration: songDur+32, action: {
					// unblock thread when finished
					cond.unhang;
				});

				//
				// Applying fadeout
				//

				// block the thread (to wait for the non-faded file)
				cond.hang;
				postMessageFunc.value("applying fadeout to [grusha]");

				// reset tempo clock to start fade in the right position
				TempoClock.default.tempo = 1;

				// initialize non-faded buffer just for getting the song duration
				nonFadedBuf = Buffer.read(s, currentDir++"grusha-without-fade.aif", action: {
					// unblock thread
					cond.unhang;
				});
				// stop thread while buffer is initialising
				cond.hang;
				// getting buffer duration
				bufDur = nonFadedBuf.duration;
				// freeing the buffer
				nonFadedBuf.free;

				// Setting up the score
				foscore = Score.new;
				fobuf = Buffer.new;

				foscore.add([0, fobuf.allocReadMsg(currentDir++"grusha-without-fade.aif";)]);

				fosynth = Synth.basicNew("microscale-fadeout");

				foscore.add([0,
					fosynth.newMsg(s, [\buf, fobuf, \fadeTime, 30, \fadeCurve, -3]);
				]);

				// add ending
				foscore.add([bufDur+2, 0]);

				foscore.sort;

				// render the score
				foscore.recordNRT(currentDir++tempOSCFileName, currentDir++"grusha.aif", sampleRate: 44100, action: {
					// remove the temp osc file
					("rm"+currentDir++tempOSCFileName).unixCmd;
					// remove the non-faded file
					("rm"+currentDir++"grusha-without-fade.aif";).unixCmd;

					// unblock the thread
					cond.unhang;
				});

				// block the thread while the rendering process
				cond.hang;

				postMessageFunc.value("[grusha] is generated as grusha.aif");

				button.valueAction = 0;

				Buffer.freeAll;
			});
		};
	};
});


startButton.action = {arg butt;
	var n = 0, processingIndicationRout;

	processingIndicationRout = Routine({
		loop{
			n = (n + 1)%4;
			window.name = window.name ++ ".";
			if(n == 0, {
				window.name = "Processing";
			});
			0.25.wait;
		}
	});

	if(butt.value == 1, {
		// processing indication
		window.name = "Processing";
		butt.enabled = false;

		AppClock.play(processingIndicationRout);

		// render function
		AppClock.play(renderFunction.value(butt));
	}, {
		processingIndicationRout.stop;
		AppClock.clear;
		butt.enabled = true;
		window.name = "microscale Renderer";
	});
};

window.layout = VLayout(textView, startButton);


// choose path alert
choosePathAlert.layout = VLayout(

	{var msg = StaticText.new;
		msg.string = "Choose a directory to where to save the output files";
		msg;
	}.value(),

	{var button = Button.new;
		button.states = [["Choose"]];

		button.action = {arg butt;
			choosePathDialog = FileDialog.new({arg path;
				choosePathAlert.close;
				currentDir = path;
				currentDir = currentDir[0]++"/";
				window.front;
			}, {}, 2);
		};
		button;
	}.value()
);

choosePathAlert.front;

)