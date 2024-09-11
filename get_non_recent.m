function non_recent = get_non_recent(params, lim)
%returns booleans representing if rule change is not recent
rules = [params.rule];
non_recent = zeros(1,length(rules));
for r = 1:length(rules)
    rule = rules(r);
    if r > lim && all(rules(r - 50: r) == rule)
        non_recent(r) = 1;
    end
end