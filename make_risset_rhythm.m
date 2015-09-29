%% Building blocks

% Set sampling frequency for the project
fs = 44104/4; % sampling frequency, in Hz

% Generate timeline of s seconds
tlengths = @(s) linspace(0,s,round(fs*s));

% Create noise-generation building blocks:

% 1 - noise generator
% noisewave(Amplitude, length in seconds)
noisewave = @(A,len) A*rand(1,len);
% 2 - hihat generator (filtered noise)
% hihatwave(Amplitude,length in seconds, filter
% constant)
hihatwave = @(A,len,hihatalpha) A*filter([hihatalpha,-hihatalpha],[1,hihatalpha],rand(1,len));

% 3 - harmonic wave generator (used to make bass drum bloops)
% harmwave(Amplitude, length in seconds)
% Frequency is fixed at good frequency to make a bassdrum sound.
nharms = 10;
freq = 100;
harmonic_grid = zeros(nharms,fs);
harmonic_spectrum = logspace(10,5,nharms);
for i=1:nharms,
    harmonic_grid(i,:) = 1/sum(harmonic_spectrum) * harmonic_spectrum(i) * sin(2*pi*freq*i*tlengths(1));
end
harmonic_grid = sum(harmonic_grid) * (1/max(sum(harmonic_grid)));
harmwave = @(A,len) A*harmonic_grid(1:len);

% Generate a signal-scale ADSR envelope based on input parameters, a matrix
% with values: [A, D, S, R, amplitude of sustain]
paramsADSR = @(adsr_) [linspace(0,1,round(fs*adsr_(1))) linspace(1,adsr_(5),round(fs*adsr_(2))) linspace(adsr_(5),adsr_(5),round(fs*adsr_(3)))  linspace(adsr_(5),0,round(fs*adsr_(4)))];

% Generate an envelope that interpolates between two ADSR profiles
percentADSR = @(adsr1,adsr2,perc1) paramsADSR(adsr1 - perc1*(adsr1-adsr2));

% Generate a snare, bass or hihat sound with a particular volume and envelope.
% (There is some manual setting of the amplitudes here because
% perceptually, the noisy generators are a lot louder than the bass.
generateSnare = @(vol,env) noisewave(vol*0.1, length(env)) .* env;
generateBass = @(vol,env) harmwave(vol,length(env)) .* env;
generateHihat = @(vol,env,hihatalpha) hihatwave(vol*0.2,length(env),hihatalpha) .* env;

% Generate a hybrid of the three sounds above within a single envelope.
generateHybrid = @(levels,env,hihatalpha) generateBass(levels(1),env) + generateSnare(levels(2),env) + generateHihat(levels(3),env,hihatalpha);

% Here are the parameters to make some good sounds:
adsr_bass = [0.01,0.07,0,0.3,0.05];
adsr_snare = [0.001,0.05,0,0.14,0.3];
adsr_openhihat = [0.05,0.03,0,1,.2];
adsr_closedhihat = [0.01,0.03,0,0,0];
hihatalpha = 0.9;


%% Make a rhythm

% Set initial rhythm of 16th notes in BPM:
T1 = 200;
% Set the length of the loop in 16th notes:
nbeats = 16*4;

% % Create beat onsets with a linear decrease in the beat period:
% % makeBeatOnsets = @(tempo1,tempo2,nbeats) [0, cumsum(linspace(60/tempo1,60/tempo2,nbeats))];

% Actually that sounds bad!! For tempo to increase at a rate perceived to
% be uniform, we instead interpolate exponentially.
makeBeatOnsets = @(tempo1,tempo2,nbeats) [0, cumsum(60./((tempo2/tempo1).^([0:nbeats-1]/nbeats) * tempo1))];

% We will increase from the original tempo to twice the tempo in one loop.
beatOnsets = makeBeatOnsets(T1,T1*2,nbeats);

% We create an additional vector to count the nth sixteenth note within
% each measure.
beatIndices = mod(1:length(beatOnsets),16);
beatIndices(beatIndices==0) = 16;
volIndices = [1 0 0 0 0 0 0 0, 1 0 0 0 0 0 0 0;      % bass
              1 0 0 0 1 0 0 0, 1 0 0 0 1 0 0 0;      % snare
              1 0 1 0 1 0 1 0, 1 0 1 0 1 0 1 0;      % hihat
              1 1 1 1 1 1 1 1, 1 1 1 1 1 1 1 1];     % dissipating hihat

% We will transition from A to B in each loop
ab_trans = 1-linspace(0,1,length(beatOnsets));
timeline = zeros(4,round(fs*(1+max(beatOnsets))));

% Generate all percussion in the same sweep:
for i=1:length(beatOnsets)-1,
    ab = ab_trans(i);
    indx = beatIndices(i);
    
    % Create instrument envelopes
    incumbentBassEnv = paramsADSR(adsr_bass);
    bassEnv = percentADSR(adsr_bass,adsr_snare,1-ab);
    snareEnv = percentADSR(adsr_snare,adsr_closedhihat,1-ab);
    hihatEnv = paramsADSR(adsr_closedhihat);
    
    % Generate instrument sounds
    incumbentBassSound = generateBass(volIndices(1,indx)*(1-ab),incumbentBassEnv);
    bass2snareSound = generateHybrid(volIndices(2,indx)*[ab,1-ab,0],bassEnv,hihatalpha);
    snare2hihatSound = generateHybrid(volIndices(3,indx)*[0,ab,(1-ab)],snareEnv,hihatalpha);
    hihat2ghostSound = generateHihat(volIndices(4,indx)*ab,hihatEnv,hihatalpha);
    
    % Find longest sound and pad zeros to that
    maxlen = max([length(incumbentBassSound),length(bass2snareSound),length(snare2hihatSound),length(hihat2ghostSound)]);
    incumbentBassSound(length(incumbentBassSound):maxlen)=0;
    bass2snareSound(length(bass2snareSound):maxlen)=0;
    snare2hihatSound(length(snare2hihatSound):maxlen)=0;
    hihat2ghostSound(length(hihat2ghostSound):maxlen)=0;
    
    t1 = max(1,round(beatOnsets(i)*fs));
    t2 = t1+round(maxlen-1);
    timeline(1,t1:t2) = timeline(1,t1:t2)+incumbentBassSound;
    timeline(2,t1:t2) = timeline(2,t1:t2)+bass2snareSound;
    timeline(3,t1:t2) = timeline(3,t1:t2)+snare2hihatSound;
    timeline(4,t1:t2) = timeline(4,t1:t2)+hihat2ghostSound;
end

% Trim the timeline to the intended loop length (otherwise the zero-padding
% breaks the 'seam')
timelineTrimmed = timeline(:,1:round(max(beatOnsets)*fs));

% FULLSEQ gives the full sequence of a bass drum sound accelerating,
% turning into a snare sound, then a hihat sound, then fading to nothing.
fullSeq = reshape(timelineTrimmed',1,[]);
% sound(fullSeq,fs)

% RISSETRHYTHM gives the Risset Rhythm looped 4 times.
rissetRhythm = repmat(sum(timelineTrimmed),1,4);

% RISSETCANON brings out the sequence aspect by producing a canon like so:
% 0---bd--sd--hh--0
%     0---bd--sd--hh--0
%     	  0---bd--sd--hh--0
%             0---bd--sd--hh--0
fullLen = length(fullSeq);
rissetCanon = zeros(1,fullLen*2);
for i=1:4,
    indxs = (1:fullLen)+(i-1)*round(fullLen/4);
    rissetCanon(indxs) = rissetCanon(indxs) + fullSeq;
end

%% Play!
% sound(fullSeq,fs)
sound(rissetRhythm,fs)
% sound(rissetCanon,fs)

%% Write to disk!
% wavwrite(fullSeq,fs,'fullSeq.wav');
wavwrite(rissetRhythm,fs,'rissetRhythm.wav');
% wavwrite(rissetCanon,fs,'rissetCanon.wav');