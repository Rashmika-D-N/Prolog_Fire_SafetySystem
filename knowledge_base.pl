% ============================================================
% Fire Safety Risk Assessment Expert System
% KNOWLEDGE BASE MODULE
% ============================================================
% This file contains all the expert knowledge - the facts
% that a real fire safety inspector would know.
% Nothing here does any reasoning, it just stores information.
% ============================================================


% ----------------------------------------------------------
% Dynamic Facts Declaration
% ----------------------------------------------------------
% Buildings can be added and removed at runtime,
% so we tell Prolog that building/9 can change.

:- dynamic building/9.

% building(Name, Type, Floors, Occupancy, Exits, Staircases,
%          AlarmSystem, SprinklerSystem, EmergencyLighting).
%
% Name        - atom, unique name for the building
% Type        - one of: office, hotel, school, hospital, factory, apartment
% Floors      - integer, number of floors
% Occupancy   - integer, max number of people
% Exits       - integer, number of emergency exits
% Staircases  - integer, number of staircases
% AlarmSystem       - yes / no
% SprinklerSystem   - yes / no
% EmergencyLighting - yes / no


% ----------------------------------------------------------
% Exit Requirements
% ----------------------------------------------------------
% exit_requirement(MaxOccupancy, RequiredExits).
% If occupancy is at most MaxOccupancy, the building
% needs at least RequiredExits emergency exits.

exit_requirement(50, 1).
exit_requirement(100, 2).
exit_requirement(300, 3).
exit_requirement(99999, 4).


% ----------------------------------------------------------
% Staircase Requirements
% ----------------------------------------------------------
% stair_requirement(MaxFloors, RequiredStaircases).
% Same logic as exits but based on number of floors.

stair_requirement(2, 1).
stair_requirement(5, 2).
stair_requirement(99999, 3).


% ----------------------------------------------------------
% Building Risk Categories
% ----------------------------------------------------------
% Some building types are riskier than others.
% Hospitals have vulnerable patients, factories have
% hazardous materials - both are high risk.

building_risk(hospital, high).
building_risk(factory, high).
building_risk(hotel, medium).
building_risk(apartment, medium).
building_risk(school, medium).
building_risk(office, low).


% ----------------------------------------------------------
% Occupancy Categories
% ----------------------------------------------------------
% occupancy_category(Category, MinPeople, MaxPeople).
% Classifies how crowded a building is.

occupancy_category(low, 0, 50).
occupancy_category(medium, 51, 150).
occupancy_category(high, 151, 300).
occupancy_category(very_high, 301, 99999).


% ----------------------------------------------------------
% Building Height Categories
% ----------------------------------------------------------
% floor_category(Category, MinFloors, MaxFloors).

floor_category(low_rise, 1, 2).
floor_category(mid_rise, 3, 5).
floor_category(high_rise, 6, 99999).


% ----------------------------------------------------------
% Equipment Importance Levels
% ----------------------------------------------------------
% Records how important each safety equipment is.

equipment(alarm_system, critical).
equipment(sprinkler_system, critical).
equipment(emergency_lighting, important).
equipment(evacuation_maps, recommended).
equipment(fire_resistant_doors, recommended).


% ----------------------------------------------------------
% Risk Weights (Penalty Points)
% ----------------------------------------------------------
% Each violation type costs this many points off the
% safety score. Score starts at 100.

risk_weight(insufficient_exits, 25).
risk_weight(insufficient_staircases, 20).
risk_weight(alarm_missing, 20).
risk_weight(sprinkler_missing, 15).
risk_weight(lighting_missing, 10).


% ----------------------------------------------------------
% Recommendations for Violations
% ----------------------------------------------------------
% Maps each violation to a corrective action.

recommendation_for(insufficient_exits,
    'Increase the number of emergency exits').
recommendation_for(insufficient_staircases,
    'Provide additional staircases').
recommendation_for(alarm_missing,
    'Install a fire detection and alarm system').
recommendation_for(sprinkler_missing,
    'Install an automatic sprinkler system').
recommendation_for(lighting_missing,
    'Install emergency lighting throughout the building').


% ----------------------------------------------------------
% Building Type Guidelines
% ----------------------------------------------------------
% Human-readable rules for each building type.
% Displayed when the user clicks "View Guidelines".

guideline(office, 'Fire alarm system required').
guideline(office, 'Emergency lighting required').
guideline(office, 'Standard exit and staircase rules apply').

guideline(hotel, 'Fire alarm system required').
guideline(hotel, 'Emergency lighting required').
guideline(hotel, 'Sprinklers required for buildings above 5 floors').
guideline(hotel, 'Hotels with occupancy above 150 require at least 3 exits').

guideline(school, 'Fire alarm system required').
guideline(school, 'Emergency lighting required').
guideline(school, 'Schools with occupancy above 200 require at least 2 staircases').

guideline(hospital, 'Fire alarm system required').
guideline(hospital, 'Sprinkler system is always mandatory').
guideline(hospital, 'Emergency lighting required').
guideline(hospital, 'Hospitals are classified as high-risk buildings').

guideline(factory, 'Fire alarm system is mandatory').
guideline(factory, 'Sprinkler system is mandatory').
guideline(factory, 'Factories are classified as high-risk buildings').
guideline(factory, 'Emergency lighting required').

guideline(apartment, 'Fire alarm system required').
guideline(apartment, 'Emergency lighting required').
guideline(apartment, 'Standard exit and staircase rules apply').


% ----------------------------------------------------------
% Example Buildings (for testing)
% ----------------------------------------------------------
% These are all well-equipped, compliant buildings.
% Every one should pass the assessment with no issues.
% Students can load these to see what a good report looks like.

% hospitals - high risk, need alarm + sprinkler mandatory
example_building(city_hospital, hospital, 6, 150, 3, 3, yes, yes, yes).
example_building(rural_clinic, hospital, 2, 80, 2, 1, yes, yes, yes).

% hotels - medium risk, need alarm, >150 occ needs 3+ exits
example_building(grand_hotel, hotel, 8, 250, 3, 3, yes, yes, yes).
example_building(beach_resort, hotel, 4, 180, 3, 2, yes, yes, yes).

% schools - medium risk, need alarm, >200 occ needs 2+ stairs
example_building(central_school, school, 3, 350, 4, 2, yes, yes, yes).
example_building(village_school, school, 2, 120, 2, 1, yes, yes, yes).

% factories - high risk, need alarm + sprinkler mandatory
example_building(steel_factory, factory, 3, 200, 3, 2, yes, yes, yes).
example_building(textile_mill, factory, 5, 100, 2, 2, yes, yes, yes).

% offices - low risk, standard rules apply
example_building(tech_office, office, 2, 40, 1, 1, yes, yes, yes).
example_building(tower_office, office, 10, 500, 4, 3, yes, yes, yes).

% apartments - medium risk, standard rules apply
example_building(sunset_apartments, apartment, 5, 120, 2, 2, yes, yes, yes).
example_building(riverside_apartments, apartment, 3, 80, 2, 2, yes, yes, yes).

