% ============================================================
% Fire Safety Risk Assessment Expert System
% MAIN ENTRY POINT
% ============================================================
% This file loads all the modules and starts the application.
%
% HOW TO RUN:
%   1. Open SWI-Prolog
%   2. ?- [main].
%   3. ?- start.
%
% File Structure:
%   main.pl            - this file (entry point)
%   knowledge_base.pl  - all facts and expert knowledge
%   inference_engine.pl - reasoning rules and assessment logic
%   gui.pl             - XPCE graphical interface
% ============================================================

% load the modules in the right order
% knowledge base first since inference engine depends on it
:- [knowledge_base].
:- [inference_engine].
:- [gui].
