% ============================================================
% Fire Safety Risk Assessment Expert System
% GUI MODULE (XPCE)
% ============================================================
% Handles the graphical user interface.
% Uses XPCE which comes built-in with SWI-Prolog.
%
% This file is loaded by main.pl - don't run it directly.
% ============================================================

:- use_module(library(pce)).


% ============================================================
% Main Window
% ============================================================
% Creates the main application window with input fields
% for adding buildings, plus action buttons.

start :-
    % load any previously saved buildings from file
    load_saved_buildings,

    % clean up if there's already a window open
    catch(send(@fire_safety_app, destroy), _, true),

    new(Dialog, dialog('Fire Safety Risk Assessment Expert System')),
    send(Dialog, name, fire_safety_app),
    send(Dialog, size, size(520, 620)),

    % title area
    send(Dialog, append,
        label(title, 'Fire Safety Risk Assessment Expert System')),
    send(Dialog, append,
        label(subtitle, '--- Enter Building Details Below ---')),

    % text input for building name
    send(Dialog, append,
        new(_NameField, text_item(building_name, ''))),

    % dropdown for building type
    send(Dialog, append,
        new(TypeMenu, menu(building_type, choice))),
    send_list(TypeMenu, append,
        [office, hotel, school, hospital, factory, apartment]),

    % number inputs - set range separately since int_item
    % only takes name and default value
    send(Dialog, append,
        new(FloorsField, int_item(floors, 1))),
    send(FloorsField, range, 1, 200),

    send(Dialog, append,
        new(OccField, int_item(occupancy, 1))),
    send(OccField, range, 1, 99999),

    send(Dialog, append,
        new(ExitsField, int_item(exits, 1))),
    send(ExitsField, range, 1, 50),

    send(Dialog, append,
        new(StairsField, int_item(staircases, 1))),
    send(StairsField, range, 1, 50),

    % yes/no choices for safety equipment
    send(Dialog, append,
        new(AlarmMenu, menu(alarm_system, choice))),
    send_list(AlarmMenu, append, [yes, no]),

    send(Dialog, append,
        new(SprinkMenu, menu(sprinkler_system, choice))),
    send_list(SprinkMenu, append, [yes, no]),

    send(Dialog, append,
        new(LightMenu, menu(emergency_lighting, choice))),
    send_list(LightMenu, append, [yes, no]),

    % action buttons
    send(Dialog, append,
        button(add_building,
            message(@prolog, add_building_action, Dialog))),
    send(Dialog, append,
        button(view_buildings,
            message(@prolog, view_buildings_action))),
    send(Dialog, append,
        button(assess_building,
            message(@prolog, open_assess_window))),
    send(Dialog, append,
        button(delete_building,
            message(@prolog, open_delete_window))),
    send(Dialog, append,
        button(view_guidelines,
            message(@prolog, view_guidelines_action))),
    send(Dialog, append,
        button(view_example_buildings,
            message(@prolog, view_examples_action))),
    send(Dialog, append,
        button(exit,
            message(Dialog, destroy))),

    send(Dialog, open_centered).


% ============================================================
% Button Actions
% ============================================================

% --- ADD BUILDING ---
% Reads form values, asserts the building, and saves to file.

add_building_action(Dialog) :-
    % grab each field from the dialog, then read its value
    get(Dialog, member, building_name, F1),
    get(F1, selection, NameAtom),
    get(Dialog, member, building_type, F2),
    get(F2, selection, Type),
    get(Dialog, member, floors, F3),
    get(F3, selection, Floors),
    get(Dialog, member, occupancy, F4),
    get(F4, selection, Occ),
    get(Dialog, member, exits, F5),
    get(F5, selection, Exits),
    get(Dialog, member, staircases, F6),
    get(F6, selection, Stairs),
    get(Dialog, member, alarm_system, F7),
    get(F7, selection, Alarm),
    get(Dialog, member, sprinkler_system, F8),
    get(F8, selection, Sprink),
    get(Dialog, member, emergency_lighting, F9),
    get(F9, selection, Light),

    % convert name to atom
    atom_string(Name, NameAtom),

    % validate - name can't be empty
    (Name == '' ->
        send(@display, inform, 'Please enter a building name.')
    ;
        % check for duplicates
        (building(Name, _, _, _, _, _, _, _, _) ->
            send(@display, inform, 'A building with that name already exists!')
        ;
            % add and save permanently
            assertz(building(Name, Type, Floors, Occ, Exits, Stairs,
                             Alarm, Sprink, Light)),
            save_buildings,
            format(atom(Msg), 'Building "~w" added and saved!', [Name]),
            send(@display, inform, Msg)
        )
    ).


% --- VIEW ALL BUILDINGS ---
% Shows every building currently in the system.

view_buildings_action :-
    findall(
        building(N, T, F, O, E, S, A, Sp, L),
        building(N, T, F, O, E, S, A, Sp, L),
        Buildings
    ),
    (Buildings == [] ->
        send(@display, inform, 'No buildings in the system yet.')
    ;
        format_building_list(Buildings, Text),
        show_text_window('Buildings in System', Text)
    ).

% helper - makes the building list readable
format_building_list(Buildings, Text) :-
    findall(Entry,
        (member(building(N, T, F, O, E, S, A, Sp, L), Buildings),
         format(atom(Entry),
            'Name: ~w~n  Type: ~w | Floors: ~w | Occupancy: ~w~n\c
  Exits: ~w | Stairs: ~w~n\c
  Alarm: ~w | Sprinkler: ~w | Lighting: ~w~n~n',
            [N, T, F, O, E, S, A, Sp, L])),
        Entries),
    atomic_list_concat(Entries, Text).


% ============================================================
% Assess Building - Separate Window
% ============================================================
% Opens a new window where user can pick a saved building
% from a dropdown and run the assessment.

open_assess_window :-
    % collect all building names currently in the system
    findall(N, building(N, _, _, _, _, _, _, _, _), Names),

    (Names == [] ->
        send(@display, inform,
            'No buildings saved yet. Add a building first.')
    ;
        new(D, dialog('Assess Building')),
        send(D, size, size(400, 200)),

        send(D, append,
            label(info, 'Select a building to assess:')),

        % dropdown with all saved building names
        send(D, append,
            new(NameMenu, menu(building_name, choice))),
        add_names_to_menu(NameMenu, Names),

        % also allow typing a name manually
        send(D, append,
            new(_NameInput, text_item(building_name_input, ''))),
        send(D, append,
            label(hint, '(Or type a building name above)')),

        send(D, append,
            button(assess,
                message(@prolog, run_assessment, D))),
        send(D, append,
            button(cancel, message(D, destroy))),

        send(D, open_centered)
    ).

% helper - adds each name to the dropdown menu
add_names_to_menu(_, []).
add_names_to_menu(Menu, [Name|Rest]) :-
    send(Menu, append, Name),
    add_names_to_menu(Menu, Rest).

% runs the assessment from the assess window
run_assessment(D) :-
    % first try the typed name, if empty use the dropdown
    get(D, member, building_name_input, InputField),
    get(InputField, selection, TypedAtom),
    atom_string(TypedName, TypedAtom),

    (TypedName \= '' ->
        Name = TypedName
    ;
        get(D, member, building_name, MenuField),
        get(MenuField, selection, Name)
    ),

    send(D, destroy),

    (building(Name, _, _, _, _, _, _, _, _) ->
        assess_building(Name, Report),
        format_report(Report, ReportText),
        show_text_window('Assessment Report', ReportText)
    ;
        format(atom(Msg), 'Building "~w" not found.', [Name]),
        send(@display, inform, Msg)
    ).


% ============================================================
% Delete Building - Separate Window
% ============================================================
% Opens a window where user can pick a building from
% the dropdown and delete it.

open_delete_window :-
    findall(N, building(N, _, _, _, _, _, _, _, _), Names),

    (Names == [] ->
        send(@display, inform,
            'No buildings saved yet. Nothing to delete.')
    ;
        new(D, dialog('Delete Building')),
        send(D, size, size(400, 180)),

        send(D, append,
            label(info, 'Select a building to delete:')),

        % dropdown with all saved building names
        send(D, append,
            new(NameMenu, menu(building_name, choice))),
        add_names_to_menu(NameMenu, Names),

        send(D, append,
            button(delete,
                message(@prolog, run_deletion, D))),
        send(D, append,
            button(cancel, message(D, destroy))),

        send(D, open_centered)
    ).

% performs the actual deletion
run_deletion(D) :-
    get(D, member, building_name, MenuField),
    get(MenuField, selection, Name),
    send(D, destroy),

    (building(Name, _, _, _, _, _, _, _, _) ->
        retractall(building(Name, _, _, _, _, _, _, _, _)),
        save_buildings,
        format(atom(Msg), 'Building "~w" deleted.', [Name]),
        send(@display, inform, Msg)
    ;
        format(atom(Msg), 'Building "~w" not found.', [Name]),
        send(@display, inform, Msg)
    ).


% --- VIEW GUIDELINES ---
% Opens a small dialog to pick a building type,
% then shows the fire safety rules for that type.

view_guidelines_action :-
    new(D, dialog('Select Building Type')),
    send(D, append, new(TypeMenu, menu(type, choice))),
    send_list(TypeMenu, append,
        [office, hotel, school, hospital, factory, apartment]),
    send(D, append,
        button(show_guidelines, message(@prolog, show_guidelines, D))),
    send(D, append,
        button(cancel, message(D, destroy))),
    send(D, open_centered).

show_guidelines(D) :-
    get(D, member, type, TF),
    get(TF, selection, Type),
    send(D, destroy),

    % get all guidelines for selected type
    findall(G, guideline(Type, G), Guidelines),
    building_risk(Type, Risk),

    format(atom(Header),
        'Fire Safety Guidelines for: ~w~nInherent Risk Level: ~w~n~n',
        [Type, Risk]),
    format_list(Guidelines, GText),
    atom_concat(Header, GText, FullText),
    show_text_window('Guidelines', FullText).


% --- VIEW EXAMPLE BUILDINGS ---
% Shows the pre-defined examples and offers to load them.

view_examples_action :-
    findall(
        example(N, T, F, O, E, S, A, Sp, L),
        example_building(N, T, F, O, E, S, A, Sp, L),
        Examples
    ),
    format_example_list(Examples, Text),

    new(D, dialog('Example Buildings')),
    send(D, append, label(info, Text)),
    send(D, append,
        button(load_into_system,
            and(
                message(@prolog, load_examples),
                message(@display, inform,
                    'Example buildings loaded and saved!'),
                message(D, destroy)
            ))),
    send(D, append,
        button(close, message(D, destroy))),
    send(D, open_centered).

% helper for example buildings display
format_example_list(Examples, Text) :-
    findall(Entry,
        (member(example(N, T, F, O, E, S, A, Sp, L), Examples),
         format(atom(Entry),
            '~w (~w)~n  Floors: ~w | Occupancy: ~w | Exits: ~w | Stairs: ~w~n\c
  Alarm: ~w | Sprinkler: ~w | Lighting: ~w~n~n',
            [N, T, F, O, E, S, A, Sp, L])),
        Entries),
    atomic_list_concat(Entries, Text).


% ============================================================
% Text Display Window
% ============================================================
% Opens a scrollable window for longer text like reports.
% Uses a view widget so the user can scroll and copy text.

show_text_window(Title, Text) :-
    new(D, dialog(Title)),
    send(D, size, size(550, 450)),

    % create a view (scrollable text area)
    new(View, view),
    send(View, size, size(520, 380)),
    send(View, font, font(screen, roman, 12)),
    send(View, editable, @off),
    send(View, contents, Text),

    send(D, append, View),
    send(D, append,
        button(close, message(D, destroy))),
    send(D, open_centered).
