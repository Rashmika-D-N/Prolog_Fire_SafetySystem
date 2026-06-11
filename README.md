# Fire Safety Risk Assessment Expert System

This is a rule-based expert system built using SWI-Prolog that evaluates building fire safety. It assesses buildings based on their structural characteristics and safety features, calculates a risk score, identifies specific safety violations, and provides tailored recommendations.

## Features

- **Dynamic Knowledge Base**: Stores facts about buildings (type, floors, occupancy, alarms, sprinklers, etc.).
- **Inference Engine**: Applies logic and expert rules to evaluate safety constraints.
- **Risk Scoring Algorithm**: Calculates a safety score (0-100) based on weighted penalties for missing safety features.
- **Graphical User Interface (GUI)**: Built using Prolog's XPCE library, allowing users to easily add buildings, run assessments, and view reports without interacting with the console.
- **Actionable Recommendations**: Generates specific advice to fix identified violations.

## File Structure

- `main.pl`: The entry point of the application. It loads all necessary modules and starts the GUI.
- `gui.pl`: Contains the XPCE code for drawing windows, buttons, forms, and handling user interactions.
- `inference_engine.pl`: Contains the logical rules for assessing risk, finding violations, and calculating the final score.
- `knowledge_base.pl`: Defines the schema for facts, rules for building classification (e.g., occupancy levels), and dynamically stores building data.
- `buildings.pl`: A text-based database file where the system permanently saves dynamically added buildings across sessions.

## Prerequisites

To run this application, you need to have SWI-Prolog installed on your system.
- Download SWI-Prolog: https://www.swi-prolog.org/Download.html

## How to Run

1. Open SWI-Prolog.
2. In the SWI-Prolog console, navigate to the project directory, or simply open `main.pl` with SWI-Prolog.
3. If using the console, compile and load the main file by typing:
   ```prolog
   ?- [main].
   ```
4. Start the application by running the `start` predicate:
   ```prolog
   ?- start.
   ```
5. The Fire Safety Expert System GUI window will appear. You can now add buildings and run risk assessments!
