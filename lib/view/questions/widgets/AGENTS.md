# question Widgets Agent Instructions

## Responsibility

`lib/view/questions/widgets` contains reusable question form, picker, and preview widgets.

## Rules

- Keep widgets controlled by explicit values and callbacks.
- Use safe image preview bounds based on the provided `imageRatio`.
- Show upload progress and retry affordances without owning upload logic.
- Keep form labels, helper text, and validation messages concise.

## Warnings

- Do not calculate server payloads here.
- Do not import service implementations or generated client types.
