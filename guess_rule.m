function [guessed_rule] = guess_rule(params)
% for given params, generates rule guess. Works only for classic/inverse
    rules = [params.rule];
    corrects = [params.correct] == [params.selected];
    guessed_rule = rules;
    guessed_rule(corrects == 0) = 1 - rules(corrects == 0);
    catches = is_catch(params);
    guessed_rule(catches) = NaN;
end