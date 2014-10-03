/*
 * Håkon Knutzen, 2013
 * See Master's Thesis (link below) for more details
 * http://urn.nb.no/URN:NBN:no-41730
 * Code licensed under GNU GPL 3
 * Dependencies: https://github.com/mzadel/libmapper-sc
 *
 * Filter coefficients for the biquad filters for the vibrotactile synths are obtained from
 * Birnbaum's Max MSP patch for the Breakflute: http://idmil.org/theses
 *
 * The synth PMCrotaleMod is based on Cottle's synth called PMCrotale:
 * see Chapter 1, The SuperCollider book, http://supercolliderbook.net/
 */



(//execute here to store all synths
~tactileGain = 3;
~drumBuffer = Buffer.read(s, /*enter directory/filename here*/);
~onsetBuffer = Buffer.alloc(s,512);

/*
SynthDef(\tactPreview, {|carfreq = 15,chan = 1,modfreq = 1,amp|
	var insig = SinOsc.ar(carfreq,mul:1)*SinOsc.ar(modfreq,mul: 0.5,add:0.5),outsig,env;
	outsig = SOS.ar(SOS.ar(insig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526);
	Out.ar(chan,outsig*amp);
}).add;
*/
/*
SynthDef(\drumloopPreview, {| out = 0,loop = 0,rate = 1,rfreq = 1000,chan1 = 0,chan2 = 1 |
	var tactout, audout,bufnum;
	bufnum = ~drumBuffer;
	audout = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction:2,loop:loop,rate:rate);
	audout = RLPF.ar(audout,rfreq);
    Out.ar(0, audout);
}).add;
*/

//Soundgenerator for prototype 2.
SynthDef(\drumloop, {| out = 0,loop = 0,rate = 1,rfreq = 1000,chan1 = 0,chan2 = 1 |
	var tactout, audout,bufnum;
	bufnum = ~drumBuffer;
	audout = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction:2,loop:loop,rate:rate);
	audout = RLPF.ar(audout,rfreq);
	tactout = LPF.ar(SOS.ar(SOS.ar(audout,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526),800);
    Out.ar(0, [Out.ar(0,audout*0.5), Out.ar(1,tactout*~tactileGain)]);
}).add;

//soundgen for prototype 2 with onset detection
SynthDef(\drumloopOnsets,{
	|rfreq = 1000,modfreq=5,carfreq=100,rate = 1|
    var sig, chain, onsets, pips, synthsig,env,tactout,audout;

    sig = PlayBuf.ar(1, ~drumBuffer, BufRateScale.kr(~drumBuffer), loop: 1,rate:rate);
	audout = RLPF.ar(sig,rfreq);
    chain = FFT(~onsetBuffer, sig);
    onsets = Onsets.kr(chain, 0.7, \mkl);
	env = EnvGen.kr(Env.perc(0.01,0.2),gate: onsets);
	synthsig = SinOsc.ar(carfreq) * SinOsc.ar(modfreq,mul:0.5,add:0.5);
    synthsig = synthsig*env;
	tactout = SOS.ar(SOS.ar(synthsig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526);
    Out.ar(0, [Out.ar(0,audout*0.5), Out.ar(1,tactout*~tactileGain)]);
}).add;

// vibrotactile AM synth
SynthDef(\tactAM, {|carfreq,modfreq,amp,chan = 1|
	var insig = SinOsc.ar((carfreq.midicps)/2,mul:abs(amp))*SinOsc.ar(modfreq,mul: 0.5,add:0.5), outsig,env;
	env = EnvGen.kr(Env.perc(0.05,0.6),doneAction:2,levelScale:~tactileGain);
	outsig = LPF.ar(SOS.ar(SOS.ar(insig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526),800);
	Out.ar(chan,outsig*env);
}).add;

// vibrotactile sinusoidal synth
SynthDef(\tactSin, {|freq,amp,chan = 1|
	var insig = SinOsc.ar((freq.midicps)/2,mul:abs(amp)), outsig,env;
	env = EnvGen.kr(Env.perc(0.05,0.6),doneAction:2,levelScale:~tactileGain);
	outsig = SOS.ar(SOS.ar(insig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
			0.980631, -1.922495, 0.941894, 1.922495, -0.922526);
	Out.ar(chan,outsig*env);
}).add;

// vibrotactile synths for grid feedback
SynthDef(\tactsineSynth,{
	|freq,chan = 1|
	var insig = SinOsc.ar(freq.midicps/2),outsig,env;
	env = EnvGen.kr(Env.perc(0.05,0.02),doneAction:2,levelScale:~tactileGain/1.5);
	outsig = SOS.ar(SOS.ar(insig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
			0.980631, -1.922495, 0.941894, 1.922495, -0.922526)*env;
	Out.ar(chan,outsig);
}).add;
SynthDef(\tactImpSynthBoarder,{
	|amp = 1,chan = 1|
	Out.ar(chan,RLPF.ar(Impulse.ar(1)*EnvGen.ar(Env.new([1,0],[0.1,0.1]),doneAction:2,levelScale:50)*amp,250));
}).add;

// burst synthesis
SynthDef(\tactImpSynth,{
	|imppar,amp,time=1,freq,chan=1|
	var insig,outsig,env,env2;
	env2 = EnvGen.kr(Env.new([imppar,0],[time,time],\lin));
	insig = Impulse.ar(env2);
	env = EnvGen.kr(Env.new([0,1,1,0],[0,time,0.01],\exp),levelScale: 100, doneAction:2);
	insig = RLPF.ar(insig,freq.midicps,2);
	outsig = LPF.ar(SOS.ar(SOS.ar(insig,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526),800);
	Out.ar(chan,outsig*env*abs(amp));
}).add;

// audio synth prototype 1. Tactile synth routed to the right channel
SynthDef(\PMCrotaleMod, {
    |midi = 60, varpar = 1, art = 1,amp = 0.9,chan = 0,tactamp = 0|
    var env, out, mod, freq,tactout;
    freq = midi.midicps;
    env = Env.perc(0, art);
        mod = 5 + (1 / IRand(2, 6));
    out = PMOsc.ar(freq, mod*freq,
        pmindex: EnvGen.kr(env, timeScale: art, levelScale: varpar),
            mul: EnvGen.kr(env, timeScale: art, levelScale: 0.5));
    out = out * EnvGen.kr(env, timeScale: 1.3 * art,
        levelScale: Rand(0.1, 0.5), doneAction: 2);
	tactout = LPF.ar(SOS.ar(SOS.ar(out,0.874225, -1.711427, 0.838289, 1.711427, -0.712514),
		0.980631, -1.922495, 0.941894, 1.922495, -0.922526),800);
	Out.ar(chan, Pan2.ar(out*abs(amp),-1,1) + Pan2.ar(tactout,1,tactamp));
}).add;
)