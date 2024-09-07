function catches = is_catch(params)
%Return booleans based on which trials are comparisons in the off-diagonal
%(meaning they are catch trials where the stimuli presented are of equal
%value).
rf_vals = ((mod((5 - mod([params.stimRF_num], 5)), 5) + 1) ... % RF color vals
    + ceil([params.stimRF_num]/5)); % RF shape vals
opp_vals = ((mod((5 - mod([params.stimOpp_num], 5)), 5) + 1) ... % Opp color vals
    + ceil([params.stimOpp_num]/5)); %Opp shape vals
catches = rf_vals == opp_vals;
end