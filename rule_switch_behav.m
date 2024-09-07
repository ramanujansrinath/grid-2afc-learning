load('data/exptRecord.mat')
exptRecord = exptRecord([exptRecord.nCorrect]>100);
exptRecord = exptRecord(cellfun(@(x) length(x)==25,{exptRecord.stimOpp_num}) & cellfun(@(x) length(x)==25,{exptRecord.stimRF_num}));
load(['~/Downloads/v4-7a/' exptRecord(50).name '_dense.mat'],'params')

% rule indicated by monkeys actions:
guesses = guess_rule(params);

% identify rule switches
switches = [];
rules = [params.rule];
prev_rule = rules(1);
for i = 1: length(rules)
    r = rules(i); 
    if r ~= prev_rule
        switches(end + 1) = i;
    end
    prev_rule = r;
end

%plot
scatter(1:length(guesses), guesses, 5, "filled", "blue")
ylim([-0.5, 1.5])
hold on 
xline(switches, "red")
title("Rule Switching Behavior")
xlabel('Trial')
ylabel('Rule')
