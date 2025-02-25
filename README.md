# NEON-Lidar-Data-Processing using R

LiDAR (Light Detection and Ranging)
	•	Remote sensing technology that uses laser pulses to measure distances.
	•	Outputs a 3D “point cloud” of the environment (trees, buildings, ground).
	•	Data is stored in .laz (compressed) or .las (uncompressed) files.

🔹 Each LiDAR point contains:

<img width="436" alt="Screenshot 2025-02-24 at 18 33 21" src="https://github.com/user-attachments/assets/b263260f-c1a0-4803-9cd3-97c63f3eaabd" />

In this dataset, the LiDAR data is unclassified (Classification = 0 for all points).
Without classification, we cannot distinguish between ground, vegetation, and buildings.

Goal:

Assign each LiDAR point to a category:

<img width="300" alt="Screenshot 2025-02-24 at 18 34 32" src="https://github.com/user-attachments/assets/57583f6a-ca8e-4ee4-8e15-ae205f6850b7" />

Why Does This Matter?
	•	Ground points (2) → Needed for Digital Terrain Model (DTM).
	•	Canopy points (5) → Needed for Canopy Height Model (CHM).
	•	Building points (6) → Helps separate man-made structures.
	•	Water points (9) → Helps in hydrological studies.

** Plot of a sample CHM - Canopy Height Model
** 
<img width="678" alt="Screenshot 2025-02-24 at 19 44 30" src="https://github.com/user-attachments/assets/ea34a5ac-8ae1-4b9a-b662-3c4fbb96e6dd" />
<img width="686" alt="Screenshot 2025-02-24 at 19 40 09" src="https://github.com/user-attachments/assets/ae7a0b11-f062-4d03-82bd-59910706da23" />
Dark Green (Low Values) → Short vegetation or bare ground.
	•	Yellow to Light Green → Medium-height trees.
	•	Brown/Pinkish Areas (High Values) → Tall trees (30m+).
 
 Tree Height distribution of the same plot
 
 <img width="618" alt="Screenshot 2025-02-24 at 19 45 51" src="https://github.com/user-attachments/assets/4a06b515-339a-4c9d-85d2-c1a249289972" />

 Canopy Cover Percentage: 36.68 % (	If Canopy Cover > 70%, it’s a dense forest. < 40%, it’s a fragmented forest or open woodland)
 
 <img width="685" alt="Screenshot 2025-02-24 at 19 50 43" src="https://github.com/user-attachments/assets/e195f678-08da-483f-a7f8-f92438fac7a0" />

 
 

