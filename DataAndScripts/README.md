#### This folder contains all necessary Matlab files, used for obtaining the relevant figure data. Raw data is provided in a separate folder.

| File                                  | Description                                                                                                               |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| analyzePositionalData.m               | Loads the positional data from the RawData directory and generates a heat map of positional data and mean velocity plots. |
| Backlights.m                          | Compares population performance with and without backlights.                                                              |
| CNN_decoder_forCalciumImaging.m       | Code to train the CNN decoder and plot relevant figures in S3.                                                            |
| decreasing_contrast.m                 | Compares population performance across contrasts.                                                                         |
| Ephys_WhiskerMetrics.m                | Correlates ephys activity with behavioral metrics (e.g., whisker-angle, whisking-phase)                                   | 
| ExpNaive_TrialCount.m                 | Counts trials per animal for initial and reversed rule.                                                                   |
| Extinction.m                          | Compares population performance before and after extinction.                                                              |
| LearningInstability.m                 | Calculates the learning instability of mice with ablated BC.                                                              | 
| LearningSpeed.m                       | Compares learning speed and time between contrasts and between rules.                                                     |
| LearningSpeed_Cohort12.m              | Compares learning time for only cohort 12 (repeated rule switches)                                                        |
| Licking_Behavior.m                    | Analyzes and visualizes lick rates for mice across different stages of an experiment.                                     |
| Lidocaine.m                           | Compares population performance with and without lidocaine application.                                                   |
| NumSesperAnimal.m                     | Counts number of sessions per animal for initial and reversed rule.                                                       |
| onsetLatencyAnalysis.m                | Calculates the onset latency of ephys activity after aperture-touch.                                                      |
| Population_Analysis.m                 | Plots population performance over trials.                                                                                 |
| Population_Analysis_Cohort12.m        | Plots population performance over trials for only cohort 12 (repeated rule switches).                                     |
| Population_Analysis_Cohort16.m        | Plots population performance over trials for only cohort 16 (contrast 14 mm and 16 mm).                                   |
| Scripts_for_figures_calciumimaging.m  | Plot all the figures for Figure 3 calcium imaging data                                                                    |
| whiskerpluck.m                        | Compares population performance before and after whiskerpluck.                                                            |
