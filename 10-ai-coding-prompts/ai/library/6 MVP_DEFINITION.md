# 6 MVP_DEFINITION.md

## Minimal Viable Product (MVP) Definition

---

## Purpose

This document defines the **Minimal Viable Product (MVP)** for the automation system
based on the selected architecture from `ARCHITECTURE_DECISION.md` and the feasibility
validation plan from `FEASIBILITY_PLAN.md`.

The MVP is designed to:

* **demonstrate core functionality**
* **validate critical assumptions** with real-world usage
* **provide a foundation** for iterative development

This document ensures that the MVP remains focused on **high-value features** and avoids unnecessary scope creep.

---

## Preconditions

* A completed `ARCHITECTURE_DECISION.md` has been reviewed.
* A completed `FEASIBILITY_PLAN.md` has been validated.
* The **selected architecture** is clearly understood and agreed upon.

If these conditions are not met, STOP and revisit `ARCHITECTURE_DECISION.md` and `FEASIBILITY_PLAN.md`.

---

## Instructions to the AI

You are defining the **MVP** for the selected architecture.

You must:

* focus only on **core features** that prove the system’s value
* **prioritize simplicity** and **critical functionality**
* **minimize scope** to avoid distractions
* clearly separate **core functionality** from **future enhancements**
* define clear **user-facing deliverables**

You must not:

* propose additional features outside the scope of the MVP
* design complete user interfaces or fine-tune algorithms beyond the MVP requirements
* estimate long-term development schedules or costs

---

## Required Inputs

Treat the following as authoritative inputs:

* `ARCHITECTURE_DECISION.md`
* `FEASIBILITY_PLAN.md`
* `OBSERVED_PROBLEM.md`

All reasoning must trace back to these documents.

---

## Required Output Structure

Produce the following sections in order.

---

## 1. MVP Scope Definition

Define **what is included in the MVP**. List the **core features** that must be delivered.

The MVP should focus on demonstrating the **primary functionality** of the system. Do not introduce additional features unless they are essential to the core value proposition.

### Examples:

* **Image Capture**: Mobile app captures a high-resolution image of the mouse spleen on millimeter graph paper.
* **Area Estimation**: The system provides an automated estimation of the organ’s area based on image processing.
* **Feedback Loop**: Users can validate or adjust the results.

### Exclusions:

* Complex analysis (e.g., multi-organ recognition, 3D reconstruction)
* Advanced user interface (UI) features (e.g., advanced settings, multiple image uploads)
* Full-scale performance optimization (focus on core features over scalability)

---

## 2. Core Assumptions

List the **critical assumptions** that must hold true for the MVP to be successful. These assumptions were identified in `FEASIBILITY_PLAN.md` and must be explicitly validated.

For each assumption:

* describe the assumption
* explain why it is critical for the MVP
* define how this will be validated

---

## 3. User Stories and Acceptance Criteria

Define the **user stories** that capture the **primary tasks** users need to perform with the MVP.

For each user story, provide the **acceptance criteria** that must be met.

Example user stories:

* **User Story 1: Image Capture**
    * As a biologist, I want to take a photo of the mouse spleen on the graph paper so that I can analyze its area.
    * **Acceptance Criteria**:
        * The app must successfully capture and save the photo in high resolution.
        * The camera preview must display the millimeter grid clearly.
* **User Story 2: Area Estimation**
    * As a biologist, I want the app to automatically estimate the area of the spleen from the photo so that I do not need to do it manually.
    * **Acceptance Criteria**:
        * The system must estimate the area and display it in square millimeters.
        * The area estimate must be within 5% of a manually calculated area (using a standard reference).

---

## 4. Non-Features (Out of MVP Scope)

Explicitly state **what is not included** in the MVP.

This section should outline any desired features or enhancements that **will not** be part of the MVP.

Examples:

* **3D Reconstruction**: Multi-organ recognition is out of scope for the MVP.
* **Advanced Image Processing**: No advanced filters or distortion corrections beyond basic area estimation.
* **Cloud Integration**: No cloud-based storage or processing in the MVP.

This section helps keep the MVP scope focused and prevents unnecessary feature creep.

---

## 5. MVP Deliverables

Define **what will be delivered** as part of the MVP.

Deliverables should include:

* A working **mobile app** that can capture images and estimate organ area.
* A **detailed report** on feasibility validation, including any outstanding risks or assumptions that could be carried forward.
* **User documentation** for the MVP, explaining the basic workflow for capturing and analyzing photos.

---

## 6. MVP Evaluation Criteria

Define **how success will be measured** for the MVP.

These criteria should reflect the core functionality and goals of the MVP.

Examples of evaluation criteria:

* The **system’s accuracy** in estimating the organ area (validated against manual measurements).
* **User feedback** on usability (ability to take clear photos and interpret results).
* **Performance** of the system (speed of image processing and area estimation).

These criteria will help determine if the MVP has achieved its objectives and whether it is ready for further iteration.

---

## 7. Post-MVP Plans

Outline the **next steps** after the MVP is completed.

This section should clarify what is expected after the MVP is validated and user feedback is gathered.

For example:

* **Iterate on UI/UX**: Based on user feedback, refine the interface to improve usability.
* **Scale Processing**: Optimize the image analysis process to handle higher volumes of images.
* **Add Additional Features**: Integrate 3D reconstruction or multi-organ recognition if validated by user demand.

These post-MVP plans are not part of the MVP itself but provide a roadmap for future development.

---

## 8. Feasibility Validation Follow-up

Explain how the **feasibility validation steps** will be rolled into the MVP development process.

* Any unresolved issues from the feasibility plan (e.g., hardware constraints, performance limitations) should be addressed during the MVP phase.
* Clarify **how the MVP will be used** to confirm critical assumptions.

---

## Stopping Condition

Stop after completing the above sections.

Do not:

* Propose new features outside the MVP scope.
* Design full-scale systems.
* Finalize non-MVP deliverables.

This document represents the **MVP definition**, not the full product roadmap.

---

## Intended Use

This artifact is meant to:

* Define a **focused MVP** that demonstrates the core value of the system.
* Guide **early development** and **user feedback**.
* Inform the transition from MVP to post-MVP iterations.

Once the MVP is validated, this document will be archived, and development will move toward full-scale implementation.

---

End of prompt.
