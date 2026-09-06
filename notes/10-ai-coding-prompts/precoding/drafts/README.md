# From Observed Problem to Implemented PoC / MVP 

### Conceptual stages

* exploration
* architecture
* refactors
* reviews
* greenfield development
* agent execution



---

## **Precoding Phase:**

This is the planning and validation phase before any actual coding starts. It is all about defining the problem and ensuring you have a feasible solution space. This phase ensures that the groundwork is solid before moving into implementation. Here's the precise order:

1. **Problem Formalization**
    * **Goal**: Convert the observed real-world practice into a precise, formal problem statement.
    * **What you do**: Ensure the human activity is well understood, define goals, implicit constraints, and make sure you know the problem well enough to begin automation planning.
2. **Automation Boundary**
    * **Goal**: Define what parts of the workflow are candidates for automation and which parts should remain human-in-the-loop or unchanged.
    * **What you do**: Decide which parts can be automated, considering both feasibility and the value of automating each part. Explicitly leave out what doesn’t need to be automated.
3. **Architecture Space / System Design Exploration**
    * **Goal**: Explore various system architectures that could satisfy the automation goals and constraints.
    * **What you do**: Investigate high-level system designs, considering trade-offs in deployment models, technologies, interaction models, and computing topology. Do not decide on one solution yet - just explore possibilities.
4. **Architecture Selection and Justification**
    * **Goal**: **Choose** the best architecture from the exploration phase based on detailed justification.
    * **What you do**: From the exploration phase, pick one architecture and justify it explicitly, comparing it against the others.
5. **Feasibility Validation for Selected Architecture**
    * **Goal**: Validate critical assumptions and ensure the chosen architecture is feasible before proceeding to full development.
    * **What you do**: Run tests, gather evidence, and validate that the selected architecture works under real-world conditions and constraints. Confirm assumptions like device capabilities, network speeds, data security, etc.
6. **Minimal Viable Product (MVP) Definition**
    * **Goal**: Define the core MVP that delivers value with the minimal features required to validate the concept.
    * **What you do**: Break down what the first version of the system must do, define the user stories, and prioritize core features that directly solve the problem. Keep the scope focused.

---

## **Coding / Implementation Phase:**

Once the **precoding** phase has been completed and all the **key decisions** are locked down, you move into **coding**.

### 7. **Implementation**

* **Goal**: Develop the system based on the architecture and MVP definition.
* **Output**: Full codebase, libraries, and apps.
* **What you do**: Write the code, integrate components, and make sure the system meets the **MVP**’s functional goals. This phase also includes detailed **unit testing**, **integration testing**, and **debugging**.

**Key milestones** during this phase:

* **Prototyping** (if necessary): Sometimes, rapid prototypes are needed to test certain assumptions before full implementation begins.
* **Feature Development**: Build out the features as defined in the MVP.
* **User Testing**: Ensure the core workflows are solid by gathering real-world feedback on the MVP and iterating based on results.

---

## **Final Phase:**

After the MVP is implemented, it goes through:

* **User Validation**
* **Post-MVP Iterations**

---

### **Why this Phase Division Works:**

* **Precoding**: You are ensuring that **decisions are made based on solid problem understanding**, technical feasibility, and a well-defined scope before committing resources to coding. This significantly reduces the risk of building something that doesn't solve the problem effectively.
* **Coding/Implementation**: Once you have a fully formed architecture and a focused MVP, the implementation phase becomes much clearer and easier to execute, reducing ambiguity and wasted effort.

---

### **In Summary**:

Your process is structured and organized in two distinct phases:

1. **Precoding** (planning, validating assumptions, and defining architecture)
2. **Coding/Implementation** (developing the actual product based on well-formed architecture and MVP)

This ensures a **methodical, risk-mitigated approach** to software development. You’re building a foundation that minimizes uncertainty and maximizes the chance of building something that actually meets the real-world needs.
