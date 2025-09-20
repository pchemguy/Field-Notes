### Storage Considerations for a New PC, Part 1: Structuring Internal Storage for Robust Migration and Failure Recovery

**1. Introduction**
- **Hook:** The initial choice every power user faces with a new machine: accept the pre-installed OS or start fresh.
- **Thesis:** Acknowledge the upfront effort of a clean setup but assert that the long-term gains in manageability, resilience, and performance are worth the investment. 
- **The Central Question:** A clean install requires a plan. How should we structure storage from the outset to simplify future migrations and recovery?
- **Roadmap:**
    - State that this is **Part 1**, focusing on the philosophy and strategy for **internal storage**.
    - Briefly state the goal: to create a logical structure based on a file's role and recovery cost.
    - Introduce and link to **Part 2**, framing it as the essential guide to creating the tool needed to implement this strategy.
**2. A Guiding Philosophy: Classifying Data by Recovery Cost**
- **Core Principle:** The foundation of a resilient storage architecture is not drive speed, but a clear understanding of what it would cost—in time and effort—to recover different types of data after a failure.
- **Category 1: Ephemeral System Files (Low Recovery Cost)**
    - **What they are:** Windows OS files, drivers, core runtimes (VC++, .NET).
    - **Recovery Method:** Reinstallation. Backups are of limited value beyond an initial "golden image."
    - **Conclusion:** These files are replaceable and should be isolated on a dedicated system partition.
- **Category 2: Program Files (Variable Recovery Cost)**
    - **What they are:** Third-party applications (Office, CAD, developer tools).
    - **Recovery Method:** Reinstallation is possible, but configuration and setup can be time-consuming.
    - **The Key Distinction:** This section introduces the critical concept of **software portability** as a factor that dramatically lowers recovery cost and simplifies management.
- **Category 3: User-Generated Data (High Recovery Cost)**
    - **What they are:** Documents, project files, photos, personal settings.
    - **Recovery Method:** Only recoverable from backups. Irreplaceable.
    - **Conclusion:** This is the most valuable data and must be isolated from the volatile system partition and backed up differently.
**3. From Philosophy to Practice: Organizing the Workstation**
- **Hardware Roles:** A brief confirmation of the standard best practice: a fast SSD for the OS and active programs/data, and a larger HDD for archives, downloads, and less critical files.
- **The Case for a Dedicated Programs Partition:**
    - Explain the limitations of installing everything to `C:\Program Files`. This increases the size and complexity of the system partition.
    - Champion the use of **portable and pseudo-portable applications**.
    - Explain how isolating these on their own partition allows them to be backed up and restored as a single unit, independent of the OS.
- **Taming the Windows User Profile:**
    - Acknowledge that Windows, by default, mixes high- and low-value data in the user profile (`C:\Users\Username`).
    - Provide the rationale for relocating specific folders off the system partition.
        - **High-Volume/Low-Value:** `Downloads`, `Temp`. These belong on a slower, larger drive if available.
        - **High-Value Data:** `Documents`, `Desktop`. These belong on a dedicated data partition for targeted backups.
    - Briefly mention the methods (Junction points vs. changing Windows settings).
**4. The Blueprint: A Practical Partitioning Scheme**
- **The Goal:** Translate the principles above into a concrete partition layout on the primary system SSD.
- **The Partition Table:**
    - Present your table with `System`, `Portable Programs`, `Data`, and `Buffer` partitions.
    - **System Partition:** Explain the sizing rationale (OS + essential, non-portable applications + headroom for updates).
    - **Portable Programs Partition:** Explain its purpose and sizing based on expected software needs.
    - **Data Partition:** Explain its role for active user files and sizing for current projects.
- **A Note on Free Space and Over-Provisioning:**
    - Explain the "Buffer"—unallocated space.
    - Describe its dual purpose: providing flexibility to extend partitions and serving as manual over-provisioning to improve SSD performance and longevity.
**5. Conclusion**
- **Summary:** Reiterate that this structured approach separates data based on its role and recovery cost, leading to a more manageable, resilient system with a more efficient backup workflow.
- **Call to Action:** Emphasize that this plan is only achievable with a clean installation.
- **Strong Transition:** Guide the reader directly to **Part 2**, presenting it as the necessary next step to build the bootable drive required to put this entire strategy into practice.
