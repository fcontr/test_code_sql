SQL test answers

This repo has my answers for the sq test.

Query to pull back the most recent redemption count, by redemption date, for the date
range 2023-10-30 to 2023-11-05, for retailer "ABC Store". -> See q1.sql

*ABC Store has no record for 2023-11-02 in the example data, so that date just doesn’t show up in the output.

Questions
1) Which date had the least number of redemptions and what was the redemption count?
Nov 5, 2023 — 3,702

2) Which date had the most number of redemptions and what was the redemption count?
Nov 4, 2023 — 5,224

3) What was the createDateTime for each redemptionCount in questions 1 and 2?
3,702 (Nov 5): 2023-11-06 11:00:00 UTC
5,224 (Nov 4): 2023-11-05 11:00:00 UTC

4) Is there another method you can use to pull back the most recent redemption count, by redemption date, for the date range 2023-10-30 to 2023-11-05, for retailer "ABC Store"? In words, describe how you would do this.

Compute MAX(createDateTime) per (retailerId, redemptionDate) for the date range, then join back on those keys to fetch the matching redemptionCount.


