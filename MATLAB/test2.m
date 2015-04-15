%% Test file 2
% Author: Alex Gabourie

%% Testing Finding Direction

close all


%Ensures we have the correct dataset to call the PhaseShift function
%if(exist('Sample_Antenna_Input.mat','file')==0)
    run('Sample_input_signal2');
%end

%close all
%clear
%load relevant data
load('Sample_Antenna_Input2.mat');

% find Phase shift between two sample signals
% First signal is reference signal
bkr = zeros(1,4);
bkr(1) = PhaseShift(real(E(1,:)), t, omega);
bkr(2) = PhaseShift(real(E(2,:)), t, omega);
bkr(3) = PhaseShift(real(E(3,:)), t, omega);
bkr(4) = PhaseShift(real(E(4,:)), t, omega);

%put the phases in the correct order and set the phase for first antenna to
%be 0 for the system of equations to be solved.
bkr = OrderPhase(bkr);

%The bkr values we have now are actually beta*k*r, so we need to divide by
%beta
kr = -bkr/beta;
r_n = r_all'*r_all;
knew = r_n\(r_all'*kr');
knew = knew/norm(knew);

figure;
quiver(0,0,knew(1),knew(2));
hold on;
scatter(r_all(:,1), r_all(:,2));
title('Ideal Signal Guessed Direction');
xlabel('x');
ylabel('y');

%% Second Stage Testing
%
% In this section, I will append the correct signals together in the way
% that our switching circuit will when running the real code. This means
% taking 2ms clips from each antenna in the order of 1,2,3,4. On the plot
% of the antenna locations this is starting at the origin and working
% counter clockwise. My plan is to use the 2ms to determine how much of a
% phase shift I would expect for the other antennas to have when I switch
% to them.

tVecIdx = zeros(1,4);

%not best code, just want something to work
%antenna 1 to 2 transition
for i=1:length(t)
    if t(i) > .002
        tVecIdx(1) = i;
        break;
    end
end
%antenna 2 to 3 transition
for i=tVecIdx(1):length(t)
    if t(i) > .004
        tVecIdx(2) = i;
        break;
    end
end   
%antenna 3 to 4 transition
for i=tVecIdx(2):length(t)
    if t(i) > .006
        tVecIdx(3) = i;
        break;
    end
end   
%antenna 4 to end transition
for i=tVecIdx(3):length(t)
    if t(i) > .008
        tVecIdx(4) = i;
        break;
    end
end     
    
% compose the antenna signal based on the time the antenna readings come in

Ein = [real(E(1,1:tVecIdx(1)-1)), real(E(2,tVecIdx(1):tVecIdx(2)-1)),...
    real(E(3,tVecIdx(2):tVecIdx(3)-1)),real(E(4,tVecIdx(3):tVecIdx(4)-1))];

Eref = zeros(1,length(Ein));
for m=1:length(Ein)
        %Sine wave. Makes phase be zero
        Eref(m) = real(exp(1i*(omega*t(m)-pi/2)));
end

%Plot the signals coming in from the antenna vs the reference signal
figure;
plot(Ein,'b');
hold on;
plot(Eref,'r');
axis([0 length(Eref) -4 4]);
    

phsPts = floor(length(Eref)/(5*4));
phsPtMax = length(Eref)-phsPts;

realPhase = zeros(1,phsPtMax);
expPhase = zeros(1,phsPtMax);

for i=1:phsPtMax
    realPhase(i) = PhaseShift(real(Eref(i:(i+phsPts-1))),t(1:(phsPts))...
        ,omega);
    expPhase(i)= PhaseShift(real(Ein(i:(i+phsPts-1))),t(1:(phsPts))...
           ,omega);
end

%unwrap phases to get the phase difference plot
realPhase = unwrap(realPhase);
expPhase = unwrap(expPhase);

% Phase differences
phaseDiff = expPhase-realPhase;

figure;
plot(phaseDiff);
title('Phase differences');    
ylabel('Radians');

% At this point we should see the phase differences that correspond to a
% particular direction and that resembles reality to a decent degree. Since
% this is an idealized situation, our phase difference plots have some
% flat regions from which we can sample from.


% Obviously this needs to be done differently, but it is for proof of
% concept
bkr = [phaseDiff(32), phaseDiff(141), phaseDiff(235), phaseDiff(335)];

%put the phases in the correct order and set the phase for first antenna to
%be 0 for the system of equations to be solved.
bkr = OrderPhase(bkr);

%The bkr values we have now are actually beta*k*r, so we need to divide by
%beta
kr = -bkr/beta;
r_n = r_all'*r_all;
knew = r_n\(r_all'*kr');
knew = knew/norm(knew);

figure;
quiver(0,0,knew(1),knew(2));
hold on;
scatter(r_all(:,1), r_all(:,2));
title('Realistic Guessed Direction');
xlabel('x');
ylabel('y');

%% Notes
% I need to discuss with Tom how the signals are being recorded because I
% still have a little confusion. Its the demodulation that trips me up
% because in the 20 ms timeframe I would expect to have larger phase
% differences between the signals of each antenna. Since the signal is
% demodulated to ~2551 Hz the phase differences are miniscule, but luckily,
% with double precision numbers, enough to capture in this simulation.
% However, this worries me for real testing where small inaccuracies may
% mess with the entire phase difference determinations
    