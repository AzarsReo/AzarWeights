#!/usr/bin/env python3
"""Generate FitnessTracker/Resources/PresetData.json from the product plan."""

from __future__ import annotations

import json
from pathlib import Path

# (name, muscleGroup, equipment, movementPattern, aliases)
EXERCISES: list[tuple[str, str, str, str, list[str]]] = []


def add(name: str, muscle: str, equipment: str, pattern: str, aliases: list[str] | None = None) -> None:
    EXERCISES.append((name, muscle, equipment, pattern, aliases or []))


# Niche variations dropped so the bundled library stays in the 150–350 range.
SKIP_NAMES = {
    "Kneeling Incline Push-Up",
    "Cobra Push-Up",
    "Push-Up Against Wall",
    "Push-Ups With Feet in Rings",
    "Plank to Push-Up",
    "Band-Assisted Bench Press",
    "Bench Press Against Band",
    "Standing Resistance Band Chest Fly",
    "Smith Machine Reverse Grip Bench Press",
    "Pin Bench Press",
    "Board Press",
    "Feet-Up Bench Press",
    "Floor Back Extension",
    "Jefferson Curl",
    "Block Clean",
    "Block Snatch",
    "Hang Power Snatch",
    "Jumping Muscle-Up",
    "Banded Muscle-Up",
    "Towel Row",
    "Smith Machine One-Handed Row",
    "Inverted Row with Underhand Grip",
    "Scap Pull-Up",
    "Snatch Grip Behind the Neck Press",
    "Smith Machine Landmine Press",
    "Front Hold",
    "Poliquin Raise",
    "Monkey Row",
    "Lying Bicep Cable Curl",
    "Overhead Cable Curl",
    "Cable Crossover Bicep Curl",
    "Bodyweight Curl",
    "Barbell Incline Triceps Extension",
    "Smith Machine Skull Crushers",
    "Half Air Squat",
    "Zombie Squat",
    "Shallow Body Weight Lunge",
    "Prisoner Get Up",
    "Standing Hip Flexor Raise",
    "Kettlebell Tibialis Raise",
    "Tibialis Band Pull",
    "Poliquin Step-Up",
    "Chair Squat",
    "Death March with Dumbbells",
    "Standing Glute Push Down",
    "Barbell Seated Calf Raise",
    "Kneeling Plank",
    "Kneeling Side Plank",
    "Dynamic Side Plank",
    "Jackknife Sit-Up",
    "Hanging Sit-Up",
    "Barbell Wrist Curl Behind the Back",
    "Plate Wrist Curl",
    "One-Handed Bar Hang",
}


# --- Chest ---
add("Bench Press", "Chest", "Barbell", "push", ["Barbell Bench Press", "Flat Bench"])
add("Incline Bench Press", "Chest", "Barbell", "push", ["Incline Barbell Press"])
add("Decline Bench Press", "Chest", "Barbell", "push", [])
add("Close-Grip Bench Press", "Chest", "Barbell", "push", ["CGBP"])
add("Floor Press", "Chest", "Barbell", "push", [])
add("Pin Bench Press", "Chest", "Barbell", "push", [])
add("Board Press", "Chest", "Barbell", "push", [])
add("Feet-Up Bench Press", "Chest", "Barbell", "push", [])
add("Smith Machine Bench Press", "Chest", "Smith Machine", "push", [])
add("Smith Machine Incline Bench Press", "Chest", "Smith Machine", "push", [])
add("Smith Machine Reverse Grip Bench Press", "Chest", "Smith Machine", "push", [])
add("Dumbbell Chest Press", "Chest", "Dumbbell", "push", ["DB Bench Press"])
add("Incline Dumbbell Press", "Chest", "Dumbbell", "push", ["Incline DB Press"])
add("Dumbbell Decline Chest Press", "Chest", "Dumbbell", "push", [])
add("Dumbbell Floor Press", "Chest", "Dumbbell", "push", [])
add("Dumbbell Chest Fly", "Chest", "Dumbbell", "push", ["DB Fly"])
add("Dumbbell Pullover", "Chest", "Dumbbell", "pull", [])
add("Cable Chest Press", "Chest", "Cable", "push", [])
add("Seated Cable Chest Fly", "Chest", "Cable", "push", [])
add("Standing Cable Chest Fly", "Chest", "Cable", "push", ["Cable Fly"])
add("Machine Chest Press", "Chest", "Machine", "push", [])
add("Machine Chest Fly", "Chest", "Machine", "push", [])
add("Pec Deck", "Chest", "Machine", "push", ["Pec Deck Fly"])
add("Push-Up", "Chest", "Bodyweight", "push", ["Push Up", "Pushup"])
add("Incline Push-Up", "Chest", "Bodyweight", "push", [])
add("Decline Push-Up", "Chest", "Bodyweight", "push", [])
add("Close-Grip Push-Up", "Chest", "Bodyweight", "push", [])
add("Kneeling Push-Up", "Chest", "Bodyweight", "push", [])
add("Kneeling Incline Push-Up", "Chest", "Bodyweight", "push", [])
add("Cobra Push-Up", "Chest", "Bodyweight", "push", [])
add("Clap Push-Up", "Chest", "Bodyweight", "push", [])
add("Plank to Push-Up", "Chest", "Bodyweight", "push", [])
add("Push-Up Against Wall", "Chest", "Bodyweight", "push", ["Wall Push-Up"])
add("Push-Ups With Feet in Rings", "Chest", "Suspension", "push", [])
add("Bar Dip", "Chest", "Bodyweight", "push", ["Dips", "Parallel Bar Dip"])
add("Assisted Dip", "Chest", "Machine", "push", [])
add("Ring Dip", "Chest", "Suspension", "push", [])
add("Band-Assisted Bench Press", "Chest", "Band", "push", [])
add("Bench Press Against Band", "Chest", "Band", "push", [])
add("Resistance Band Chest Fly", "Chest", "Band", "push", [])
add("Standing Resistance Band Chest Fly", "Chest", "Band", "push", [])
add("Medicine Ball Chest Pass", "Chest", "Medicine Ball", "push", [])
add("Kettlebell Floor Press", "Chest", "Kettlebell", "push", [])
add("Low Cable Crossover", "Chest", "Cable", "push", [])
add("High Cable Crossover", "Chest", "Cable", "push", [])
add("Cable Crossover", "Chest", "Cable", "push", ["Mid Cable Crossover"])

# --- Back ---
add("Deadlift", "Back", "Barbell", "hinge", ["Conventional Deadlift"])
add("Sumo Deadlift", "Back", "Barbell", "hinge", [])
add("Trap Bar Deadlift", "Back", "Trap Bar", "hinge", ["Hex Bar Deadlift", "High Handles", "Low Handles"])
add("Deficit Deadlift", "Back", "Barbell", "hinge", [])
add("Pause Deadlift", "Back", "Barbell", "hinge", [])
add("Snatch Grip Deadlift", "Back", "Barbell", "hinge", [])
add("Stiff-Legged Deadlift", "Hamstrings", "Barbell", "hinge", ["SLDL"])
add("Rack Pull", "Back", "Barbell", "hinge", [])
add("Smith Machine Deadlift", "Back", "Smith Machine", "hinge", [])
add("Dumbbell Deadlift", "Back", "Dumbbell", "hinge", [])
add("Barbell Row", "Back", "Barbell", "pull", ["Bent-Over Row", "Barbell Bent Over Row"])
add("Pendlay Row", "Back", "Barbell", "pull", [])
add("T-Bar Row", "Back", "Barbell", "pull", ["Landmine Row"])
add("Dumbbell Row", "Back", "Dumbbell", "pull", ["One-Arm Dumbbell Row", "DB Row"])
add("Kroc Row", "Back", "Dumbbell", "pull", [])
add("Chest-Supported Dumbbell Row", "Back", "Dumbbell", "pull", ["Incline DB Row"])
add("Gorilla Row", "Back", "Kettlebell", "pull", [])
add("Renegade Row", "Back", "Dumbbell", "pull", [])
add("Seal Row", "Back", "Barbell", "pull", [])
add("One-Handed Cable Row", "Back", "Cable", "pull", ["Single-Arm Cable Row"])
add("Cable Close Grip Seated Row", "Back", "Cable", "pull", [])
add("Cable Wide Grip Seated Row", "Back", "Cable", "pull", [])
add("Seated Machine Row", "Back", "Machine", "pull", ["Chest-Supported Machine Row"])
add("Inverted Row", "Back", "Bodyweight", "pull", ["Bodyweight Row"])
add("Inverted Row with Underhand Grip", "Back", "Bodyweight", "pull", [])
add("Ring Row", "Back", "Suspension", "pull", [])
add("Towel Row", "Back", "Bodyweight", "pull", [])
add("Smith Machine One-Handed Row", "Back", "Smith Machine", "pull", [])
add("Pull-Up", "Back", "Bodyweight", "pull", ["Pull Up", "Pullup"])
add("Chin-Up", "Back", "Bodyweight", "pull", ["Chin Up"])
add("Close-Grip Chin-Up", "Back", "Bodyweight", "pull", [])
add("Pull-Up With Neutral Grip", "Back", "Bodyweight", "pull", ["Neutral Grip Pull-Up"])
add("Ring Pull-Up", "Back", "Suspension", "pull", [])
add("Scap Pull-Up", "Back", "Bodyweight", "pull", [])
add("Assisted Pull-Up", "Back", "Machine", "pull", [])
add("Assisted Chin-Up", "Back", "Machine", "pull", [])
add("Lat Pulldown", "Back", "Cable", "pull", ["Lat Pull Down"])
add("Lat Pulldown Pronated", "Back", "Cable", "pull", ["Lat Pulldown With Pronated Grip"])
add("Lat Pulldown Supinated", "Back", "Cable", "pull", ["Reverse Grip Lat Pulldown"])
add("Lat Pulldown Neutral Grip", "Back", "Cable", "pull", [])
add("Close-Grip Lat Pulldown", "Back", "Cable", "pull", [])
add("One-Handed Lat Pulldown", "Back", "Cable", "pull", ["Single-Arm Lat Pulldown"])
add("Machine Lat Pulldown", "Back", "Machine", "pull", [])
add("Rope Pulldown", "Back", "Cable", "pull", [])
add("Straight Arm Lat Pulldown", "Back", "Cable", "pull", ["Straight-Arm Pulldown"])
add("Barbell Shrug", "Back", "Barbell", "pull", [])
add("Dumbbell Shrug", "Back", "Dumbbell", "pull", [])
add("Back Extension", "Back", "Machine", "hinge", ["Hyperextension", "45 Degree Back Extension"])
add("Floor Back Extension", "Back", "Bodyweight", "hinge", [])
add("Jefferson Curl", "Back", "Barbell", "hinge", [])
add("Good Morning", "Hamstrings", "Barbell", "hinge", [])
add("Superman Raise", "Back", "Bodyweight", "hinge", ["Superman"])
add("Clean", "Back", "Barbell", "olympic", ["Barbell Clean"])
add("Power Clean", "Back", "Barbell", "olympic", [])
add("Hang Clean", "Back", "Barbell", "olympic", [])
add("Block Clean", "Back", "Barbell", "olympic", [])
add("Snatch", "Back", "Barbell", "olympic", [])
add("Power Snatch", "Back", "Barbell", "olympic", [])
add("Hang Snatch", "Back", "Barbell", "olympic", [])
add("Block Snatch", "Back", "Barbell", "olympic", [])
add("Clean and Jerk", "Back", "Barbell", "olympic", ["C&J"])
add("Hang Power Clean", "Back", "Barbell", "olympic", [])
add("Hang Power Snatch", "Back", "Barbell", "olympic", [])
add("Kettlebell Clean", "Back", "Kettlebell", "olympic", [])
add("Kettlebell Snatch", "Back", "Kettlebell", "olympic", [])
add("Kettlebell Swing", "Hamstrings", "Kettlebell", "hinge", ["KB Swing"])
add("One-Handed Kettlebell Swing", "Hamstrings", "Kettlebell", "hinge", [])
add("Kettlebell Row", "Back", "Kettlebell", "pull", [])
add("Kettlebell Clean & Press", "Shoulders", "Kettlebell", "olympic", [])
add("Kettlebell Clean & Jerk", "Shoulders", "Kettlebell", "olympic", [])
add("Muscle-Up (Bar)", "Back", "Bodyweight", "pull", ["Bar Muscle-Up"])
add("Muscle-Up (Rings)", "Back", "Suspension", "pull", ["Ring Muscle-Up"])
add("Banded Muscle-Up", "Back", "Band", "pull", [])
add("Jumping Muscle-Up", "Back", "Bodyweight", "pull", [])
add("Chest to Bar", "Back", "Bodyweight", "pull", ["Chest-to-Bar Pull-Up"])
add("Wide-Grip Pull-Up", "Back", "Bodyweight", "pull", [])
add("Weighted Pull-Up", "Back", "Bodyweight", "pull", [])
add("Band-Assisted Pull-Up", "Back", "Band", "pull", [])
add("Face Pull", "Shoulders", "Cable", "pull", ["Cable Face Pull"])

# --- Shoulders ---
add("Overhead Press", "Shoulders", "Barbell", "push", ["OHP", "Military Press", "Barbell Overhead Press"])
add("Seated Barbell Overhead Press", "Shoulders", "Barbell", "push", ["Seated OHP"])
add("Push Press", "Shoulders", "Barbell", "push", [])
add("Behind the Neck Press", "Shoulders", "Barbell", "push", [])
add("Snatch Grip Behind the Neck Press", "Shoulders", "Barbell", "push", [])
add("Z Press", "Shoulders", "Barbell", "push", [])
add("Dumbbell Shoulder Press", "Shoulders", "Dumbbell", "push", ["DB OHP"])
add("Seated Dumbbell Shoulder Press", "Shoulders", "Dumbbell", "push", [])
add("Arnold Press", "Shoulders", "Dumbbell", "push", [])
add("Machine Shoulder Press", "Shoulders", "Machine", "push", [])
add("Seated Smith Machine Shoulder Press", "Shoulders", "Smith Machine", "push", [])
add("Kettlebell Press", "Shoulders", "Kettlebell", "push", [])
add("Seated Kettlebell Press", "Shoulders", "Kettlebell", "push", [])
add("Kettlebell Push Press", "Shoulders", "Kettlebell", "push", [])
add("Landmine Press", "Shoulders", "Barbell", "push", [])
add("One-Arm Landmine Press", "Shoulders", "Barbell", "push", [])
add("Smith Machine Landmine Press", "Shoulders", "Smith Machine", "push", [])
add("Lateral Raise", "Shoulders", "Dumbbell", "push", ["Side Raise", "Dumbbell Lateral Raise"])
add("Cable Lateral Raise", "Shoulders", "Cable", "push", [])
add("Machine Lateral Raise", "Shoulders", "Machine", "push", [])
add("Resistance Band Lateral Raise", "Shoulders", "Band", "push", [])
add("Dumbbell Front Raise", "Shoulders", "Dumbbell", "push", [])
add("Barbell Front Raise", "Shoulders", "Barbell", "push", [])
add("Cable Front Raise", "Shoulders", "Cable", "push", [])
add("Plate Front Raise", "Shoulders", "Other", "push", [])
add("Poliquin Raise", "Shoulders", "Dumbbell", "push", [])
add("Front Hold", "Shoulders", "Dumbbell", "push", [])
add("Banded Face Pull", "Shoulders", "Band", "pull", [])
add("Cable Rear Delt Row", "Shoulders", "Cable", "pull", [])
add("Dumbbell Rear Delt Row", "Shoulders", "Dumbbell", "pull", [])
add("Barbell Rear Delt Row", "Shoulders", "Barbell", "pull", [])
add("Reverse Dumbbell Flyes", "Shoulders", "Dumbbell", "pull", ["Rear Delt Fly"])
add("Reverse Dumbbell Flyes on Incline Bench", "Shoulders", "Dumbbell", "pull", [])
add("Reverse Cable Flyes", "Shoulders", "Cable", "pull", ["Cable Reverse Fly"])
add("Reverse Machine Fly", "Shoulders", "Machine", "pull", ["Reverse Pec Deck"])
add("Monkey Row", "Shoulders", "Dumbbell", "pull", [])
add("Barbell Upright Row", "Shoulders", "Barbell", "pull", ["Upright Row"])
add("Band Pull-Apart", "Shoulders", "Band", "pull", [])
add("Cuban Press", "Shoulders", "Dumbbell", "push", [])
add("Band External/Internal Shoulder Rotation", "Shoulders", "Band", "pull", [])
add("Cable External/Internal Shoulder Rotation", "Shoulders", "Cable", "pull", [])
add("Dumbbell Horizontal External/Internal Rotation", "Shoulders", "Dumbbell", "pull", [])
add("Lying Dumbbell External/Internal Rotation", "Shoulders", "Dumbbell", "pull", [])
add("Handstand Push-Up", "Shoulders", "Bodyweight", "push", ["HSPU"])
add("Jerk", "Shoulders", "Barbell", "olympic", [])
add("Power Jerk", "Shoulders", "Barbell", "olympic", [])
add("Split Jerk", "Shoulders", "Barbell", "olympic", [])
add("Squat Jerk", "Shoulders", "Barbell", "olympic", [])
add("Devils Press", "Shoulders", "Dumbbell", "push", ["Devil Press"])
add("Turkish Get-Up", "Shoulders", "Kettlebell", "core", ["TGU"])
add("Kettlebell Halo", "Shoulders", "Kettlebell", "core", [])
add("Wall Walk", "Shoulders", "Bodyweight", "push", [])
add("Pike Push-Up", "Shoulders", "Bodyweight", "push", [])
add("Leaning Lateral Raise", "Shoulders", "Dumbbell", "push", [])

# --- Biceps ---
add("Barbell Curl", "Biceps", "Barbell", "pull", [])
add("EZ Curl", "Biceps", "EZ Bar", "pull", ["EZ Bar Curl"])
add("Dumbbell Curl", "Biceps", "Dumbbell", "pull", ["DB Curl"])
add("Hammer Curl", "Biceps", "Dumbbell", "pull", [])
add("Concentration Curl", "Biceps", "Dumbbell", "pull", [])
add("Preacher Curl", "Biceps", "EZ Bar", "pull", ["Barbell Preacher Curl"])
add("Dumbbell Preacher Curl", "Biceps", "Dumbbell", "pull", [])
add("Spider Curl", "Biceps", "EZ Bar", "pull", [])
add("Incline Dumbbell Curl", "Biceps", "Dumbbell", "pull", [])
add("Drag Curl", "Biceps", "Barbell", "pull", [])
add("Bayesian Curl", "Biceps", "Cable", "pull", [])
add("Reverse Barbell Curl", "Biceps", "Barbell", "pull", [])
add("Reverse Dumbbell Curl", "Biceps", "Dumbbell", "pull", [])
add("Zottman Curl", "Biceps", "Dumbbell", "pull", [])
add("Cable Curl With Bar", "Biceps", "Cable", "pull", [])
add("Cable Curl With Rope", "Biceps", "Cable", "pull", [])
add("Lying Bicep Cable Curl", "Biceps", "Cable", "pull", [])
add("Overhead Cable Curl", "Biceps", "Cable", "pull", [])
add("Cable Crossover Bicep Curl", "Biceps", "Cable", "pull", [])
add("Machine Bicep Curl", "Biceps", "Machine", "pull", [])
add("Kettlebell Curl", "Biceps", "Kettlebell", "pull", [])
add("Bodyweight Curl", "Biceps", "Bodyweight", "pull", [])
add("Resistance Band Curl", "Biceps", "Band", "pull", [])
add("Cross-Body Hammer Curl", "Biceps", "Dumbbell", "pull", [])

# --- Triceps ---
add("Tricep Pushdown", "Triceps", "Cable", "push", ["Tricep Pushdown With Bar", "Pushdown"])
add("Tricep Pushdown With Rope", "Triceps", "Cable", "push", ["Rope Pushdown"])
add("Overhead Cable Triceps Extension", "Triceps", "Cable", "push", [])
add("Crossbody Cable Triceps Extension", "Triceps", "Cable", "push", [])
add("Barbell Lying Triceps Extension", "Triceps", "Barbell", "push", ["Skull Crusher"])
add("Barbell Incline Triceps Extension", "Triceps", "Barbell", "push", [])
add("Barbell Standing Triceps Extension", "Triceps", "Barbell", "push", ["French Press"])
add("EZ Bar Lying Triceps Extension", "Triceps", "EZ Bar", "push", ["EZ Skull Crusher"])
add("Dumbbell Lying Triceps Extension", "Triceps", "Dumbbell", "push", [])
add("Dumbbell Standing Triceps Extension", "Triceps", "Dumbbell", "push", ["Overhead DB Extension"])
add("Smith Machine Skull Crushers", "Triceps", "Smith Machine", "push", [])
add("Tate Press", "Triceps", "Dumbbell", "push", [])
add("Bench Dip", "Triceps", "Bodyweight", "push", [])
add("Tricep Bodyweight Extension", "Triceps", "Bodyweight", "push", [])
add("Machine Overhead Triceps Extension", "Triceps", "Machine", "push", [])
add("Dumbbell Kickback", "Triceps", "Dumbbell", "push", ["Tricep Kickback"])

# --- Quadriceps ---
add("Squat", "Quadriceps", "Barbell", "squat", ["Back Squat", "Barbell Squat"])
add("Front Squat", "Quadriceps", "Barbell", "squat", [])
add("Pause Squat", "Quadriceps", "Barbell", "squat", [])
add("Pin Squat", "Quadriceps", "Barbell", "squat", [])
add("Box Squat", "Quadriceps", "Barbell", "squat", [])
add("Goblet Squat", "Quadriceps", "Dumbbell", "squat", ["Kettlebell Goblet Squat"])
add("Zercher Squat", "Quadriceps", "Barbell", "squat", [])
add("Safety Bar Squat", "Quadriceps", "Barbell", "squat", ["SSB Squat"])
add("Zombie Squat", "Quadriceps", "Barbell", "squat", [])
add("Belt Squat", "Quadriceps", "Machine", "squat", [])
add("Air Squat", "Quadriceps", "Bodyweight", "squat", ["Bodyweight Squat"])
add("Half Air Squat", "Quadriceps", "Bodyweight", "squat", [])
add("Jump Squat", "Quadriceps", "Bodyweight", "squat", [])
add("Bulgarian Split Squat", "Quadriceps", "Dumbbell", "squat", ["Rear Foot Elevated Split Squat"])
add("Leg Press", "Quadriceps", "Machine", "squat", [])
add("Vertical Leg Press", "Quadriceps", "Machine", "squat", [])
add("Hack Squat", "Quadriceps", "Machine", "squat", ["Hack Squat Machine"])
add("Barbell Hack Squat", "Quadriceps", "Barbell", "squat", [])
add("Pendulum Squat", "Quadriceps", "Machine", "squat", [])
add("Landmine Squat", "Quadriceps", "Barbell", "squat", [])
add("Landmine Hack Squat", "Quadriceps", "Barbell", "squat", [])
add("Smith Machine Squat", "Quadriceps", "Smith Machine", "squat", [])
add("Smith Machine Front Squat", "Quadriceps", "Smith Machine", "squat", [])
add("Smith Machine Bulgarian Split Squat", "Quadriceps", "Smith Machine", "squat", [])
add("Dumbbell Squat", "Quadriceps", "Dumbbell", "squat", [])
add("Kettlebell Front Squat", "Quadriceps", "Kettlebell", "squat", [])
add("Barbell Lunge", "Quadriceps", "Barbell", "squat", [])
add("Dumbbell Lunge", "Quadriceps", "Dumbbell", "squat", [])
add("Walking Lunge", "Quadriceps", "Dumbbell", "squat", [])
add("Barbell Walking Lunge", "Quadriceps", "Barbell", "squat", [])
add("Reverse Lunge", "Quadriceps", "Dumbbell", "squat", [])
add("Barbell Reverse Lunge", "Quadriceps", "Barbell", "squat", [])
add("Body Weight Lunge", "Quadriceps", "Bodyweight", "squat", ["Bodyweight Lunge"])
add("Shallow Body Weight Lunge", "Quadriceps", "Bodyweight", "squat", [])
add("Side Lunges", "Quadriceps", "Bodyweight", "squat", ["Lateral Lunge"])
add("Curtsy Lunge", "Quadriceps", "Dumbbell", "squat", [])
add("Jumping Lunge", "Quadriceps", "Bodyweight", "squat", [])
add("Step Up", "Quadriceps", "Dumbbell", "squat", ["Step-Up"])
add("Poliquin Step-Up", "Quadriceps", "Dumbbell", "squat", [])
add("Chair Squat", "Quadriceps", "Bodyweight", "squat", ["Sit-to-Stand"])
add("Leg Extension", "Quadriceps", "Machine", "squat", [])
add("One-Legged Leg Extension", "Quadriceps", "Machine", "squat", ["Single-Leg Extension"])
add("Standing Cable Leg Extension", "Quadriceps", "Cable", "squat", [])
add("Box Jump", "Quadriceps", "Bodyweight", "squat", [])
add("Depth Jump", "Quadriceps", "Bodyweight", "squat", [])
add("Lateral Bound", "Quadriceps", "Bodyweight", "squat", [])
add("Sled Push", "Quadriceps", "Other", "carry", [])
add("Prisoner Get Up", "Quadriceps", "Bodyweight", "squat", [])
add("Cossack Squat", "Quadriceps", "Bodyweight", "squat", [])
add("Standing Hip Flexor Raise", "Quadriceps", "Cable", "core", [])
add("Tibialis Raise", "Calves", "Other", "squat", [])
add("Kettlebell Tibialis Raise", "Calves", "Kettlebell", "squat", [])
add("Tibialis Band Pull", "Calves", "Band", "squat", [])
add("Heel Walk", "Calves", "Bodyweight", "carry", [])
add("Kettlebell Thrusters", "Quadriceps", "Kettlebell", "squat", ["KB Thruster"])

# --- Hamstrings ---
add("Romanian Deadlift", "Hamstrings", "Barbell", "hinge", ["RDL"])
add("Smith Machine Romanian Deadlift", "Hamstrings", "Smith Machine", "hinge", [])
add("Dumbbell Romanian Deadlift", "Hamstrings", "Dumbbell", "hinge", ["DB RDL"])
add("Single Leg Romanian Deadlift", "Hamstrings", "Dumbbell", "hinge", ["SL RDL"])
add("Lying Leg Curl", "Hamstrings", "Machine", "hinge", ["Prone Leg Curl"])
add("Leg Curl", "Hamstrings", "Machine", "hinge", ["Seated or Lying Leg Curl"])
add("Seated Leg Curl", "Hamstrings", "Machine", "hinge", [])
add("Standing Leg Curl", "Hamstrings", "Machine", "hinge", [])
add("One-Legged Lying Leg Curl", "Hamstrings", "Machine", "hinge", [])
add("One-Legged Seated Leg Curl", "Hamstrings", "Machine", "hinge", [])
add("Bodyweight Leg Curl", "Hamstrings", "Bodyweight", "hinge", [])
add("Leg Curl On Ball", "Hamstrings", "Other", "hinge", ["Stability Ball Leg Curl"])
add("Nordic Hamstring Eccentric", "Hamstrings", "Bodyweight", "hinge", ["Nordic Curl"])
add("Reverse Nordic", "Quadriceps", "Bodyweight", "squat", [])
add("Glute Ham Raise", "Hamstrings", "Machine", "hinge", ["GHR"])
add("Band Good Morning", "Hamstrings", "Band", "hinge", [])
add("Cable Pull Through", "Glutes", "Cable", "hinge", ["Pull-Through"])

# --- Glutes ---
add("Hip Thrust", "Glutes", "Barbell", "hinge", ["Barbell Hip Thrust"])
add("Hip Thrust Machine", "Glutes", "Machine", "hinge", [])
add("Smith Machine Hip Thrust", "Glutes", "Smith Machine", "hinge", [])
add("Glute Bridge", "Glutes", "Bodyweight", "hinge", [])
add("One-Legged Glute Bridge", "Glutes", "Bodyweight", "hinge", [])
add("One-Legged Hip Thrust", "Glutes", "Barbell", "hinge", ["Single-Leg Hip Thrust"])
add("Hip Thrust With Band Around Knees", "Glutes", "Band", "hinge", [])
add("Cable Glute Kickback", "Glutes", "Cable", "hinge", [])
add("Machine Glute Kickbacks", "Glutes", "Machine", "hinge", [])
add("Donkey Kicks", "Glutes", "Bodyweight", "hinge", [])
add("Fire Hydrants", "Glutes", "Bodyweight", "hinge", [])
add("Frog Pumps", "Glutes", "Bodyweight", "hinge", [])
add("Dumbbell Frog Pumps", "Glutes", "Dumbbell", "hinge", [])
add("Clamshells", "Glutes", "Band", "hinge", [])
add("Death March with Dumbbells", "Glutes", "Dumbbell", "hinge", [])
add("Reverse Hyperextension", "Glutes", "Machine", "hinge", ["Reverse Hyper"])
add("Hip Abduction Machine", "Glutes", "Machine", "hinge", [])
add("Cable Machine Hip Abduction", "Glutes", "Cable", "hinge", [])
add("Hip Abduction Against Band", "Glutes", "Band", "hinge", [])
add("Standing Hip Abduction Against Band", "Glutes", "Band", "hinge", [])
add("Lateral Walk With Band", "Glutes", "Band", "carry", ["Monster Walk"])
add("Banded Side Kicks", "Glutes", "Band", "hinge", [])
add("Standing Glute Kickback in Machine", "Glutes", "Machine", "hinge", [])
add("Standing Glute Push Down", "Glutes", "Cable", "hinge", [])
add("Kettlebell Windmill", "Glutes", "Kettlebell", "core", [])

# --- Calves ---
add("Calf Raise", "Calves", "Machine", "squat", ["Standing Calf Raise"])
add("Standing Calf Raise", "Calves", "Machine", "squat", [])
add("Seated Calf Raise", "Calves", "Machine", "squat", [])
add("Barbell Standing Calf Raise", "Calves", "Barbell", "squat", [])
add("Barbell Seated Calf Raise", "Calves", "Barbell", "squat", [])
add("Calf Raise in Leg Press", "Calves", "Machine", "squat", [])
add("Donkey Calf Raise", "Calves", "Machine", "squat", [])
add("Heel Raise", "Calves", "Bodyweight", "squat", [])
add("Eccentric Heel Drop", "Calves", "Bodyweight", "squat", [])

# --- Core ---
add("Crunch", "Core", "Bodyweight", "core", [])
add("Sit-Up", "Core", "Bodyweight", "core", [])
add("Bicycle Crunch", "Core", "Bodyweight", "core", [])
add("Oblique Crunch", "Core", "Bodyweight", "core", [])
add("Oblique Sit-Up", "Core", "Bodyweight", "core", [])
add("Cable Crunch", "Core", "Cable", "core", [])
add("Machine Crunch", "Core", "Machine", "core", [])
add("Hanging Leg Raise", "Core", "Bodyweight", "core", [])
add("Hanging Knee Raise", "Core", "Bodyweight", "core", [])
add("Captain's Chair Knee/Leg Raise", "Core", "Machine", "core", ["Captain's Chair"])
add("Lying Leg Raise", "Core", "Bodyweight", "core", [])
add("Dragon Flag", "Core", "Bodyweight", "core", [])
add("Hollow Hold", "Core", "Bodyweight", "core", [])
add("Hollow Body Crunch", "Core", "Bodyweight", "core", [])
add("Dead Bug", "Core", "Bodyweight", "core", [])
add("Dead Bug With Dumbbells", "Core", "Dumbbell", "core", [])
add("Plank", "Core", "Bodyweight", "core", [])
add("Side Plank", "Core", "Bodyweight", "core", [])
add("Kneeling Plank", "Core", "Bodyweight", "core", [])
add("Kneeling Side Plank", "Core", "Bodyweight", "core", [])
add("Dynamic Side Plank", "Core", "Bodyweight", "core", [])
add("Plank with Leg Lifts", "Core", "Bodyweight", "core", [])
add("Plank with Shoulder Taps", "Core", "Bodyweight", "core", [])
add("Weighted Plank", "Core", "Other", "core", [])
add("Copenhagen Plank", "Core", "Bodyweight", "core", [])
add("L-Sit", "Core", "Bodyweight", "core", [])
add("Ab Wheel Roll-Out", "Core", "Other", "core", ["Ab Wheel", "Kneeling Rollout"])
add("Pallof Press", "Core", "Cable", "core", [])
add("Wood Chop", "Core", "Cable", "core", ["High-to-Low", "Low-to-High", "Horizontal", "Cable Wood Chop", "Band Wood Chop"])
add("Landmine Rotation", "Core", "Barbell", "core", ["Landmine Twist"])
add("Core Twist", "Core", "Bodyweight", "core", ["Russian Twist"])
add("Mountain Climbers", "Core", "Bodyweight", "core", [])
add("Jackknife Sit-Up", "Core", "Bodyweight", "core", [])
add("Hanging Sit-Up", "Core", "Bodyweight", "core", [])
add("Hanging Windshield Wiper", "Core", "Bodyweight", "core", [])
add("Lying Windshield Wiper", "Core", "Bodyweight", "core", [])
add("Dumbbell Side Bend", "Core", "Dumbbell", "core", [])
add("Kettlebell Plank Pull Through", "Core", "Kettlebell", "core", [])
add("Ball Slams", "Core", "Medicine Ball", "core", ["Medicine Ball Slam"])
add("Toes to Bar", "Core", "Bodyweight", "core", ["T2B"])
add("V-Up", "Core", "Bodyweight", "core", [])

# --- Forearms ---
add("Barbell Wrist Curl", "Forearms", "Barbell", "pull", [])
add("Barbell Wrist Curl Behind the Back", "Forearms", "Barbell", "pull", [])
add("Barbell Wrist Extension", "Forearms", "Barbell", "pull", [])
add("Dumbbell Wrist Curl", "Forearms", "Dumbbell", "pull", [])
add("Dumbbell Wrist Extension", "Forearms", "Dumbbell", "pull", [])
add("Plate Wrist Curl", "Forearms", "Other", "pull", [])
add("Wrist Roller", "Forearms", "Other", "pull", [])
add("Farmers Walk", "Forearms", "Dumbbell", "carry", ["Farmer's Carry", "Farmer Walk"])
add("Bar Hang", "Forearms", "Bodyweight", "carry", ["Dead Hang"])
add("One-Handed Bar Hang", "Forearms", "Bodyweight", "carry", [])
add("Plate Pinch", "Forearms", "Other", "carry", [])
add("Gripper", "Forearms", "Other", "pull", ["Hand Gripper"])
add("Fat Bar Deadlift", "Forearms", "Barbell", "hinge", ["Axle Deadlift"])
add("Towel Pull-Up", "Forearms", "Bodyweight", "pull", [])
add("Suitcase Carry", "Forearms", "Dumbbell", "carry", [])

# --- Neck ---
add("Lying Neck Curl", "Neck", "Other", "pull", [])
add("Lying Neck Extension", "Neck", "Other", "pull", [])
add("Prone Neck Bridge", "Neck", "Bodyweight", "core", [])
add("Supine Neck Bridge", "Neck", "Bodyweight", "core", [])

# --- Cardio (duration logged by user at workout time) ---
add("Rowing Machine", "Cardio", "Machine", "cardio", ["Erg", "Concept2"])
add("Stationary Bike", "Cardio", "Machine", "cardio", ["Exercise Bike"])
add("Treadmill Run", "Cardio", "Machine", "cardio", [])
add("Elliptical", "Cardio", "Machine", "cardio", [])
add("Stair Climber", "Cardio", "Machine", "cardio", ["Stairmaster"])
add("Jump Rope", "Cardio", "Other", "cardio", ["Skipping Rope"])
add("Battle Ropes", "Cardio", "Other", "cardio", [])
add("Prowler Push", "Cardio", "Other", "cardio", ["Sled Push Finisher"])
add("Assault Bike", "Cardio", "Machine", "cardio", ["Air Bike", "Fan Bike"])
add("SkiErg", "Cardio", "Machine", "cardio", [])
add("Burpees", "Cardio", "Bodyweight", "cardio", [])
add("Jacob's Ladder", "Cardio", "Machine", "cardio", ["Ladder Climber"])
add("VersaClimber", "Cardio", "Machine", "cardio", ["Vertical Climber"])
add("ARC Trainer", "Cardio", "Machine", "cardio", ["Cybex ARC"])
add("Lateral Elliptical", "Cardio", "Machine", "cardio", ["Helix", "Octane"])
add("Incline Treadmill Walk", "Cardio", "Machine", "cardio", ["Incline Walk"])
add("Curved Treadmill", "Cardio", "Machine", "cardio", ["Woodway", "Manual Treadmill"])
add("Precor AMT", "Cardio", "Machine", "cardio", ["Adaptive Motion Trainer"])
add("Spin Bike", "Cardio", "Machine", "cardio", ["Indoor Cycle"])
add("Recumbent Bike", "Cardio", "Machine", "cardio", [])
add("Kettlebell Swing Intervals", "Cardio", "Kettlebell", "cardio", ["KB Swing Intervals"])
add("Medicine Ball Slam Intervals", "Cardio", "Medicine Ball", "cardio", ["Ball Slam Intervals"])
add("Box Step-Ups", "Cardio", "Bodyweight", "cardio", ["Step Ups"])


def slot(name: str, sets: int, lo: int, hi: int, rest: int | None = None) -> dict:
    item = {
        "name": name,
        "targetSets": sets,
        "targetRepsMin": lo,
        "targetRepsMax": hi,
    }
    if rest is not None:
        item["restSeconds"] = rest
    return item


def template(name: str, exercises: list[dict], weekdays: list[int] | None = None) -> dict:
    item: dict = {"name": name, "exercises": exercises}
    if weekdays is not None:
        item["suggestedWeekdays"] = weekdays
    return item


# Strength-leaning defaults from the plan examples.
PUSH_A = [
    slot("Bench Press", 4, 6, 8, 150),
    slot("Overhead Press", 3, 8, 10, 120),
    slot("Incline Dumbbell Press", 3, 10, 12),
    slot("Cable Lateral Raise", 3, 12, 15, 60),
    slot("Tricep Pushdown With Rope", 3, 12, 15, 60),
]
PUSH_B = [
    slot("Overhead Press", 4, 5, 8, 150),
    slot("Incline Bench Press", 3, 8, 10),
    slot("Dumbbell Chest Press", 3, 10, 12),
    slot("Lateral Raise", 3, 12, 15, 60),
    slot("Overhead Cable Triceps Extension", 3, 12, 15, 60),
]
PULL_A = [
    slot("Barbell Row", 4, 6, 8, 150),
    slot("Pull-Up", 3, 6, 10, 120),
    slot("Lat Pulldown Pronated", 3, 10, 12),
    slot("Face Pull", 3, 15, 20, 60),
    slot("Barbell Curl", 3, 10, 12, 60),
]
PULL_B = [
    slot("Deadlift", 3, 4, 6, 180),
    slot("Lat Pulldown", 3, 8, 10),
    slot("Dumbbell Row", 3, 10, 12),
    slot("Face Pull", 3, 12, 15, 60),
    slot("Hammer Curl", 3, 10, 12, 60),
]
LEGS_A = [
    slot("Squat", 4, 6, 8, 180),
    slot("Romanian Deadlift", 3, 8, 10, 150),
    slot("Leg Press", 3, 10, 12),
    slot("Leg Extension", 3, 12, 15, 60),
    slot("Lying Leg Curl", 3, 12, 15, 60),
    slot("Standing Calf Raise", 4, 12, 15, 45),
]
LEGS_B = [
    slot("Deadlift", 3, 4, 6, 180),
    slot("Front Squat", 3, 6, 8, 150),
    slot("Bulgarian Split Squat", 3, 8, 10),
    slot("Seated Leg Curl", 3, 10, 12),
    slot("Hip Thrust", 3, 8, 12),
    slot("Seated Calf Raise", 4, 12, 15, 45),
]
UPPER_A = [
    slot("Bench Press", 4, 6, 8, 150),
    slot("Barbell Row", 4, 6, 8, 150),
    slot("Overhead Press", 3, 8, 10),
    slot("Lat Pulldown", 3, 8, 12),
    slot("Barbell Curl", 3, 10, 12, 60),
    slot("Tricep Pushdown", 3, 10, 12, 60),
]
UPPER_B = [
    slot("Incline Dumbbell Press", 3, 8, 12),
    slot("Pull-Up", 3, 6, 10),
    slot("Dumbbell Shoulder Press", 3, 8, 12),
    slot("Cable Close Grip Seated Row", 3, 8, 12),
    slot("Lateral Raise", 3, 12, 15, 60),
    slot("Face Pull", 3, 12, 15, 60),
]
LOWER_A = [
    slot("Squat", 4, 6, 8, 180),
    slot("Romanian Deadlift", 3, 8, 10),
    slot("Leg Press", 3, 10, 12),
    slot("Leg Curl", 3, 10, 12),
    slot("Calf Raise", 4, 12, 15, 45),
]
LOWER_B = [
    slot("Deadlift", 3, 4, 6, 180),
    slot("Front Squat", 3, 6, 8),
    slot("Hip Thrust", 3, 8, 12),
    slot("Walking Lunge", 3, 8, 12),
    slot("Seated Calf Raise", 4, 12, 15, 45),
]
FULL_A = [
    slot("Squat", 3, 6, 8, 150),
    slot("Bench Press", 3, 6, 8, 150),
    slot("Barbell Row", 3, 6, 8),
    slot("Overhead Press", 2, 8, 10),
    slot("Romanian Deadlift", 2, 8, 10),
]
FULL_B = [
    slot("Deadlift", 3, 4, 6, 180),
    slot("Incline Dumbbell Press", 3, 8, 10),
    slot("Pull-Up", 3, 6, 10),
    slot("Dumbbell Shoulder Press", 2, 8, 12),
    slot("Walking Lunge", 2, 8, 12),
]
FULL_C = [
    slot("Front Squat", 3, 6, 8, 150),
    slot("Overhead Press", 3, 6, 8),
    slot("Dumbbell Row", 3, 8, 10),
    slot("Hip Thrust", 3, 8, 12),
    slot("Face Pull", 2, 12, 15, 60),
]
CHEST_DAY = [
    slot("Bench Press", 4, 6, 8, 150),
    slot("Incline Dumbbell Press", 3, 8, 12),
    slot("Cable Chest Press", 3, 10, 12),
    slot("Dumbbell Chest Fly", 3, 12, 15, 60),
    slot("Push-Up", 2, 10, 15, 60),
]
BACK_DAY = [
    slot("Deadlift", 3, 4, 6, 180),
    slot("Barbell Row", 4, 6, 8),
    slot("Lat Pulldown", 3, 8, 12),
    slot("Dumbbell Row", 3, 8, 12),
    slot("Face Pull", 3, 12, 15, 60),
]
SHOULDERS_DAY = [
    slot("Overhead Press", 4, 6, 8, 150),
    slot("Dumbbell Shoulder Press", 3, 8, 12),
    slot("Lateral Raise", 4, 12, 15, 60),
    slot("Face Pull", 3, 12, 15, 60),
    slot("Reverse Dumbbell Flyes", 3, 12, 15, 60),
]
LEGS_BRO = [
    slot("Squat", 4, 6, 8, 180),
    slot("Romanian Deadlift", 3, 8, 10),
    slot("Leg Press", 3, 10, 12),
    slot("Leg Extension", 3, 12, 15),
    slot("Lying Leg Curl", 3, 12, 15),
    slot("Calf Raise", 4, 12, 15, 45),
]
ARMS_DAY = [
    slot("Close-Grip Bench Press", 3, 6, 8),
    slot("Barbell Curl", 3, 8, 10),
    slot("Tricep Pushdown With Rope", 3, 10, 12),
    slot("Incline Dumbbell Curl", 3, 10, 12),
    slot("Overhead Cable Triceps Extension", 3, 10, 12),
    slot("Hammer Curl", 3, 10, 12, 60),
]
CHEST_BACK_A = [
    slot("Bench Press", 4, 6, 8, 150),
    slot("Barbell Row", 4, 6, 8, 150),
    slot("Incline Dumbbell Press", 3, 8, 12),
    slot("Pull-Up", 3, 6, 10),
    slot("Dumbbell Chest Fly", 3, 12, 15, 60),
]
CHEST_BACK_B = [
    slot("Incline Bench Press", 4, 6, 8),
    slot("Deadlift", 3, 4, 6, 180),
    slot("Machine Chest Press", 3, 8, 12),
    slot("Lat Pulldown", 3, 8, 12),
    slot("Face Pull", 3, 12, 15, 60),
]
SHOULDERS_ARMS_A = [
    slot("Overhead Press", 4, 6, 8, 150),
    slot("Lateral Raise", 4, 12, 15, 60),
    slot("Barbell Curl", 3, 8, 10),
    slot("Tricep Pushdown", 3, 10, 12),
    slot("Face Pull", 3, 12, 15, 60),
]
SHOULDERS_ARMS_B = [
    slot("Dumbbell Shoulder Press", 4, 8, 10),
    slot("Cable Lateral Raise", 3, 12, 15, 60),
    slot("Incline Dumbbell Curl", 3, 10, 12),
    slot("Overhead Cable Triceps Extension", 3, 10, 12),
    slot("Hammer Curl", 3, 10, 12, 60),
]
UPPER_POWER = [
    slot("Bench Press", 5, 3, 5, 180),
    slot("Barbell Row", 5, 3, 5, 180),
    slot("Overhead Press", 4, 3, 5, 150),
    slot("Weighted Pull-Up", 3, 4, 6, 150),
]
LOWER_POWER = [
    slot("Squat", 5, 3, 5, 180),
    slot("Deadlift", 3, 3, 5, 180),
    slot("Front Squat", 3, 4, 6, 150),
    slot("Barbell Walking Lunge", 3, 6, 8),
]
UPPER_HYP = [
    slot("Incline Dumbbell Press", 4, 8, 12),
    slot("Lat Pulldown", 4, 8, 12),
    slot("Dumbbell Shoulder Press", 3, 8, 12),
    slot("Cable Close Grip Seated Row", 3, 8, 12),
    slot("Lateral Raise", 3, 12, 15, 60),
    slot("Barbell Curl", 3, 10, 12, 60),
    slot("Tricep Pushdown", 3, 10, 12, 60),
]
LOWER_HYP = [
    slot("Leg Press", 4, 10, 12),
    slot("Romanian Deadlift", 3, 8, 12),
    slot("Bulgarian Split Squat", 3, 8, 12),
    slot("Leg Extension", 3, 12, 15),
    slot("Lying Leg Curl", 3, 12, 15),
    slot("Hip Thrust", 3, 10, 12),
    slot("Calf Raise", 4, 12, 15, 45),
]
BACK_SHOULDERS = [
    slot("Barbell Row", 4, 6, 8),
    slot("Pull-Up", 3, 6, 10),
    slot("Overhead Press", 4, 6, 8),
    slot("Lat Pulldown", 3, 8, 12),
    slot("Lateral Raise", 3, 12, 15, 60),
    slot("Face Pull", 3, 12, 15, 60),
]
CHEST_ARMS = [
    slot("Bench Press", 4, 6, 8, 150),
    slot("Incline Dumbbell Press", 3, 8, 12),
    slot("Close-Grip Bench Press", 3, 6, 8),
    slot("Barbell Curl", 3, 8, 10),
    slot("Tricep Pushdown With Rope", 3, 10, 12),
    slot("Hammer Curl", 3, 10, 12, 60),
]


SPLITS = [
    {
        "name": "Push Pull Legs (3-day)",
        "description": "Classic PPL run three days per week. Rotate Push, Pull, then Legs.",
        "daysPerWeek": 3,
        "templates": [
            template("Push", PUSH_A, [2]),
            template("Pull", PULL_A, [4]),
            template("Legs", LEGS_A, [6]),
        ],
    },
    {
        "name": "Push Pull Legs (6-day)",
        "description": "High-frequency PPL with A/B variants so you hit each pattern twice per week.",
        "daysPerWeek": 6,
        "templates": [
            template("Push A", PUSH_A, [2]),
            template("Pull A", PULL_A, [3]),
            template("Legs A", LEGS_A, [4]),
            template("Push B", PUSH_B, [5]),
            template("Pull B", PULL_B, [6]),
            template("Legs B", LEGS_B, [7]),
        ],
    },
    {
        "name": "Upper / Lower",
        "description": "Four-day upper/lower split with two unique days for each.",
        "daysPerWeek": 4,
        "templates": [
            template("Upper A", UPPER_A, [2]),
            template("Lower A", LOWER_A, [3]),
            template("Upper B", UPPER_B, [5]),
            template("Lower B", LOWER_B, [6]),
        ],
    },
    {
        "name": "Full Body",
        "description": "Three non-competing full-body sessions. Efficient if you train 3 days a week.",
        "daysPerWeek": 3,
        "templates": [
            template("Full Body A", FULL_A, [2]),
            template("Full Body B", FULL_B, [4]),
            template("Full Body C", FULL_C, [6]),
        ],
    },
    {
        "name": "Bro Split",
        "description": "Five-day body-part split: Chest, Back, Shoulders, Legs, Arms.",
        "daysPerWeek": 5,
        "templates": [
            template("Chest", CHEST_DAY, [2]),
            template("Back", BACK_DAY, [3]),
            template("Shoulders", SHOULDERS_DAY, [4]),
            template("Legs", LEGS_BRO, [5]),
            template("Arms", ARMS_DAY, [6]),
        ],
    },
    {
        "name": "PPLUL (5-day hybrid)",
        "description": "Push, Pull, Legs, then extra Upper and Lower days for more volume.",
        "daysPerWeek": 5,
        "templates": [
            template("Push", PUSH_A, [2]),
            template("Pull", PULL_A, [3]),
            template("Legs", LEGS_A, [4]),
            template("Upper", UPPER_B, [5]),
            template("Lower", LOWER_B, [6]),
        ],
    },
    {
        "name": "Arnold Split",
        "description": "Chest/Back, Shoulders/Arms, Legs — each twice per week (6 days).",
        "daysPerWeek": 6,
        "templates": [
            template("Chest/Back A", CHEST_BACK_A, [2]),
            template("Shoulders/Arms A", SHOULDERS_ARMS_A, [3]),
            template("Legs A", LEGS_A, [4]),
            template("Chest/Back B", CHEST_BACK_B, [5]),
            template("Shoulders/Arms B", SHOULDERS_ARMS_B, [6]),
            template("Legs B", LEGS_B, [7]),
        ],
    },
    {
        "name": "PHUL",
        "description": "Power Hypertrophy Upper Lower: two heavy power days and two hypertrophy days.",
        "daysPerWeek": 4,
        "templates": [
            template("Upper Power", UPPER_POWER, [2]),
            template("Lower Power", LOWER_POWER, [3]),
            template("Upper Hypertrophy", UPPER_HYP, [5]),
            template("Lower Hypertrophy", LOWER_HYP, [6]),
        ],
    },
    {
        "name": "PHAT",
        "description": "Power Hypertrophy Adaptive Training: two power days plus three hypertrophy days.",
        "daysPerWeek": 5,
        "templates": [
            template("Upper Power", UPPER_POWER, [2]),
            template("Lower Power", LOWER_POWER, [3]),
            template("Back/Shoulders", BACK_SHOULDERS, [4]),
            template("Lower Hypertrophy", LOWER_HYP, [5]),
            template("Chest/Arms", CHEST_ARMS, [6]),
        ],
    },
    {
        "name": "Upper/Lower/Push/Pull/Legs",
        "description": "Five-day hybrid: Upper, Lower, then a PPL wave for extra frequency.",
        "daysPerWeek": 5,
        "templates": [
            template("Upper", UPPER_A, [2]),
            template("Lower", LOWER_A, [3]),
            template("Push", PUSH_B, [4]),
            template("Pull", PULL_B, [5]),
            template("Legs", LEGS_B, [6]),
        ],
    },
]


STARTER_TEMPLATES = [
    template(
        "Push Day",
        [
            slot("Bench Press", 4, 6, 8, 150),
            slot("Overhead Press", 3, 8, 10, 120),
            slot("Incline Dumbbell Press", 3, 10, 12),
            slot("Lateral Raise", 3, 12, 15, 60),
            slot("Tricep Pushdown", 3, 12, 15, 60),
        ],
    ),
    template(
        "Pull Day",
        [
            slot("Barbell Row", 4, 6, 8, 150),
            slot("Pull-Up", 3, 6, 10, 120),
            slot("Lat Pulldown", 3, 10, 12),
            slot("Face Pull", 3, 15, 20, 60),
            slot("Barbell Curl", 3, 10, 12, 60),
        ],
    ),
    template(
        "Leg Day",
        [
            slot("Squat", 4, 6, 8, 180),
            slot("Romanian Deadlift", 3, 8, 10, 150),
            slot("Leg Press", 3, 10, 12),
            slot("Leg Extension", 3, 12, 15, 60),
            slot("Lying Leg Curl", 3, 12, 15, 60),
            slot("Calf Raise", 4, 12, 15, 45),
        ],
    ),
    template(
        "Upper Body",
        [
            slot("Bench Press", 4, 6, 8, 150),
            slot("Barbell Row", 4, 6, 8, 150),
            slot("Overhead Press", 3, 8, 10),
            slot("Lat Pulldown", 3, 8, 12),
            slot("Barbell Curl", 3, 10, 12, 60),
            slot("Tricep Pushdown", 3, 10, 12, 60),
        ],
    ),
    template(
        "Lower Body",
        [
            slot("Squat", 4, 6, 8, 180),
            slot("Romanian Deadlift", 3, 8, 10),
            slot("Leg Press", 3, 10, 12),
            slot("Leg Curl", 3, 10, 12),
            slot("Calf Raise", 4, 12, 15, 45),
        ],
    ),
    template(
        "Full Body",
        [
            slot("Squat", 3, 6, 8, 150),
            slot("Bench Press", 3, 6, 8, 150),
            slot("Barbell Row", 3, 6, 8),
            slot("Overhead Press", 2, 8, 10),
            slot("Romanian Deadlift", 2, 8, 10),
        ],
    ),
]


def main() -> None:
    unique: dict[str, dict] = {}
    for name, muscle, equipment, pattern, aliases in EXERCISES:
        if name in SKIP_NAMES:
            continue
        if name in unique:
            raise SystemExit(f"Duplicate exercise name: {name}")
        unique[name] = {
            "name": name,
            "muscleGroup": muscle,
            "equipment": equipment,
            "movementPattern": pattern,
            "aliases": aliases,
        }

    referenced: set[str] = set()
    for split in SPLITS:
        for tmpl in split["templates"]:
            for ex in tmpl["exercises"]:
                referenced.add(ex["name"])
    for tmpl in STARTER_TEMPLATES:
        for ex in tmpl["exercises"]:
            referenced.add(ex["name"])

    missing = sorted(referenced - set(unique))
    if missing:
        raise SystemExit(f"Templates reference unknown exercises: {missing}")

    payload = {
        "exercises": list(unique.values()),
        "splits": SPLITS,
        "starterTemplates": STARTER_TEMPLATES,
    }

    out = Path(__file__).resolve().parents[1] / "FitnessTracker" / "Resources" / "PresetData.json"
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"Wrote {len(unique)} exercises, {len(SPLITS)} splits, {len(STARTER_TEMPLATES)} starters → {out}")


if __name__ == "__main__":
    main()
