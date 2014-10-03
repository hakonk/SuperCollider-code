/*
 * Håkon Knutzen, 2013
 * See Master's Thesis (link below) for more details
 * http://urn.nb.no/URN:NBN:no-41730
 * Code licensed under GNU GPL 3
*/

( // instatiate libmapper device and create outputs
a = MapperDevice.new;
b = a.addOutput('/toPwm', 1, $i, 'PWM', 0, 255);
c = a.addOutput('/toPwm2', 1, $i, 'PWM', 0, 255);
d = a.addOutput('/toPwm3', 1, $i, 'PWM', 0, 255);
e = a.addOutput('/toPwm4', 1, $i, 'PWM', 0, 255);
h = a.addOutput('/toPwm5',1,$i,'PWM',0,255);
f = a.addInput('/leftRight', 1, $i,'bool',0,1,{
	arg signame, instanceid, value;
	value.postln; if(value == 0, {~lr.play},{~rl.play});});
g = a.addInput('/tapsIn', 1, $i,'bool',0,1,{
	arg signame, instanceid, value;
	value.postln; if(value == 0, {~bwpc.play},{~pcbw.play});});
~debugIn = a.addInput('/debugIn',1,$i,'PWM',0,255, {
	arg signame, instanceid, value;
	"debug:".post; value.postln;
});
)

( //panic button kill vibration
b.update(0);
c.update(0);
d.update(0);
e.update(0);
h.update(0);
)
//(
//Env.cutoff(1, 255, \sqr).asSignal(70).round(1).addAll([0,0,0,0,0]).plot('sqrt envelope',discrete: true,minval:0,maxval:255);
//Env.cutoff(1, 255, \sqr).asSignal(70).round(1).reverse.addAll([0,0,0,0,0]).plot('reverse sqrt envelope',discrete: true,minval:0,maxval:255);
//)
(
//~foo = (0..255).add(0); // linear ramp from 0-255
~foo = Env.new([0,255],[1,1],curve:'lin').asSignal(70).round(1).add(0).add(0).add(0);
~percArray = ~foo.reverse;
~globalWait = (1/200); // freq of tactile signal (update rate) should have pwm freq much higher than this
~level = 255; // peaklevel for percussive envelope
//~percArray = Env.perc(level: ~level).asSignal(255).round(1);


~bup = Routine{~foo.do{arg in; b.update(in); ~globalWait.wait}; ~bup.yieldAndReset;};
~cup = Routine{~foo.do{arg in; c.update(in);~globalWait.wait}; ~cup.yieldAndReset;};
~dup = Routine{~foo.do{arg in; d.update(in); ~globalWait.wait}; ~dup.yieldAndReset;};
~eup = Routine{~foo.do{arg in; e.update(in); ~globalWait.wait}; ~eup.yieldAndReset;};
~hup = Routine{~foo.do{arg in; h.update(in); ~globalWait.wait}; ~hup.yieldAndReset;};

~bdown = Routine{~foo.reverse.do{arg in; b.update(in);~globalWait.wait}; ~bdown.yieldAndReset;};
~cdown = Routine{~foo.reverse.do{arg in; c.update(in);~globalWait.wait}; ~cdown.yieldAndReset;};
~ddown = Routine{~foo.reverse.do{arg in; d.update(in); ~globalWait.wait}; ~ddown.yieldAndReset;};
~edown = Routine{~foo.reverse.do{arg in; e.update(in); ~globalWait.wait}; ~edown.yieldAndReset;};
~hdown = Routine{~foo.reverse.do{arg in; h.update(in); ~globalWait.wait}; ~hdown.yieldAndReset;};

~bsdown = Routine{~percArray.do{arg in; b.update(in); ~globalWait.wait}; ~bsdown.yieldAndReset;};
~csdown = Routine{~percArray.do{arg in; c.update(in); ~globalWait.wait}; ~csdown.yieldAndReset;};
~dsdown = Routine{~percArray.do{arg in; d.update(in); ~globalWait.wait}; ~dsdown.yieldAndReset;};
~esdown = Routine{~percArray.do{arg in; e.update(in); ~globalWait.wait}; ~esdown.yieldAndReset;};
~hsdown = Routine{~percArray.do{arg in; h.update(in); ~globalWait.wait}; ~hsdown.yieldAndReset;};

~bsup = Routine{~percArray.reverse.do{arg in; b.update(in);~globalWait.wait}; ~bsup.yieldAndReset;};
~csup = Routine{~percArray.reverse.do{arg in; c.update(in);~globalWait.wait}; ~csup.yieldAndReset;};
~dsup = Routine{~percArray.reverse.do{arg in; d.update(in); ~globalWait.wait}; ~dsup.yieldAndReset;};
~esup = Routine{~percArray.reverse.do{arg in; e.update(in);~globalWait.wait}; ~esup.yieldAndReset;};
~hsup = Routine{~percArray.reverse.do{arg in; h.update(in); ~globalWait.wait}; ~hsup.yieldAndReset;};

~bwpc = Routine{~bdown.play;~cup.play;~bwpc.yieldAndReset;}; // from bottom wrist to palm center
~pcbw = Routine{~bup.play;~cdown.play;~pcbw.yieldAndReset;}; // from palm center to bottom wrist
~lr = Routine{~edown.play;~dup.play;~lr.yieldAndReset;}; // left to right
~rl = Routine{~eup.play;~ddown.play;~rl.yieldAndReset;}; // right to left
~bwth = Routine{~hup.play;~bdown.play;~bwth.yieldAndReset;}; // bottom wrist to top hand
~thbw = Routine{~hdown.play;~bup.play;~thbw.yieldAndReset;}; // top hand to bottom wrist
~lbwpc = Routine{~bdown.play;~cup.play;~esup;~lbwpc.yieldAndReset;}; // from bottom wrist to palm center + left
~lpcbw = Routine{~esdown;~bup.play;~cdown.play;~lpcbw.yieldAndReset;}; // from palm center + left to bottom wrist
~rbwpc = Routine{~bdown.play;~cup.play;~dsup;~rbwpc.yieldAndReset;}; // from bottom wrist to palm center + right
~rpcbw = Routine{~dsdown;~bup.play;~cdown.play;~rpcbw.yieldAndReset;}; // from palm center + right to bottom wrist

)
// attempt to create apparent motion
//
~bwpc.play; // from bottom wrist to palm center
~pcbw.play;// from palm center to bottom wrist
~lr.play; // left to right
~rl.play;// right to left
~bwth.play; // bottom wrist to top hand
~thbw.play; // top hand to bottom wrist
~lbwpc.play; // from bottom wrist to palm center + left
~lpcbw.play; // from palm center + left to bottom wrist
~rbwpc.play; // from bottom wrist to palm center + right
~rpcbw.play; // from palm center to bottom wrist
~esdown.play

(
// from palm center to bottom wrist
~bup.play;
~esdown.play;
~cdown.play;
)

(
// from palm center to bottom wrist
~bup.play;
~esdown.play;
~cdown.play;
)

(
// from palm center to bottom wrist
~bup.play;
~esdown.play;
~cdown.play;
)

