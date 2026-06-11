% ============================================================
% Fire Safety Risk Assessment Expert System
% INFERENCE ENGINE MODULE
% ============================================================
% This is where the actual reasoning happens.
% It takes the facts from knowledge_base.pl and uses
% Prolog rules to figure out violations, scores, etc.
% ============================================================


% ----------------------------------------------------------
% Inference Rules - Exit Requirements
% ----------------------------------------------------------
% Walk through exit_requirement/2 facts and find the first
% threshold where the occupancy fits underneath it.

infer_required_exits(Occupancy, Required) :-
    exit_requirement(Threshold, Required),
    Occupancy =< Threshold,
    !.

% ----------------------------------------------------------
% Inference Rules - Staircase Requirements
% ----------------------------------------------------------
% Same approach but uses floor count instead of occupancy.

infer_required_staircases(Floors, Required) :-
    stair_requirement(Threshold, Required),
    Floors =< Threshold,
    !.

% ----------------------------------------------------------
% Inference Rules - Occupancy Category
% ----------------------------------------------------------
% Figures out whether occupancy is low, medium, high, etc.
% e.g. 120 people -> medium

infer_occupancy_category(Occupancy, Category) :-
    occupancy_category(Category, Min, Max),
    Occupancy >= Min,
    Occupancy =< Max,
    !.

% ----------------------------------------------------------
% Inference Rules - Floor Category
% ----------------------------------------------------------
% Classifies building as low_rise, mid_rise, or high_rise.
% e.g. 4 floors -> mid_rise

infer_floor_category(Floors, Category) :-
    floor_category(Category, Min, Max),
    Floors >= Min,
    Floors =< Max,
    !.


% ============================================================
% Violation Detection
% ============================================================
% The core of the expert system. Each clause of
% check_violation/10 checks for one specific problem.

% not enough exits for the number of people
check_violation(_, _, _, Occupancy, Exits, _, _, _, _, insufficient_exits) :-
    infer_required_exits(Occupancy, Required),
    Exits < Required.

% not enough staircases for the building height
check_violation(_, _, Floors, _, _, Staircases, _, _, _, insufficient_staircases) :-
    infer_required_staircases(Floors, Required),
    Staircases < Required.

% alarm system is missing
check_violation(_, _, _, _, _, _, no, _, _, alarm_missing).

% sprinkler system is missing
check_violation(_, _, _, _, _, _, _, no, _, sprinkler_missing).

% emergency lighting is missing
check_violation(_, _, _, _, _, _, _, _, no, lighting_missing).


% ============================================================
% Mandatory Issues (Building-Type Specific)
% ============================================================
% These are serious enough to cause automatic FAIL.
% Regular violations just lower the score, but mandatory
% issues mean the building cannot pass compliance.

% --- insufficient exits is always a mandatory issue ---
% every building must have enough exits for its occupancy
mandatory_issue(_, _, _, Occupancy, Exits, _, _, _, _,
    'Building has INSUFFICIENT EXITS - mandatory') :-
    infer_required_exits(Occupancy, Required),
    Exits < Required.

% --- alarm system is mandatory for these building types ---
mandatory_issue(_, hospital, _, _, _, _, no, _, _,
    'Hospital REQUIRES alarm system - mandatory').
mandatory_issue(_, hotel, _, _, _, _, no, _, _,
    'Hotel REQUIRES alarm system - mandatory').
mandatory_issue(_, school, _, _, _, _, no, _, _,
    'School REQUIRES alarm system - mandatory').
mandatory_issue(_, factory, _, _, _, _, no, _, _,
    'Factory REQUIRES alarm system - mandatory').

% hospitals always need sprinklers - patients can't evacuate easily
mandatory_issue(_, hospital, _, _, _, _, _, no, _,
    'Hospital REQUIRES sprinkler system - mandatory').

% factories need sprinklers due to fire hazards
mandatory_issue(_, factory, _, _, _, _, _, no, _,
    'Factory REQUIRES sprinkler system - mandatory').

% large hotels need more exits for safe evacuation
mandatory_issue(_, hotel, _, Occupancy, Exits, _, _, _, _,
    'Hotel with occupancy above 150 REQUIRES at least 3 exits') :-
    Occupancy > 150,
    Exits < 3.

% crowded schools need extra staircases
mandatory_issue(_, school, _, Occupancy, _, Staircases, _, _, _,
    'School with occupancy above 200 REQUIRES at least 2 staircases') :-
    Occupancy > 200,
    Staircases < 2.


% ============================================================
% Risk Assessment Engine
% ============================================================

% --- collect all violations for a building ---
find_violations(Name, Violations) :-
    building(Name, Type, Floors, Occ, Exits, Stairs, Alarm, Sprink, Light),
    findall(V,
        check_violation(Name, Type, Floors, Occ, Exits, Stairs, Alarm, Sprink, Light, V),
        Violations).

% --- collect all mandatory issues ---
find_mandatory_issues(Name, Issues) :-
    building(Name, Type, Floors, Occ, Exits, Stairs, Alarm, Sprink, Light),
    findall(Msg,
        mandatory_issue(Name, Type, Floors, Occ, Exits, Stairs, Alarm, Sprink, Light, Msg),
        Issues).

% --- calculate safety score ---
% start at 100, subtract penalty for each violation
% score bottoms out at 0 (can't go negative)
calculate_score(Violations, Score) :-
    findall(W,
        (member(V, Violations), risk_weight(V, W)),
        Weights),
    sum_list(Weights, TotalPenalty),
    RawScore is 100 - TotalPenalty,
    (RawScore < 0 -> Score = 0 ; Score = RawScore).

% --- determine risk level from the score ---
risk_level(Score, 'LOW') :- Score >= 80, !.
risk_level(Score, 'MEDIUM') :- Score >= 50, !.
risk_level(_, 'HIGH').

% --- compliance check ---
% passes only when there are zero mandatory issues
compliance_status(Name, 'PASS') :-
    find_mandatory_issues(Name, Issues),
    Issues == [],
    !.
compliance_status(_, 'FAIL').

% --- look up recommendations for each violation ---
get_recommendations(Violations, Recommendations) :-
    findall(Rec,
        (member(V, Violations), recommendation_for(V, Rec)),
        Recommendations).


% ============================================================
% Full Assessment
% ============================================================
% Runs everything and packs results into a report structure.

assess_building(Name, Report) :-
    building(Name, Type, Floors, Occ, Exits, Stairs, Alarm, Sprink, Light),

    % infer the categories from raw data
    infer_occupancy_category(Occ, OccCat),
    infer_floor_category(Floors, FloorCat),
    building_risk(Type, RiskCat),

    % figure out what's actually required
    infer_required_exits(Occ, ReqExits),
    infer_required_staircases(Floors, ReqStairs),

    % find what's wrong
    find_violations(Name, Violations),
    find_mandatory_issues(Name, MandatoryIssues),

    % compute the score and risk
    calculate_score(Violations, Score),
    risk_level(Score, RLevel),
    compliance_status(Name, Compliance),

    % get the fix suggestions
    get_recommendations(Violations, Recs),

    % bundle it all up
    Report = report(
        name(Name),
        type(Type),
        floors(Floors),
        occupancy(Occ),
        exits(Exits),
        staircases(Stairs),
        alarm(Alarm),
        sprinkler(Sprink),
        lighting(Light),
        occ_category(OccCat),
        floor_category(FloorCat),
        risk_category(RiskCat),
        required_exits(ReqExits),
        required_staircases(ReqStairs),
        violations(Violations),
        mandatory_issues(MandatoryIssues),
        score(Score),
        risk_level(RLevel),
        compliance(Compliance),
        recommendations(Recs)
    ).


% ============================================================
% Helper - Save Buildings to File
% ============================================================
% Writes all current buildings to buildings.pl so they
% survive between sessions. Called after every add/delete.

save_buildings :-
    open('buildings.pl', write, Stream),
    forall(
        building(N, T, F, O, E, S, A, Sp, L),
        (   format(Stream, 'building(~q, ~q, ~q, ~q, ~q, ~q, ~q, ~q, ~q).~n',
                   [N, T, F, O, E, S, A, Sp, L])
        )
    ),
    close(Stream).

% ============================================================
% Helper - Load Saved Buildings from File
% ============================================================
% Reads buildings.pl on startup to restore previously
% saved buildings. Silently does nothing if file missing.

load_saved_buildings :-
    (   exists_file('buildings.pl')
    ->  open('buildings.pl', read, Stream),
        read_buildings(Stream),
        close(Stream)
    ;   true
    ).

% reads building terms one by one from the file
read_buildings(Stream) :-
    read(Stream, Term),
    (   Term == end_of_file
    ->  true
    ;   (   Term = building(N, T, F, O, E, S, A, Sp, L),
            \+ building(N, _, _, _, _, _, _, _, _)
        ->  assertz(building(N, T, F, O, E, S, A, Sp, L))
        ;   true
        ),
        read_buildings(Stream)
    ).


% ============================================================
% Helper - Load Example Buildings
% ============================================================
% Copies example buildings into the system and saves them.

load_examples :-
    forall(
        example_building(N, T, F, O, E, S, A, Sp, L),
        (   \+ building(N, _, _, _, _, _, _, _, _)
        ->  assertz(building(N, T, F, O, E, S, A, Sp, L))
        ;   true
        )
    ),
    save_buildings.


% ============================================================
% Helper - Format Report as Text
% ============================================================
% Turns the report structure into a readable string
% that the GUI can display in a text window.

format_report(Report, Text) :-
    Report = report(
        name(Name), type(Type), floors(Floors),
        occupancy(Occ), exits(Exits), staircases(Stairs),
        alarm(Alarm), sprinkler(Sprink), lighting(Light),
        occ_category(OccCat), floor_category(FloorCat),
        risk_category(RiskCat),
        required_exits(ReqExits), required_staircases(ReqStairs),
        violations(Violations),
        mandatory_issues(MandIssues),
        score(Score), risk_level(RLevel),
        compliance(Compliance),
        recommendations(Recs)
    ),

    % prepare list sections first
    length(Violations, VCount),
    format_list(Violations, VText),
    length(MandIssues, MCount),
    format_list(MandIssues, MText),
    length(Recs, RCount),
    format_list(Recs, RText),

    % now build the full report string
    format(atom(Text),
        '~`=t~60|~n~a~n~`=t~60|~n~n\c
Building Name     : ~w~n\c
Building Type     : ~w~n\c
Floors            : ~w~n\c
Occupancy         : ~w~n\c
Exits             : ~w  (Required: ~w)~n\c
Staircases        : ~w  (Required: ~w)~n\c
Alarm System      : ~w~n\c
Sprinkler System  : ~w~n\c
Emergency Lighting: ~w~n~n\c
~`-t~40|~n\c
Occupancy Category : ~w~n\c
Building Height    : ~w~n\c
Risk Category      : ~w~n~n\c
~`-t~40|~n\c
Safety Score       : ~w / 100~n\c
Risk Level         : ~w~n\c
Compliance Status  : ~w~n~n\c
~`-t~40|~n\c
Violations (~w found):~n~a~n\c
Mandatory Issues (~w found):~n~a~n\c
Recommendations (~w found):~n~a~n\c
~`=t~60|~n',
        [
            'FIRE SAFETY ASSESSMENT REPORT',
            Name, Type, Floors, Occ,
            Exits, ReqExits,
            Stairs, ReqStairs,
            Alarm, Sprink, Light,
            OccCat, FloorCat, RiskCat,
            Score, RLevel, Compliance,
            VCount, VText,
            MCount, MText,
            RCount, RText
        ]).

% --- turns a list into bullet points ---
format_list([], '  (none)\n').
format_list(List, Text) :-
    List \= [],
    findall(Line,
        (member(Item, List),
         format(atom(Line), '  * ~w~n', [Item])),
        Lines),
    atomic_list_concat(Lines, Text).
