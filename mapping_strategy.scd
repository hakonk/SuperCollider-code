/*
 * Håkon Knutzen, 2013
 * See Master's Thesis (link below) for more details
 * http://urn.nb.no/URN:NBN:no-41730
 * Code licensed under GNU GPL 3
 * Dependencies: https://github.com/mzadel/libmapper-sc
 */

// used to change the grid "spread"
~boarderDivisor = 300;
(
// variables used in processing of the Vicon Motion Capture input
~boarderFreq = 0;
~croTimb = 0;
~croAmp = 0;
~sawCutoff = 0;
~amMod = 0;
~impFreq = 0;

//libmapper devices
~dev1 = MapperDevice.new('Vicon');
~dev2 = MapperDevice.new('SuperCollider');

// Vicon outputs
~vic1 = ~dev1.addOutput('/markerX', 1, $f, 'pos', -2000, 2000);
~vic2 = ~dev1.addOutput('/markerY', 1, $f, 'pos', -2000, 2000);
~vic3 = ~dev1.addOutput('/markerZ', 1, $f, 'pos', 300, 1800);
~vic4 = ~dev1.addOutput('/markerXvelAbs', 1, $f, 'vel', 0,10);
~vic5 = ~dev1.addOutput('/markerYvelAbs', 1, $f, 'vel', 0,10);
~vic6 = ~dev1.addOutput('/markerZvelAbs', 1, $f, 'vel', 0,10);

// Supercollider libmapper inputs
~amModIn = ~dev2.addInput('/amModFreqCrotale',1, $f, 'Hz', 7, 20, {
		|signame, instanceid, value|
		~amMod = value});
~croTimbIn = ~dev2.addInput('/crotaleTimbre',1, $f, 'timb', 0, 3, {
		|signame, instanceid, value|
		~croTimb = value;});
~setup4ImpFreq = ~dev2.addInput('/impBurstFreq',1, $f, 'Hz', 3, 15, {
		|signame, instanceid, value|
		~impFreq = value;});
~croAmpIn = ~dev2.addInput('/crotaleAmp',1, $f, 'amp', 0, 1, {
		|signame, instanceid, value|
		~croAmp = value;});
~inDebug = ~dev2.addInput('/inDebug',1, $f, 'any',0,1,{
	|signame, instanceid, value|
	postln("debug: " + value);});

// for debugging
~prevDebug = 0;
~croDebug = ~dev2.addInput('/crotaleDebug', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	if(value.isNegative && ~prevDebug.isPositive,
		{postln("croamp: " + ~croAmp + "croTimb: " + ~croTimb + "boarderFreq: " + ~boarderFreq)}
	,{});
	~prevDebug = value;
});

// The function defined in the input, triggers the tactile synth whenever a threshold is
// crossed. Also the frequency variable is set such that when the audio synth is
// triggered, the frequency of that synth is set equal to value of ~boarderFreq.

~prev2 = 0;
~boarderTactSin = ~dev2.addInput('/boarderSynthTactImp', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	var func,modvalue;
	modvalue = (value/~boarderDivisor).round(1).mod(8);
	if((modvalue - ~prev2) != 0, {case
	{modvalue == 0}{~boarderFreq = 60; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 1}{~boarderFreq = 63; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 2}{~boarderFreq = 65; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 3}{~boarderFreq = 67; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 4}{~boarderFreq = 70; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 5}{~boarderFreq = 72; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 6}{~boarderFreq = 75; Synth(\tactImpSynthBoarder,[\amp,1]);}
	{modvalue == 7}{~boarderFreq = 77; Synth(\tactImpSynthBoarder,[\amp,1]);}
	},{});
	~prev2 = modvalue;
});

// control of sound and sinusoidal vibrotactile feedback
~prevVal1 = 0;
~setup1 = ~dev2.addInput('/sineOnlyCrotale', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	if(value.isNegative && ~prevVal1.isPositive,
		{Synth(\PMCrotaleMod,[\midi,~boarderFreq,\varpar,~croTimb,\amp,~croAmp,\tactAmp,0]);
		Synth(\tactSin,[\freq,~boarderFreq,\amp,~croAmp]);
	},{});
	~prevVal1 = value;
});

// control of sound and vibrotactile feedback that is created by filtering the audio signal
~prevVal2 = 0;
~setup2 = ~dev2.addInput('/sameSoundCrotale', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	if(value.isNegative && ~prevVal2.isPositive,
		{Synth(\PMCrotaleMod,[\midi,~boarderFreq,\varpar,~croTimb,\amp,~croAmp,\tactamp,30]);
	},{});
	~prevVal2 = value;
});

// control of sound and vibrotactile feedback that is created with amplitude modulation
~prevVal3 = 0;
~setup3 = ~dev2.addInput('/amTactCrotale', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	if(value.isNegative && ~prevVal3.isPositive,
		{Synth(\PMCrotaleMod,[\midi,~boarderFreq,\varpar,~croTimb,\amp,~croAmp,\tactAmp,0]);
			Synth(\tactAM,[\carfreq,~boarderFreq,\amp,~croAmp,\modfreq,~amMod]);
	},{});
	~prevVal3 = value;
});

// control of sound and impulse burst vibrotactile feedback
~prevVal4 = 0;
~setup4 = ~dev2.addInput('/impBurstCrotale', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	if(value.isNegative && ~prevVal4.isPositive,
		{Synth(\PMCrotaleMod,[\midi,~boarderFreq,\varpar,~croTimb,\amp,~croAmp,\tactAmp,0]);
			Synth(\tactImpSynth,[\imppar,~impFreq,\amp,~croAmp,\freq,~boarderFreq]);
	},{});
	~prevVal4 = value;
});

// control of sound (drumloop) and vibrotactile feedback that is created by filtering the audio
~prevVal5 = 0;
~drumbool = false;
~drumloop = ~dev2.addInput('/drumloopPure', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	case
	{value.isNegative && ~prevVal5.isPositive}{a = Synth(\drumloop,[\bufnum,~drumBuffer,\loop,1]);~drumbool = true;}
	{value.isPositive && ~prevVal5.isNegative}{a.free; ~drumbool = false;};
	~prevVal5 = value;
});

// control of sound (drumloop) and vibrotactile feedback that is created by extracting onsets of the audio signal
~prevVal6 = 0;
~drumbool2 = false;
~drumloop2 = ~dev2.addInput('/drumloopOnsets', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	case
	{value.isNegative && ~prevVal6.isPositive}{a = Synth(\drumloopOnsets,[\loop,1,\bufnum,~drumBuffer,\gain,3]);~drumbool2 = true;}
	{value.isPositive && ~prevVal6.isNegative}{a.free; ~drumbool2 = false;};
	~prevVal6 = value;
});

// other inputs for drum loop
~drumResFreq = ~dev2.addInput('/drumResFreq',1,$f,'Hz',50,12000,{
	|signame,instanceid, value|
	if (~drumbool,{a.set(\rfreq,value)},{})
});
~drumResFreq2 = ~dev2.addInput('/drumResFreq2',1,$f,'Hz',50,12000,{
	|signame,instanceid, value|
	if (~drumbool2,{a.set(\rfreq,value)},{})
});
~drumRate = ~dev2.addInput('/drumRate',1,$f,'rate',-1,2,{
	|signame,instanceid, value|
	if (~drumbool,{a.set(\rate,value)},{})
});
~drumRate2 = ~dev2.addInput('/drumRate2',1,$f,'rate',-1,2,{
	|signame,instanceid, value|
	if (~drumbool2,{a.set(\rate,value)},{})
});

~drumOnsetCarFreq = ~dev2.addInput('/drumOnsetCarFreq',1,$f,'Hz',15,500,{
	|signame,instanceid, value|
	if (~drumbool2,{a.set(\carfreq,value)},{})
});
~drumOnsetModFreq = ~dev2.addInput('/drumOnsetModFreq',1,$f,'rate',1,30,{
	|signame,instanceid, value|
	if (~drumbool2,{a.set(\modfreq,value)},{})
});

// not used in thesis
~prevVal7 = 0;
~drumbool3 = false;
~drumloop3 = ~dev2.addInput('/drumloopPreview', 1, $f, 'pos', -2000, 2000,{
	|signame, instanceid, value|
	case
	{value.isNegative && ~prevVal6.isPositive}{
		a = Synth(\drumloopPreview,[\loop,1,\bufnum]);
		~previewSynth.set(\amp,0);
		~drumbool3 = true;}
	{value.isPositive && ~prevVal6.isNegative}{
		a.free;
		~previewSynth.set(\amp,1);
		~drumbool3 = false};
	~prevVal6 = value;
});

~drumPreviewAm = ~dev2.addInput('/drumPreviewAMCar',1,$f,'Hz',15,400,{
	|signame,instanceid, value|
	if(~drumbool3,~previewSynth.set(\carfreq,value),{});
});

~drumPreviewMod = ~dev2.addInput('/drumPreviewAMMod',1,$f,'Hz',1,17,{
	|signame,instanceid, value|
	if(~drumbool3,~previewSynth.set(\modfreq,value),{});
});

~drumResFreq3 = ~dev2.addInput('/drumResFreq3',1,$f,'Hz',50,12000,{
	|signame,instanceid, value|
	if (~drumbool3,{a.set(\rfreq,value)},{})
});
~drumRate3 = ~dev2.addInput('/drumRate3',1,$f,'rate',-1,2,{
	|signame,instanceid, value|
	if (~drumbool3,{a.set(\rate,value)},{})
});
)

// trace OSC input
OSCFunc.trace(true);
OSCFunc.trace(false);
// record marker position data
~fileWriteX = File("markerX","w");
~fileWriteY = File("markerY","w");
~fileWriteZ = File("markerZ","w");
~fileWriteYVel = File("markerYVel","w");

// setting up listener
(
n = NetAddr.new("192.168.1.101", 1297);
~velPrevY = 0;
// function that responds to Vicon input and sends both the distance value and the
// marker position values to the libmapper device outputs.
OSCdef.new(\test, {|msg, time, addr, recvPort|
	var vel;
	~vic1.update(msg[1]);~vic2.update(msg[2]);~vic3.update(msg[3]);
	vel = abs(msg[2] - ~velPrevY);
	~vic5.update(vel);
	if(~writeBool, {
		~fileWriteX.write(msg[1] + "\n");
		~fileWriteY.write(msg[2] + "\n");
		~fileWriteZ.write(msg[3] + "\n");
		~fileWriteYVel.write(vel + "\n");
	},{});
	~velPrevY = msg[2];
				},
	'/cross/Marker2/P',n);
)

// boolean used to trigger recording of mocap data
~writeBool = false;
~writeBool = true;
//closing and freeing files with the mocap data
~fileWriteX.close;
~fileWriteY.close;
~fileWriteZ.close;
~fileWriteYVel.close;
~fileWriteX.free;
~fileWriteY.free;
~fileWriteZ.free;
~fileWriteYVel.free;

// buffers for recording of audio and tactile signal
~buffer1.free;
~buffer2.free;
~recordLength = 20;
~buffer1 = Buffer.alloc(s, 44100 * ~recordLength,1);
~buffer2 = Buffer.alloc(s, 44100 * ~recordLength,1);

(
~buffer1.write(sampleFormat: 'int24',headerFormat: "aiff");
thisProcess.platform.recordingsDir +/+ "buf1_" ++ Date.localtime.stamp ++ ".aiff";
)

// synths used for recording
SynthDef(\recordBuffersLeft, {
	|buf|
	var in = In.ar(0,1);
	RecordBuf.ar(in,buf,loop:0,doneAction:2);
}).add;
SynthDef(\recordBuffersRight, {
	|buf|
	var in = In.ar(1,1);
	RecordBuf.ar(in,buf,loop:0,doneAction:2);
}).add;

// function to trigger recording of audio, tactile signal and mocap data
fork({
	~writeBool = true;
	Synth(\recordBuffersLeft,[\buf,~buffer1]);
	Synth(\recordBuffersRight,[\buf,~buffer2]);
	20.wait;
	~writeBool = false;
})

